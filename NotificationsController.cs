using Microsoft.AspNetCore.Mvc;
using SkillsAuditSystem.Models;
using System.Collections.Generic;
using System.Linq;
using System;
using Google.Cloud.Firestore;
using System.Threading.Tasks;
using System.Globalization;
using System.IO;

namespace SkillsAuditSystem.Controllers
{
    public class NotificationsController : Controller
    {
        private readonly FirestoreDb _firestoreDb;

        public NotificationsController(FirestoreDb firestoreDb)
        {
            _firestoreDb = firestoreDb;
        }

        private static List<Notification> _notifications = new List<Notification>
        {
            new Notification
            {
                Id = "1",
                Title = "Welcome to Skills Audit System",
                Message = "Welcome! Your account has been successfully created. Please complete your profile to get started.",
                Timestamp = DateTime.Now.AddDays(-1),
                IsRead = false,
                UserId = "currentUserId"
            },
            new Notification
            {
                Id = "2",
                Title = "Skill Assessment Due",
                Message = "Your quarterly skill assessment is due in 3 days. Please update your skills to stay current.",
                Timestamp = DateTime.Now.AddHours(-5),
                IsRead = false,
                UserId = "currentUserId"
            },
            new Notification
            {
                Id = "3",
                Title = "New Training Opportunity",
                Message = "A new Python programming course is now available. This matches your career development goals.",
                Timestamp = DateTime.Now.AddHours(-2),
                IsRead = true,
                UserId = "currentUserId"
            },
            new Notification
            {
                Id = "4",
                Title = "Profile Update Required",
                Message = "Please update your profile information to ensure accurate skill matching and recommendations.",
                Timestamp = DateTime.Now.AddDays(-2),
                IsRead = true,
                UserId = "currentUserId"
            }
        };

        public async Task<IActionResult> Index()
        {
            // Check if user is authenticated via session
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                return RedirectToAction("Index", "Login");
            }

            // Check if admin and redirect to admin notifications
            var employeeId = HttpContext.Session.GetString("employeeId");
            if (!string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01"))
            {
                return RedirectToAction("Admin");
            }

            // Fetch user details for profile name and photo
            string userName = "My Profile";
            string photoBase64 = "";
            string profilePhotoUrl = "";
            var userDoc = await _firestoreDb.Collection("users").Document(userId).GetSnapshotAsync();
            if (userDoc.Exists)
            {
                var userData = userDoc.ToDictionary();
                var firstName = userData.GetValueOrDefault("firstName", "") as string;
                var lastName = userData.GetValueOrDefault("lastName", "") as string;
                userName = $"{firstName} {lastName}".Trim();
                if (string.IsNullOrWhiteSpace(userName))
                {
                    userName = "My Profile";
                }
                photoBase64 = userData.GetValueOrDefault("photoBase64", "") as string;
                profilePhotoUrl = userData.GetValueOrDefault("photoUrl", "") as string;
            }

            // Fetch notifications from Firestore for the current user
            var notifications = new List<Notification>();
            try
            {
                var notificationsRef = _firestoreDb.Collection("notifications");
                var snapshot = await notificationsRef.WhereEqualTo("UserId", userId).GetSnapshotAsync();

                foreach (var document in snapshot.Documents)
                {
                    var notification = document.ConvertTo<Notification>();
                    notification.Id = document.Id;
                    notifications.Add(notification);
                }

                // Order by timestamp descending in memory
                notifications = notifications.OrderByDescending(n => n.Timestamp).ToList();
            }
            catch (Exception ex)
            {
                // Handle errors gracefully
                Console.WriteLine($"Error loading notifications: {ex.Message}");
            }

            ViewBag.Notifications = notifications;
            ViewBag.NewNotifications = notifications.Count(n => !n.IsRead);
            ViewBag.UserName = userName;
            ViewBag.PhotoBase64 = photoBase64;
            ViewBag.ProfilePhotoUrl = profilePhotoUrl;
            return View();
        }

