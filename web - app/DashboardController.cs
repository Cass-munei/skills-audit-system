using Microsoft.AspNetCore.Mvc;
using Google.Cloud.Firestore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using SkillsAuditSystem.Models;
using FirebaseAdmin.Auth;

namespace SkillsAuditSystem.Controllers
{
    public class DashboardController : Controller
    {
        private readonly FirestoreDb _firestore;

        public DashboardController(FirestoreDb firestore)
        {
            _firestore = firestore;
        }

        public async Task<IActionResult> Index()
        {
            // Check if user is authenticated (you might need to implement proper auth)
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                return RedirectToAction("Index", "Login");
            }

            // Check if admin and redirect to admin dashboard
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");
            Console.WriteLine($"Dashboard Index - UserId: {userId}, EmployeeId: {employeeId}, IsAdmin: {isAdmin}");
            if (isAdmin)
            {
                Console.WriteLine("Redirecting to Admin dashboard");
                return RedirectToAction("Admin", "Dashboard");
            }

            var viewModel = new DashboardViewModel();

            // Fetch user details for profile name and employee ID
            var userDoc = await _firestore.Collection("users").Document(userId).GetSnapshotAsync();
            var userData = userDoc.Exists ? userDoc.ToDictionary() : new Dictionary<string, object>();

            if (userDoc.Exists)
            {
                var firstName = userData.GetValueOrDefault("firstName", "") as string;
                var lastName = userData.GetValueOrDefault("lastName", "") as string;
                viewModel.UserName = $"{firstName} {lastName}".Trim();
                viewModel.EmployeeId = userData.GetValueOrDefault("employeeId", "User") as string;
                viewModel.ProfilePhotoUrl = userData.GetValueOrDefault("photoUrl", "") as string;
                viewModel.PhotoBase64 = userData.GetValueOrDefault("photoBase64", "") as string;
            }
            else
            {
                viewModel.UserName = "My Profile";
                viewModel.EmployeeId = "User";
                viewModel.ProfilePhotoUrl = "";
            }

            try
            {
                // Fetch counts from actual collections
                var trainingsQuery = await _firestore.Collection("users").Document(userId).Collection("trainings").GetSnapshotAsync();
                viewModel.TrainingCompleted = trainingsQuery.Documents.Count;

                var qualificationsQuery = await _firestore.Collection("users").Document(userId).Collection("qualifications").GetSnapshotAsync();
                viewModel.QualificationsAdded = qualificationsQuery.Documents.Count;

                var documentsQuery = await _firestore.Collection("users").Document(userId).Collection("documents").GetSnapshotAsync();
                viewModel.DocumentsUploaded = documentsQuery.Documents.Count;

                var skillsQuery = await _firestore.Collection("users").Document(userId).Collection("skills").GetSnapshotAsync();
                viewModel.SkillsInDemand = skillsQuery.Documents.Count;

                // For notifications, count unread notifications the employee has received
                var notificationsQuery = await _firestore.Collection("notifications").WhereEqualTo("UserId", userId).WhereEqualTo("IsRead", false).GetSnapshotAsync();
                viewModel.NewNotifications = notificationsQuery.Documents.Count;

                // Fetch upcoming deadlines from qualifications and trainings
                var upcomingDeadlines = new List<Deadline>();
                var now = DateTime.Now;
                var currentDate = new DateTime(now.Year, now.Month, now.Day);

                // Qualifications with future dates
                foreach (var doc in qualificationsQuery.Documents)
                {
                    var data = doc.ToDictionary();
                    var dateStr = data.ContainsKey("date") ? data["date"] as string : null;
                    if (!string.IsNullOrEmpty(dateStr))
                    {
                        if (DateTime.TryParse(dateStr, out var date) && date > currentDate)
                        {
                            upcomingDeadlines.Add(new Deadline
                            {
                                Title = $"Qualification renewal: {data.GetValueOrDefault("name", "Unknown")}",
                                Date = dateStr
                            });
                        }
                    }
                }

                // Trainings with future end dates
                foreach (var doc in trainingsQuery.Documents)
                {
                    var data = doc.ToDictionary();
                    var endDateStr = data.ContainsKey("endDate") ? data["endDate"] as string : null;
                    if (!string.IsNullOrEmpty(endDateStr))
                    {
                        if (DateTime.TryParse(endDateStr, out var endDate) && endDate > currentDate)
                        {
                            upcomingDeadlines.Add(new Deadline
                            {
                                Title = $"Training completion: {data.GetValueOrDefault("trainingName", "Unknown")}",
                                Date = endDateStr
                            });
                        }
                    }
                }

                // Sort and limit
                viewModel.UpcomingDeadlines = upcomingDeadlines.OrderBy(d => d.Date).Take(5).ToList();

                // Fetch recent activities
                var recentActivities = new List<string>();
                var recentSkills = await _firestore.Collection("users").Document(userId).Collection("skills")
                    .OrderByDescending("createdAt").Limit(3).GetSnapshotAsync();
                foreach (var doc in recentSkills.Documents)
                {
                    var data = doc.ToDictionary();
                    recentActivities.Add($"Added skill: {data.GetValueOrDefault("name", "Unknown")}");
                }

                var recentQualifications = await _firestore.Collection("users").Document(userId).Collection("qualifications")
                    .OrderByDescending("createdAt").Limit(3).GetSnapshotAsync();
                foreach (var doc in recentQualifications.Documents)
                {
                    var data = doc.ToDictionary();
                    recentActivities.Add($"Added qualification: {data.GetValueOrDefault("name", "Unknown")}");
                }

                var recentTrainings = await _firestore.Collection("users").Document(userId).Collection("trainings")
                    .OrderByDescending("createdAt").Limit(3).GetSnapshotAsync();
                foreach (var doc in recentTrainings.Documents)
                {
                    var data = doc.ToDictionary();
                    recentActivities.Add($"Enrolled in training: {data.GetValueOrDefault("trainingName", "Unknown")}");
                }

                viewModel.RecentActivities = recentActivities.Take(5).ToList();

                // Calculate progress dynamically from actual Firestore data
                // Rating Progress: Profile completion (firstName, lastName, employeeId, photo each 25%)
                double ratingProgress = 0.0;
                if (!string.IsNullOrEmpty(userData.GetValueOrDefault("firstName", "") as string)) ratingProgress += 0.25;
                if (!string.IsNullOrEmpty(userData.GetValueOrDefault("lastName", "") as string)) ratingProgress += 0.25;
                if (!string.IsNullOrEmpty(userData.GetValueOrDefault("employeeId", "") as string)) ratingProgress += 0.25;
                if (!string.IsNullOrEmpty(userData.GetValueOrDefault("photoUrl", "") as string) ||
                    !string.IsNullOrEmpty(userData.GetValueOrDefault("photoBase64", "") as string)) ratingProgress += 0.25;
                viewModel.RatingProgress = ratingProgress;

                // Skills Progress: (skills count / 10) * 100%
                int skillsCount = skillsQuery.Documents.Count;
                viewModel.SkillsProgress = Math.Min((double)skillsCount / 10.0, 1.0);

                // Documents Progress: (documents count / 5) * 100%
                int documentsCount = documentsQuery.Documents.Count;
                viewModel.DocumentsProgress = Math.Min((double)documentsCount / 5.0, 1.0);

                // Set default today's tasks
                viewModel.TodaysTasks = new List<string>
                {
                    "Upload documents",
                    "Add acquired skills",
                    "Add planned training",
                    "Add qualification"
                };
            }
            catch (Exception ex)
            {
                // Handle errors gracefully
                Console.WriteLine($"Error loading dashboard data: {ex.Message}");
            }

            return View(viewModel);
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

            var viewModel = new DashboardStats
            {
                AdminId = employeeId ?? "ADMIN"
            };