        public async Task<IActionResult> Admin()
        {
            // Check if user is authenticated and is admin
            var userId = HttpContext.Session.GetString("userId");
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (string.IsNullOrEmpty(userId) || !isAdmin)
            {
                return RedirectToAction("Index", "Login");
            }

            // Fetch sent notifications history from Firestore
            var notifications = new List<Notification>();
            try
            {
                var notificationsRef = _firestoreDb.Collection("notifications");
                var snapshot = await notificationsRef.OrderByDescending("Timestamp").GetSnapshotAsync();

                foreach (var document in snapshot.Documents)
                {
                    var notification = document.ConvertTo<Notification>();
                    notification.Id = document.Id;

                    // Enrich employee notifications with actual employee ID
                    if (notification.RecipientType == "employee" && !string.IsNullOrEmpty(notification.EmployeeId))
                    {
                        var userDoc = await _firestoreDb.Collection("users").Document(notification.EmployeeId).GetSnapshotAsync();
                        if (userDoc.Exists)
                        {
                            var userData = userDoc.ToDictionary();
                            notification.EmployeeId = userData.GetValueOrDefault("employeeId", notification.EmployeeId) as string;
                        }
                    }

                    notifications.Add(notification);
                }



                // Group notifications to avoid duplicates for "all" recipients
                notifications = notifications
                    .GroupBy(n => new
                    {
                        n.Title,
                        n.Message,
                        Date = n.Timestamp.Date,
                        Time = n.Timestamp.TimeOfDay,
                        n.RecipientType,
                        n.Department,
                        n.EmployeeId
                    })
                    .Select(g => g.First())
                    .OrderByDescending(n => n.Timestamp)
                    .ToList();
            }
            catch (Exception ex)
            {
                // Handle errors gracefully
                Console.WriteLine($"Error loading notifications: {ex.Message}");
            }

            ViewBag.Notifications = notifications;
            ViewBag.AdminId = employeeId ?? "ADMIN";
            return View("Admin");
        }