            try
            {
                // Fetch all users from Firebase Auth and check Firestore to match User Management logic
                var listUsersAsync = FirebaseAuth.DefaultInstance.ListUsersAsync(null);
                var employeesByDepartment = new Dictionary<string, int>();
                var allUserIds = new List<string>();

                await foreach (var firebaseUser in listUsersAsync)
                {
                    var userDoc = await _firestore.Collection("users").Document(firebaseUser.Uid).GetSnapshotAsync();
                    if (userDoc.Exists)
                    {
                        var userData = userDoc.ToDictionary();
                        var userEmployeeId = userData.GetValueOrDefault("employeeId", "") as string;
                        var department = userData.GetValueOrDefault("department", "") as string;

                        // Skip admin users and users without assigned departments
                        if (!string.IsNullOrEmpty(userEmployeeId) && !userEmployeeId.StartsWith("ADM-") && !string.IsNullOrEmpty(department))
                        {
                            allUserIds.Add(firebaseUser.Uid);

                            // Count by department
                            if (employeesByDepartment.ContainsKey(department))
                                employeesByDepartment[department]++;
                            else
                                employeesByDepartment[department] = 1;
                        }
                    }
                }

                // Set total employees to match User Management (excluding admins)
                viewModel.TotalEmployees = allUserIds.Count;

                // Filter out departments with 0 employees
                viewModel.EmployeesByDepartment = employeesByDepartment.Where(d => d.Value > 0).ToDictionary(d => d.Key, d => d.Value);

                // Calculate verified documents percentage and pending approvals
                var totalDocuments = 0;
                var verifiedDocuments = 0;
                var pendingApprovals = 0;
                var missingDocuments = new Dictionary<string, int>();

                foreach (var userIdForDocs in allUserIds)
                {
                    var documentsQuery = await _firestore.Collection("users").Document(userIdForDocs).Collection("documents").GetSnapshotAsync();

                    foreach (var doc in documentsQuery.Documents)
                    {
                        var docData = doc.ToDictionary();
                        var status = docData.GetValueOrDefault("status", "pending") as string;
                        var docType = docData.GetValueOrDefault("documentType", "Unknown") as string;

                        totalDocuments++;

                        if (status?.ToLower() == "verified" || status?.ToLower() == "approved")
                        {
                            verifiedDocuments++;
                        }
                        else if (status?.ToLower() == "pending" || status?.ToLower() == "awaiting review")
                        {
                            pendingApprovals++;
                        }

                        // Track missing documents by type
                        if (status?.ToLower() != "verified" && status?.ToLower() != "approved")
                        {
                            if (missingDocuments.ContainsKey(docType))
                                missingDocuments[docType]++;
                            else
                                missingDocuments[docType] = 1;
                        }
                    }
                }

                viewModel.VerifiedDocumentsPercentage = totalDocuments > 0 ? (double)verifiedDocuments / totalDocuments * 100 : 0.0;
                viewModel.PendingApprovals = pendingApprovals;
                viewModel.MissingDocuments = missingDocuments;

                // Count upcoming training sessions (calculated status == "Upcoming")
                var upcomingTraining = 0;

                foreach (var userIdForTraining in allUserIds)
                {
                    var trainingsQuery = await _firestore.Collection("users").Document(userIdForTraining).Collection("trainings").GetSnapshotAsync();

                    foreach (var trainingDoc in trainingsQuery.Documents)
                    {
                        var trainingData = trainingDoc.ToDictionary();
                        var startDateStr = trainingData.GetValueOrDefault("StartDate", trainingData.GetValueOrDefault("startDate", "")) as string;
                        var endDateStr = trainingData.GetValueOrDefault("EndDate", trainingData.GetValueOrDefault("endDate", "")) as string;

                        if (!string.IsNullOrEmpty(startDateStr) && !string.IsNullOrEmpty(endDateStr) &&
                            DateTime.TryParse(startDateStr, out var start) && DateTime.TryParse(endDateStr, out var end))
                        {
                            var now = DateTime.Now;
                            if (now < start)
                            {
                                upcomingTraining++;
                            }
                        }
                    }
                }

                viewModel.UpcomingTraining = upcomingTraining;
            }
            catch (Exception ex)
            {
                // Handle errors gracefully and return default values
                Console.WriteLine($"Error loading admin dashboard data: {ex.Message}");
                viewModel.TotalEmployees = 0;
                viewModel.VerifiedDocumentsPercentage = 0.0;
                viewModel.PendingApprovals = 0;
                viewModel.UpcomingTraining = 0;
                viewModel.EmployeesByDepartment = new Dictionary<string, int>();
                viewModel.MissingDocuments = new Dictionary<string, int>();
            }

            return View("Admin", viewModel);
        }

        [HttpGet]
        public async Task<IActionResult> ExportReport()
        {
            // Check if user is authenticated and is admin
            var userId = HttpContext.Session.GetString("userId");
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (string.IsNullOrEmpty(userId) || !isAdmin)
            {
                return Unauthorized();
            }

            try
            {
                // Get dashboard data similar to Admin action
                var viewModel = new DashboardStats
                {
                    AdminId = employeeId ?? "ADMIN"
                };

                // Fetch all users from Firebase Auth and check Firestore to match User Management logic
                var listUsersAsync = FirebaseAuth.DefaultInstance.ListUsersAsync(null);
                var employeesByDepartment = new Dictionary<string, int>();
                var allUserIds = new List<string>();

                await foreach (var firebaseUser in listUsersAsync)
                {
                    var userDoc = await _firestore.Collection("users").Document(firebaseUser.Uid).GetSnapshotAsync();
                    if (userDoc.Exists)
                    {
                        var userData = userDoc.ToDictionary();
                        var userEmployeeId = userData.GetValueOrDefault("employeeId", "") as string;
                        var department = userData.GetValueOrDefault("department", "") as string;

                        // Skip admin users and users without assigned departments
                        if (!string.IsNullOrEmpty(userEmployeeId) && !userEmployeeId.StartsWith("ADM-") && !string.IsNullOrEmpty(department))
                        {
                            allUserIds.Add(firebaseUser.Uid);

                            // Count by department
                            if (employeesByDepartment.ContainsKey(department))
                                employeesByDepartment[department]++;
                            else
                                employeesByDepartment[department] = 1;
                        }
                    }
                }

                // Set total employees to match User Management (excluding admins)
                viewModel.TotalEmployees = allUserIds.Count;

                // Filter out departments with 0 employees
                viewModel.EmployeesByDepartment = employeesByDepartment.Where(d => d.Value > 0).ToDictionary(d => d.Key, d => d.Value);

                // Calculate verified documents percentage and pending approvals
                var totalDocuments = 0;
                var verifiedDocuments = 0;
                var pendingApprovals = 0;
                var missingDocuments = new Dictionary<string, int>();

                foreach (var userIdForDocs in allUserIds)
                {
                    var documentsQuery = await _firestore.Collection("users").Document(userIdForDocs).Collection("documents").GetSnapshotAsync();

                    foreach (var doc in documentsQuery.Documents)
                    {
                        var docData = doc.ToDictionary();
                        var status = docData.GetValueOrDefault("status", "pending") as string;
                        var docType = docData.GetValueOrDefault("documentType", "Unknown") as string;

                        totalDocuments++;

                        if (status?.ToLower() == "verified" || status?.ToLower() == "approved")
                        {
                            verifiedDocuments++;
                        }
                        else if (status?.ToLower() == "pending" || status?.ToLower() == "awaiting review")
                        {
                            pendingApprovals++;
                        }

                        // Track missing documents by type
                        if (status?.ToLower() != "verified" && status?.ToLower() != "approved")
                        {
                            if (missingDocuments.ContainsKey(docType))
                                missingDocuments[docType]++;
                            else
                                missingDocuments[docType] = 1;
                        }
                    }
                }

                viewModel.VerifiedDocumentsPercentage = totalDocuments > 0 ? (double)verifiedDocuments / totalDocuments * 100 : 0.0;
                viewModel.PendingApprovals = pendingApprovals;
                viewModel.MissingDocuments = missingDocuments;

                // Count upcoming training sessions (calculated status == "Upcoming")
                var upcomingTraining = 0;

                foreach (var userIdForTraining in allUserIds)
                {
                    var trainingsQuery = await _firestore.Collection("users").Document(userIdForTraining).Collection("trainings").GetSnapshotAsync();

                    foreach (var trainingDoc in trainingsQuery.Documents)
                    {
                        var trainingData = trainingDoc.ToDictionary();
                        var startDateStr = trainingData.GetValueOrDefault("StartDate", trainingData.GetValueOrDefault("startDate", "")) as string;
                        var endDateStr = trainingData.GetValueOrDefault("EndDate", trainingData.GetValueOrDefault("endDate", "")) as string;

                        if (!string.IsNullOrEmpty(startDateStr) && !string.IsNullOrEmpty(endDateStr) &&
                            DateTime.TryParse(startDateStr, out var start) && DateTime.TryParse(endDateStr, out var end))
                        {
                            var now = DateTime.Now;
                            if (now < start)
                            {
                                upcomingTraining++;
                            }
                        }
                    }
                }

                viewModel.UpcomingTraining = upcomingTraining;

                // Generate CSV content
                var csvContent = new System.Text.StringBuilder();
                csvContent.AppendLine("Dashboard Statistics Report");
                csvContent.AppendLine($"Generated on: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
                csvContent.AppendLine($"Generated by: {employeeId}");
                csvContent.AppendLine();
                csvContent.AppendLine("Summary Statistics");
                csvContent.AppendLine($"Total Employees,{viewModel.TotalEmployees}");
                csvContent.AppendLine($"Verified Documents Percentage,{viewModel.VerifiedDocumentsPercentage:F1}%");
                csvContent.AppendLine($"Pending Approvals,{viewModel.PendingApprovals}");
                csvContent.AppendLine($"Upcoming Training,{viewModel.UpcomingTraining}");
                csvContent.AppendLine();

                // Employees by Department
                csvContent.AppendLine("Employees by Department");
                csvContent.AppendLine("Department,Count");
                foreach (var dept in viewModel.EmployeesByDepartment)
                {
                    csvContent.AppendLine($"{EscapeCsvField(dept.Key)},{dept.Value}");
                }
                csvContent.AppendLine();



                // Return CSV file
                var csvBytes = System.Text.Encoding.UTF8.GetBytes(csvContent.ToString());
                return File(csvBytes, "text/csv", $"Dashboard_Report_{DateTime.Now.ToString("yyyyMMdd_HHmmss")}.csv");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error generating dashboard report: {ex.Message}");
                return StatusCode(500, "Error generating report");
            }
        }

        private string EscapeCsvField(string field)
        {
            if (string.IsNullOrEmpty(field))
                return "";

            if (field.Contains(",") || field.Contains("\"") || field.Contains("\n"))
            {
                return "\"" + field.Replace("\"", "\"\"") + "\"";
            }
            return field;
        }

        [HttpPost]
        public new async Task<IActionResult> SignOut()
        {
            // Clear session
            HttpContext.Session.Clear();
            return RedirectToAction("Index", "Login");
        }
    }

    public class DashboardViewModel
    {
        public int DocumentsUploaded { get; set; }
        public int QualificationsAdded { get; set; }
        public int TrainingCompleted { get; set; }
        public int NewNotifications { get; set; }
        public int MissingDocuments { get; set; }
        public int SkillsInDemand { get; set; }
        public double RatingProgress { get; set; }
        public double SkillsProgress { get; set; }
        public double DocumentsProgress { get; set; }
        public List<string> TodaysTasks { get; set; } = new List<string>();
        public List<Deadline> UpcomingDeadlines { get; set; } = new List<Deadline>();
        public List<string> RecentActivities { get; set; } = new List<string>();
        public string UserName { get; set; } = "My Profile";
        public string EmployeeId { get; set; } = "User";
        public string ProfilePhotoUrl { get; set; } = "";
        public string PhotoBase64 { get; set; } = "";
    }

    public class Deadline
    {
        public string Title { get; set; }
        public string Date { get; set; }
    }
}