        [HttpPost]
        public async Task<IActionResult> SendNotification(string title, string message, string recipientType, string department, string employee, IFormFile attachment)
        {
            // Check admin authentication
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (!isAdmin)
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            if (string.IsNullOrWhiteSpace(title) || string.IsNullOrWhiteSpace(message))
            {
                return Json(new { success = false, message = "Title and message are required" });
            }

            if (string.IsNullOrWhiteSpace(recipientType))
            {
                return Json(new { success = false, message = "Recipient type is required" });
            }

            try
            {
                var usersRef = _firestoreDb.Collection("users");
                var usersSnapshot = await usersRef.GetSnapshotAsync();
                var notificationsRef = _firestoreDb.Collection("notifications");
                var timestamp = DateTime.UtcNow;

                List<string> targetUserIds = new List<string>();

                if (recipientType == "all")
                {
                    // Send to all active employees (excluding admins)
                    foreach (var userDoc in usersSnapshot.Documents)
                    {
                        var userData = userDoc.ToDictionary();
                        var employeeIdFromDoc = userData.GetValueOrDefault("employeeId", "") as string;
                        var isActive = userData.GetValueOrDefault("isActive", true) as bool?;
                        if (isActive == true && !string.IsNullOrEmpty(employeeIdFromDoc) && !employeeIdFromDoc.StartsWith("ADM-"))
                        {
                            targetUserIds.Add(userDoc.Id);
                        }
                    }
                }
                else if (recipientType == "department")
                {
                    if (string.IsNullOrWhiteSpace(department))
                    {
                        return Json(new { success = false, message = "Department is required when sending to a department" });
                    }

                    // Send to active employees in the specified department (excluding admins)
                    foreach (var userDoc in usersSnapshot.Documents)
                    {
                        var userData = userDoc.ToDictionary();
                        var userDepartment = userData.GetValueOrDefault("department", "") as string;
                        var employeeIdFromDoc = userData.GetValueOrDefault("employeeId", "") as string;
                        var isActive = userData.GetValueOrDefault("isActive", true) as bool?;

                        if (isActive == true && userDepartment == department && !string.IsNullOrEmpty(employeeIdFromDoc) && !employeeIdFromDoc.StartsWith("ADM-"))
                        {
                            targetUserIds.Add(userDoc.Id);
                        }
                    }
                }
                else if (recipientType == "employee")
                {
                    if (string.IsNullOrWhiteSpace(employee))
                    {
                        return Json(new { success = false, message = "Employee is required when sending to a specific employee" });
                    }

                    // Send to specific active employee (excluding admins)
                    var targetUser = usersSnapshot.Documents.FirstOrDefault(doc => doc.Id == employee);
                    if (targetUser != null)
                    {
                        var userData = targetUser.ToDictionary();
                        var employeeIdFromDoc = userData.GetValueOrDefault("employeeId", "") as string;
                        var isActive = userData.GetValueOrDefault("isActive", true) as bool?;
                        if (isActive == true && !string.IsNullOrEmpty(employeeIdFromDoc) && !employeeIdFromDoc.StartsWith("ADM-"))
                        {
                            targetUserIds.Add(employee);
                        }
                        else
                        {
                            return Json(new { success = false, message = "Selected employee is not active or is an admin" });
                        }
                    }
                    else
                    {
                        return Json(new { success = false, message = "Employee not found" });
                    }
                }
                else
                {
                    return Json(new { success = false, message = "Invalid recipient type" });
                }

                if (!targetUserIds.Any())
                {
                    return Json(new { success = false, message = "No active employees found for the selected criteria" });
                }

                // Handle attachment upload if provided
                string attachmentUrl = null;
                string attachmentName = null;
                if (attachment != null && attachment.Length > 0)
                {
                    // Create uploads directory if it doesn't exist
                    var uploadsDir = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "notifications");
                    Directory.CreateDirectory(uploadsDir);

                    // Generate unique filename
                    var fileExtension = Path.GetExtension(attachment.FileName);
                    var uniqueFileName = $"{Guid.NewGuid()}{fileExtension}";
                    var filePath = Path.Combine(uploadsDir, uniqueFileName);

                    // Save file
                    using (var stream = new FileStream(filePath, FileMode.Create))
                    {
                        await attachment.CopyToAsync(stream);
                    }

                    attachmentUrl = $"/uploads/notifications/{uniqueFileName}";
                    attachmentName = attachment.FileName;
                }

                // Send notifications to target users
                foreach (var userId in targetUserIds)
                {
                    var notification = new Notification
                    {
                        Id = Guid.NewGuid().ToString(),
                        Title = title,
                        Message = message,
                        Timestamp = timestamp,
                        IsRead = false,
                        UserId = userId,
                        RecipientType = recipientType,
                        Department = recipientType == "department" ? department : null,
                        EmployeeId = recipientType == "employee" ? employee : null,
                        AttachmentUrl = attachmentUrl,
                        AttachmentName = attachmentName
                    };

                    await notificationsRef.AddAsync(notification.ToMap());
                }

                string recipientDescription = recipientType switch
                {
                    "all" => "all employees",
                    "department" => $"employees in {department} department",
                    "employee" => "the selected employee",
                    _ => "recipients"
                };

                return Json(new { success = true, message = $"Notification sent to {targetUserIds.Count} {recipientDescription}" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error sending notification: {ex.Message}" });
            }
        }

        private string GetRecipientDescription(Notification notification)
        {
            return notification.RecipientType switch
            {
                "all" => "All Employees",
                "department" => $"{notification.Department} Department",
                "employee" => $"Employee {notification.EmployeeId}",
                _ => "Unknown Recipients"
            };
        }

        private string FormatDateTimeSAST(DateTime utcDateTime)
        {
            // SAST is UTC+2
            var sastTime = utcDateTime.AddHours(2);
            return sastTime.ToString("dd MMM yyyy, HH:mm", CultureInfo.InvariantCulture);
        }

        [HttpPost]
        public async Task<IActionResult> MarkAsRead(string id)
        {
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                return Json(new { success = false, message = "User not authenticated" });
            }

            try
            {
                var notificationRef = _firestoreDb.Collection("notifications").Document(id);
                var updateData = new Dictionary<string, object>
                {
                    { "IsRead", true }
                };

                await notificationRef.UpdateAsync(updateData);
                return Json(new { success = true });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error marking notification as read: {ex.Message}" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> MarkAllAsRead()
        {
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                return Json(new { success = false, message = "User not authenticated" });
            }

            try
            {
                var notificationsRef = _firestoreDb.Collection("notifications");
                var snapshot = await notificationsRef.WhereEqualTo("UserId", userId).WhereEqualTo("IsRead", false).GetSnapshotAsync();

                foreach (var document in snapshot.Documents)
                {
                    var updateData = new Dictionary<string, object>
                    {
                        { "IsRead", true }
                    };
                    await document.Reference.UpdateAsync(updateData);
                }

                return Json(new { success = true });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error marking all notifications as read: {ex.Message}" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> Delete(string id)
        {
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                return Json(new { success = false, message = "User not authenticated" });
            }

            try
            {
                // Verify the notification belongs to the current user
                var notificationDoc = await _firestoreDb.Collection("notifications").Document(id).GetSnapshotAsync();
                if (notificationDoc.Exists)
                {
                    var notification = notificationDoc.ConvertTo<Notification>();
                    if (notification.UserId != userId)
                    {
                        return Json(new { success = false, message = "Unauthorized to delete this notification" });
                    }

                    await notificationDoc.Reference.DeleteAsync();
                }

                return Json(new { success = true });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error deleting notification: {ex.Message}" });
            }
        }

        [HttpGet]
        public async Task<IActionResult> GetNotification(string id)
        {
            // Check admin authentication
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (!isAdmin)
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            try
            {
                var notificationDoc = await _firestoreDb.Collection("notifications").Document(id).GetSnapshotAsync();
                if (notificationDoc.Exists)
                {
                    var notification = notificationDoc.ConvertTo<Notification>();
                    notification.Id = notificationDoc.Id;

                    // Enrich employee notifications with actual employee ID
                    if (notification.RecipientType == "employee" && !string.IsNullOrEmpty(notification.EmployeeId))
                    {
                        var userDoc = await _firestoreDb.Collection("users").Document(notification.EmployeeId).GetSnapshotAsync();
                        if (userDoc.Exists)
                        {
                            var userData = userDoc.ToDictionary();
                            notification.EmployeeId = userData.GetValueOrDefault("employeeId", notification.EmployeeId) as string;
                        }
                    }

                    return Json(new
                    {
                        success = true,
                        notification = new
                        {
                            id = notification.Id,
                            title = notification.Title,
                            message = notification.Message,
                            recipient = GetRecipientDescription(notification),
                            attachmentName = notification.AttachmentName ?? "No attachment",
                            attachmentUrl = notification.AttachmentUrl,
                            dateSent = FormatDateTimeSAST(notification.Timestamp)
                        }
                    });
                }
                else
                {
                    return Json(new { success = false, message = "Notification not found" });
                }
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error fetching notification: {ex.Message}" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> UpdateNotification(string id, string title, string message, IFormFile attachment)
        {
            // Check admin authentication
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (!isAdmin)
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            if (string.IsNullOrWhiteSpace(title) || string.IsNullOrWhiteSpace(message))
            {
                return Json(new { success = false, message = "Title and message are required" });
            }

            try
            {
                // Get the original notification to find all matching ones
                var notificationDoc = await _firestoreDb.Collection("notifications").Document(id).GetSnapshotAsync();
                if (!notificationDoc.Exists)
                {
                    return Json(new { success = false, message = "Notification not found" });
                }

                var originalNotification = notificationDoc.ConvertTo<Notification>();

                // Handle attachment upload if provided
                string attachmentUrl = originalNotification.AttachmentUrl; // Keep existing by default
                string attachmentName = originalNotification.AttachmentName;
                if (attachment != null && attachment.Length > 0)
                {
                    // Create uploads directory if it doesn't exist
                    var uploadsDir = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "notifications");
                    Directory.CreateDirectory(uploadsDir);

                    // Generate unique filename
                    var fileExtension = Path.GetExtension(attachment.FileName);
                    var uniqueFileName = $"{Guid.NewGuid()}{fileExtension}";
                    var filePath = Path.Combine(uploadsDir, uniqueFileName);

                    // Save file
                    using (var stream = new FileStream(filePath, FileMode.Create))
                    {
                        await attachment.CopyToAsync(stream);
                    }

                    attachmentUrl = $"/uploads/notifications/{uniqueFileName}";
                    attachmentName = attachment.FileName;
                }

                // Find all notifications with the same content and recipient details
                var notificationsRef = _firestoreDb.Collection("notifications");
                var query = notificationsRef
                    .WhereEqualTo("Title", originalNotification.Title)
                    .WhereEqualTo("Message", originalNotification.Message)
                    .WhereEqualTo("RecipientType", originalNotification.RecipientType);

                if (!string.IsNullOrEmpty(originalNotification.Department))
                {
                    query = query.WhereEqualTo("Department", originalNotification.Department);
                }

                if (!string.IsNullOrEmpty(originalNotification.EmployeeId))
                {
                    query = query.WhereEqualTo("EmployeeId", originalNotification.EmployeeId);
                }

                var snapshot = await query.GetSnapshotAsync();

                // Update all matching notifications
                var newTimestamp = DateTime.UtcNow;
                foreach (var document in snapshot.Documents)
                {
                    var updateData = new Dictionary<string, object>
                    {
                        { "Title", title },
                        { "Message", message },
                        { "Timestamp", newTimestamp },
                        { "AttachmentUrl", attachmentUrl },
                        { "AttachmentName", attachmentName }
                    };

                    await document.Reference.UpdateAsync(updateData);
                }

                return Json(new { success = true, message = $"Notification updated for {snapshot.Documents.Count} recipients" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error updating notification: {ex.Message}" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> DeleteNotification(string id)
        {
            // Check admin authentication
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (!isAdmin)
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            try
            {
                // Get the original notification to find all matching ones
                var notificationDoc = await _firestoreDb.Collection("notifications").Document(id).GetSnapshotAsync();
                if (!notificationDoc.Exists)
                {
                    return Json(new { success = false, message = "Notification not found" });
                }

                var originalNotification = notificationDoc.ConvertTo<Notification>();

                // Find all notifications with the same content and recipient details
                var notificationsRef = _firestoreDb.Collection("notifications");
                var query = notificationsRef
                    .WhereEqualTo("Title", originalNotification.Title)
                    .WhereEqualTo("Message", originalNotification.Message)
                    .WhereEqualTo("RecipientType", originalNotification.RecipientType);

                if (!string.IsNullOrEmpty(originalNotification.Department))
                {
                    query = query.WhereEqualTo("Department", originalNotification.Department);
                }

                if (!string.IsNullOrEmpty(originalNotification.EmployeeId))
                {
                    query = query.WhereEqualTo("EmployeeId", originalNotification.EmployeeId);
                }

                var snapshot = await query.GetSnapshotAsync();

                // Delete all matching notifications
                foreach (var document in snapshot.Documents)
                {
                    await document.Reference.DeleteAsync();
                }

                return Json(new { success = true, message = $"Notification deleted for {snapshot.Documents.Count} recipients" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error deleting notification: {ex.Message}" });
            }
        }

        [HttpGet]
        public IActionResult GetDepartments()
        {
            // Check admin authentication
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (!isAdmin)
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            // Departments based on Registration page
            var departments = new List<string>
            {
                "Office of the Director-General",
                "Intergovernmental Relations",
                "Office of the General Counsel",
                "Budget Preparation / Budget Office",
                "Economic Policy and International Cooperation",
                "Office of the Accountant-General",
                "Tax & Financial Sector Policy",
                "Assets & Liability Management",
                "Public Finance / Expenditure Control",
                "Corporate / Support Services (HR, ICT, Facilities, Legal, Security, etc.)",
                "Chief Procurement Office"
            };

            return Json(new { success = true, departments = departments });
        }

        [HttpGet]
        public async Task<IActionResult> GetEmployeeNotification(string id)
        {
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                return Json(new { success = false, message = "User not authenticated" });
            }

            try
            {
                var notificationDoc = await _firestoreDb.Collection("notifications").Document(id).GetSnapshotAsync();
                if (notificationDoc.Exists)
                {
                    var notification = notificationDoc.ConvertTo<Notification>();
                    notification.Id = notificationDoc.Id;

                    // Security check: ensure notification belongs to current user
                    if (notification.UserId != userId)
                    {
                        return Json(new { success = false, message = "Unauthorized to access this notification" });
                    }

                    return Json(new
                    {
                        success = true,
                        notification = new
                        {
                            id = notification.Id,
                            title = notification.Title,
                            message = notification.Message,
                            attachmentName = notification.AttachmentName,
                            attachmentUrl = notification.AttachmentUrl,
                            dateSent = FormatDateTimeSAST(notification.Timestamp)
                        }
                    });
                }
                else
                {
                    return Json(new { success = false, message = "Notification not found" });
                }
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error fetching notification: {ex.Message}" });
            }
        }

        [HttpGet]
        public async Task<IActionResult> GetEmployees()
        {
            // Check admin authentication
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (!isAdmin)
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            try
            {
                var employees = new List<object>();
                var usersRef = _firestoreDb.Collection("users");
                var snapshot = await usersRef.GetSnapshotAsync();

                foreach (var document in snapshot.Documents)
                {
                    var userData = document.ToDictionary();
                    var firstName = userData.GetValueOrDefault("firstName", "") as string;
                    var lastName = userData.GetValueOrDefault("lastName", "") as string;
                    var employeeIdFromDoc = userData.GetValueOrDefault("employeeId", "") as string;
                    var isActive = userData.GetValueOrDefault("isActive", true) as bool?;

            // Only include active employees, excluding admins (same as User Management)
            if (isActive == true && !string.IsNullOrWhiteSpace(employeeIdFromDoc) && !employeeIdFromDoc.StartsWith("ADM-"))
            {
                employees.Add(new
                {
                    id = document.Id,
                    employeeId = employeeIdFromDoc,
                    name = $"{firstName} {lastName}".Trim(),
                    department = userData.GetValueOrDefault("department", "") as string
                });
            }
                }

                return Json(new { success = true, employees = employees });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error fetching employees: {ex.Message}" });
            }
        }
    }
}
