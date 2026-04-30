using Microsoft.AspNetCore.Mvc;
using Google.Cloud.Firestore;
using FirebaseAdmin.Auth;
using SkillsAuditSystem.Models;
using System.Collections.Generic;
using System.Threading.Tasks;
using PdfSharp.Pdf;
using PdfSharp.Drawing;
using PdfSharp.Fonts;
using System.IO;
using System.Linq;
using DocumentFormat.OpenXml;
using DocumentFormat.OpenXml.Packaging;
using WP = DocumentFormat.OpenXml.Wordprocessing;
using System.Security.Cryptography;
using Microsoft.Extensions.Logging;

namespace SkillsAuditSystem.Controllers
{
    public class UserManagementController : Controller
    {
        private readonly FirestoreDb _firestore;
        private readonly ILogger<UserManagementController> _logger;

        public UserManagementController(FirestoreDb firestore, ILogger<UserManagementController> logger)
        {
            _firestore = firestore;
            _logger = logger;
        }

        public async Task<IActionResult> UserManagement()
        {
            // Check if user is authenticated and is admin
            var userId = HttpContext.Session.GetString("userId");
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (string.IsNullOrEmpty(userId) || !isAdmin)
            {
                return RedirectToAction("Index", "Login");
            }

            var viewModel = new UserManagementViewModel
            {
                AdminId = employeeId ?? "ADMIN",
                Users = new List<UserInfo>()
            };

            // Set ViewBag data for department, HOD, and job title dropdowns
            ViewBag.Departments = new List<string>
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

            ViewBag.HodMap = new Dictionary<string, List<string>>
            {
                { "Office of the Director-General", new List<string> { "Tlotlo Mokaleng" } },
                { "Intergovernmental Relations", new List<string> { "Kamohelo Mkhatshwa" } },
                { "Office of the General Counsel", new List<string> { "Lethabo Rabothata" } },
                { "Budget Preparation / Budget Office", new List<string> { "Noncedo Ngcobo" } },
                { "Economic Policy and International Cooperation", new List<string> { "Noxolo Mabunda" } },
                { "Office of the Accountant-General", new List<string> { "Cassandra Munyai" } },
                { "Tax & Financial Sector Policy", new List<string> { "Fana Mokhotu" } },
                { "Assets & Liability Management", new List<string> { "Muzi Mkhize" } },
                { "Public Finance / Expenditure Control", new List<string> { "Tumelo Legodi" } },
                { "Corporate / Support Services (HR, ICT, Facilities, Legal, Security, etc.)", new List<string> { "Dikatlego Kgopane" } },
                { "Chief Procurement Office", new List<string> { "Wesley Magata" } }
            };

            ViewBag.JobTitleMap = new Dictionary<string, List<string>>
            {
                { "Budget Preparation / Budget Office", new List<string> {
                    "Expenditure Planning",
                    "Public Finance Statistics",
                    "International Development Co-operation",
                    "Fiscal Policy",
                    "Public Sector Remuneration Unit",
                    "Infrastructure Regulation and Assessment Unit"
                }},
                { "Chief Procurement Office", new List<string> {
                    "Transversal Contracting",
                    "SCM Policy, Norms & Standards",
                    "Strategic Procurement",
                    "SCM Client Support",
                    "SCM Information, Communication & Technology",
                    "SCM Governance, Monitoring & Compliance"
                }},
                { "Corporate / Support Services (HR, ICT, Facilities, Legal, Security, etc.)", new List<string> {
                    "Strategic Projects & Support",
                    "Human Resources Management",
                    "Information & Communications Technology",
                    "Facilities Management",
                    "Security Management",
                    "Media Liaison & Communications"
                }},
                { "Intergovernmental Relations", new List<string> {
                    "Local Government Budget Analysis",
                    "Intergovernmental Policy & Planning",
                    "Provincial & Local Government Infrastructure",
                    "Provincial Budget Analysis",
                    "Neighbourhood Development Unit"
                }},
                { "Assets & Liability Management", new List<string> {
                    "Sectoral Oversight",
                    "Liability Management",
                    "Financial Operations",
                    "Strategy & Risk Management",
                    "Governance & Financial Analysis"
                }},
                { "Public Finance / Expenditure Control", new List<string> {
                    "Justice & Protection Services",
                    "Economic Services",
                    "Administrative Services",
                    "Education & Related Departments & Labour",
                    "Health & Social Development",
                    "Urban Development & Infrastructure"
                }},
                { "Tax & Financial Sector Policy", new List<string> {
                    "Financial Sector Development",
                    "Financial Services",
                    "Financial Stability",
                    "Economic Tax Analysis",
                    "Legal Tax Design"
                }},
                { "Office of the General Counsel", new List<string> {
                    "Legal Services",
                    "Legislation",
                    "Public Entities Governance Unit (PEGU)"
                }},
                { "Economic Policy and International Cooperation", new List<string> {
                    "Modelling & Forecasting",
                    "Microeconomic Policy",
                    "Macroeconomic Policy",
                    "African Economic Integration",
                    "Multilateral Development Banks & Concessional Finance",
                    "Global and Emerging Markets"
                }},
                { "Office of the Accountant-General", new List<string> {
                    "Capacity Building",
                    "MFMA Implementation",
                    "Accounting Support & Integration",
                    "Internal Audit Support",
                    "Risk Management",
                    "Technical Support Services",
                    "Governance Monitoring & Compliance",
                    "Specialised Audit Services",
                    "Financial Systems",
                    "Integrated Financial Management Systems (IFMS)"
                }},
                { "Office of the Director-General", new List<string> {
                    "Financial Management (including Supply Chain Management)",
                    "Data Analytics",
                    "Strategic Management & Oversight",
                    "Enterprise Risk Management",
                    "Internal Audit"
                }}
            };

            try
            {
                // Get all users from Firebase Auth
                var listUsersAsync = FirebaseAuth.DefaultInstance.ListUsersAsync(null);

                await foreach (var firebaseUser in listUsersAsync)
                {
                    // Get user details from Firestore
                    var userDoc = await _firestore.Collection("users").Document(firebaseUser.Uid).GetSnapshotAsync();

                    if (userDoc.Exists)
                    {
                        var userData = userDoc.ToDictionary();
                        var userEmployeeId = userData.GetValueOrDefault("employeeId", "") as string;

                        // Skip admin users and inactive users in the list (admins manage other users, only show active employees)
                        var isActive = userData.GetValueOrDefault("isActive", true) as bool?;
                        if (!string.IsNullOrEmpty(userEmployeeId) && !userEmployeeId.StartsWith("ADM-") && isActive == true)
                        {
                            var userInfo = new UserInfo
                            {
                                UserId = firebaseUser.Uid,
                                Email = firebaseUser.Email,
                                FirstName = userData.GetValueOrDefault("firstName", "") as string,
                                LastName = userData.GetValueOrDefault("lastName", "") as string,
                                EmployeeId = userEmployeeId,
                                Department = userData.GetValueOrDefault("department", "Unknown") as string,
                                IsDisabled = firebaseUser.Disabled,
                                CreatedAt = firebaseUser.UserMetaData.CreationTimestamp?.ToString("yyyy-MM-dd") ?? "Unknown",
                                PhotoBase64 = userData.GetValueOrDefault("photoBase64", "") as string,
                                PhotoUrl = userData.GetValueOrDefault("photoUrl", "") as string
                            };

                            viewModel.Users.Add(userInfo);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                // Handle errors gracefully
                Console.WriteLine($"Error loading user management data: {ex.Message}");
            }

            return View(viewModel);
        }

        private string GenerateWordPasswordHash(string password, string salt)
        {
            using (var md5 = MD5.Create())
            {
                var passwordBytes = System.Text.Encoding.Unicode.GetBytes(password);
                var saltBytes = Convert.FromBase64String(salt);
                var combinedBytes = passwordBytes.Concat(saltBytes).ToArray();
                var hashBytes = md5.ComputeHash(combinedBytes);
                return Convert.ToBase64String(hashBytes);
            }
        }

        private string GenerateSalt()
        {
            var saltBytes = new byte[16];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(saltBytes);
            }
            return Convert.ToBase64String(saltBytes);
        }

        [HttpPost]
        public async Task<IActionResult> ResetPassword(string userId)
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
                // Get user email from Firebase Auth
                var userRecord = await FirebaseAuth.DefaultInstance.GetUserAsync(userId);

                // Generate password reset link using the user's email
                var resetLink = await FirebaseAuth.DefaultInstance.GeneratePasswordResetLinkAsync(userRecord.Email);

                // In a real application, you would send this link via email
                // For now, we'll just return success
                return Json(new { success = true, message = "Password reset link generated successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error: {ex.Message}" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> DisableUser(string userId, bool disable)
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
                var updateRequest = new UserRecordArgs
                {
                    Uid = userId,
                    Disabled = disable
                };

                await FirebaseAuth.DefaultInstance.UpdateUserAsync(updateRequest);

                return Json(new { success = true, message = $"User {(disable ? "disabled" : "enabled")} successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error: {ex.Message}" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> DeleteUser(string userId)
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
                // Delete user from Firebase Auth
                await FirebaseAuth.DefaultInstance.DeleteUserAsync(userId);

                // Delete user data from Firestore (optional - you might want to keep for audit)
                // await _firestore.Collection("users").Document(userId).DeleteAsync();

                return Json(new { success = true, message = "User deleted successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error: {ex.Message}" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> AddEmployee(string firstName, string lastName, string email, string employeeId, string department, string hod, string jobTitle)
        {
            // Check admin authentication
            var adminEmployeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(adminEmployeeId) && adminEmployeeId.StartsWith("ADM-01");

            if (!isAdmin)
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            try
            {
                // Validate input
                if (string.IsNullOrEmpty(firstName) || string.IsNullOrEmpty(lastName) ||
                    string.IsNullOrEmpty(email) || string.IsNullOrEmpty(employeeId) ||
                    string.IsNullOrEmpty(department) || string.IsNullOrEmpty(hod) ||
                    string.IsNullOrEmpty(jobTitle))
                {
                    return Json(new { success = false, message = "All fields are required" });
                }

                // Create user in Firebase Auth
                var userRecordArgs = new UserRecordArgs
                {
                    Email = email,
                    EmailVerified = false,
                    DisplayName = $"{firstName} {lastName}",
                    Disabled = false
                };

                var userRecord = await FirebaseAuth.DefaultInstance.CreateUserAsync(userRecordArgs);

                // Store additional user data in Firestore
                var userData = new Dictionary<string, object>
                {
                    { "firstName", firstName },
                    { "lastName", lastName },
                    { "email", email },
                    { "employeeId", employeeId },
                    { "department", department },
                    { "hod", hod },
                    { "jobTitle", jobTitle },
                    { "createdAt", DateTime.UtcNow },
                    { "isActive", true }
                };

                await _firestore.Collection("users").Document(userRecord.Uid).SetAsync(userData);

                return Json(new { success = true, message = "Employee Added successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error: {ex.Message}" });
            }
        }

        [HttpGet]
        public async Task<IActionResult> GetEmployeeDetails(string userId)
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
                // Fetch user profile data
                var userDoc = await _firestore.Collection("users").Document(userId).GetSnapshotAsync();
                if (!userDoc.Exists)
                {
                    return Json(new { success = false, message = "User not found" });
                }

                var userData = userDoc.ToDictionary();

                // Fetch skills
                var skillsRef = _firestore.Collection("users").Document(userId).Collection("skills");
                var skillsSnapshot = await skillsRef.GetSnapshotAsync();
                var skills = new List<Skill>();
                foreach (var doc in skillsSnapshot.Documents)
                {
                    try
                    {
                        var skill = Skill.FromMap(doc.ToDictionary(), doc.Id);
                        if (skill != null)
                            skills.Add(skill);
                    }
                    catch
                    {
                        // Skip invalid skill data
                    }
                }

                // Fetch qualifications
                var qualificationsRef = _firestore.Collection("users").Document(userId).Collection("qualifications");
                var qualificationsSnapshot = await qualificationsRef.GetSnapshotAsync();
                var qualifications = new List<Qualification>();
                foreach (var doc in qualificationsSnapshot.Documents)
                {
                    try
                    {
                        var qualification = Qualification.FromMap(doc.ToDictionary(), doc.Id);
                        if (qualification != null)
                            qualifications.Add(qualification);
                    }
                    catch
                    {
                        // Skip invalid qualification data
                    }
                }

                // Fetch trainings
                var trainingsRef = _firestore.Collection("users").Document(userId).Collection("trainings");
                var trainingsSnapshot = await trainingsRef.GetSnapshotAsync();
                var trainings = new List<Training>();
                foreach (var doc in trainingsSnapshot.Documents)
                {
                    try
                    {
                        var training = Training.FromMap(doc.ToDictionary(), doc.Id);
                        if (training != null)
                            trainings.Add(training);
                    }
                    catch
                    {
                        // Skip invalid training data
                    }
                }

                // Prepare response data
                var employeeDetails = new
                {
                    personalInfo = new
                    {
                        firstName = userData.GetValueOrDefault("firstName", ""),
                        lastName = userData.GetValueOrDefault("lastName", ""),
                        dateOfBirth = userData.GetValueOrDefault("dateOfBirth", ""),
                        gender = userData.GetValueOrDefault("gender", ""),
                        contact = userData.GetValueOrDefault("contact", ""),
                        idNumber = userData.GetValueOrDefault("idNumber", ""),
                        email = userData.GetValueOrDefault("email", ""),
                        photoBase64 = userData.GetValueOrDefault("photoBase64", ""),
                        photoUrl = userData.GetValueOrDefault("photoUrl", "")
                    },
                    employmentInfo = new
                    {
                        employeeId = userData.GetValueOrDefault("employeeId", ""),
                        jobTitle = userData.GetValueOrDefault("jobTitle", ""),
                        department = userData.GetValueOrDefault("department", ""),
                        hod = userData.GetValueOrDefault("hod", ""),
                        createdAt = userData.GetValueOrDefault("createdAt", "")
                    },
                    skills = skills.Select(s => new
                    {
                        name = s.Name,
                        category = s.Category,
                        proficiency = s.Proficiency
                    }),
                    qualifications = qualifications.Select(q => new
                    {
                        name = q.Name,
                        institution = q.Institution,
                        date = q.Date
                    }),
                    trainings = trainings.Select(t => new
                    {
                        trainingName = t.TrainingName,
                        provider = t.Provider,
                        startDate = t.StartDate,
                        endDate = t.EndDate,
                        status = t.Status
                    })
                };

                return Json(new { success = true, data = employeeDetails });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error: {ex.Message}" });
            }
        }

        public async Task<IActionResult> GenerateEmployeePDF(string userId)
        {
            // Check admin authentication
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (!isAdmin)
            {
                return Unauthorized();
            }

            if (string.IsNullOrEmpty(userId))
            {
                return BadRequest("User ID is required");
            }

            try
            {
                // Fetch user profile data
                var userDoc = await _firestore.Collection("users").Document(userId).GetSnapshotAsync();
                if (!userDoc.Exists)
                {
                    return NotFound("User not found");
                }

                var userData = userDoc.ToDictionary();

                // Fetch skills
                var skillsRef = _firestore.Collection("users").Document(userId).Collection("skills");
                var skillsSnapshot = await skillsRef.GetSnapshotAsync();
                var skills = new List<Skill>();
                foreach (var doc in skillsSnapshot.Documents)
                {
                    try
                    {
                        var skill = Skill.FromMap(doc.ToDictionary(), doc.Id);
                        if (skill != null)
                            skills.Add(skill);
                    }
                    catch
                    {
                        // Skip invalid skill data
                    }
                }

                // Fetch qualifications
                var qualificationsRef = _firestore.Collection("users").Document(userId).Collection("qualifications");
                var qualificationsSnapshot = await qualificationsRef.GetSnapshotAsync();
                var qualifications = new List<Qualification>();
                foreach (var doc in qualificationsSnapshot.Documents)
                {
                    try
                    {
                        var qualification = Qualification.FromMap(doc.ToDictionary(), doc.Id);
                        if (qualification != null)
                            qualifications.Add(qualification);
                    }
                    catch
                    {
                        // Skip invalid qualification data
                    }
                }

                // Fetch trainings
                var trainingsRef = _firestore.Collection("users").Document(userId).Collection("trainings");
                var trainingsSnapshot = await trainingsRef.GetSnapshotAsync();
                var trainings = new List<Training>();
                foreach (var doc in trainingsSnapshot.Documents)
                {
                    try
                    {
                        var training = Training.FromMap(doc.ToDictionary(), doc.Id);
                        if (training != null)
                            trainings.Add(training);
                    }
                    catch
                    {
                        // Skip invalid training data
                    }
                }

                // Generate PDF document
                using (var memoryStream = new MemoryStream())
                {
                    var document = new PdfDocument();
                    // Set password protection using employee ID
                    var userEmployeeId = userData.GetValueOrDefault("employeeId", "") as string ?? "";
                    document.SecuritySettings.UserPassword = userEmployeeId;
                    var page = document.AddPage();
                    var gfx = XGraphics.FromPdfPage(page);

                    // Draw watermark diagonally from bottom left to top right
                    var watermarkFont = new XFont("Arial", 72, XFontStyleEx.Bold);
                    var watermarkBrush = new XSolidBrush(XColor.FromArgb(77, 128, 128, 128)); // Gray with ~30% opacity
                    gfx.Save();
                    // Calculate angle for diagonal from bottom left to top right
                    double angle = -Math.Atan2(page.Height, page.Width) * 180 / Math.PI; // Convert to degrees
                    gfx.RotateAtTransform(angle, new XPoint(page.Width / 2, page.Height / 2));
                    gfx.DrawString("CONFIDENCIAL", watermarkFont, watermarkBrush, new XPoint(page.Width / 2, page.Height / 2), XStringFormats.Center);
                    gfx.Restore();

                    var font = new XFont("Arial", 12, XFontStyleEx.Regular);
                    var boldFont = new XFont("Arial", 12, XFontStyleEx.Bold);
                    var headerFont = new XFont("Arial", 16, XFontStyleEx.Bold);

                    double yPosition = 50;
                    double leftMargin = 50;
                    double pageWidth = page.Width - 100;

                    // Header: Name
                    var firstName = userData.GetValueOrDefault("firstName", "N/A") as string ?? "";
                    var lastName = userData.GetValueOrDefault("lastName", "N/A") as string ?? "";
                    var fullName = $"{firstName} {lastName}";
                    gfx.DrawString(fullName, headerFont, XBrushes.Black, new XRect(leftMargin, yPosition, pageWidth, 20), XStringFormats.TopLeft);
                    yPosition += 30;

                    // Photo (if available)
                    var photoBase64 = userData.GetValueOrDefault("photoBase64", "") as string;
                    if (!string.IsNullOrEmpty(photoBase64))
                    {
                        try
                        {
                            var photoBytes = Convert.FromBase64String(photoBase64);
                            using (var photoStream = new MemoryStream(photoBytes))
                            {
                                var image = XImage.FromStream(photoStream);
                                gfx.DrawImage(image, leftMargin, yPosition, 100, 100);
                            }
                        }
                        catch
                        {
                            // Skip if image fails
                        }
                    }
                    yPosition += 120;

                    // Contact Information
                    gfx.DrawString("Contact Information", boldFont, XBrushes.Black, leftMargin, yPosition);
                    yPosition += 20;
                    gfx.DrawString($"Email: {userData.GetValueOrDefault("email", "N/A")}", font, XBrushes.Black, leftMargin, yPosition);
                    yPosition += 15;
                    gfx.DrawString($"Phone: {userData.GetValueOrDefault("contact", "N/A")}", font, XBrushes.Black, leftMargin, yPosition);
                    yPosition += 15;
                    gfx.DrawString($"ID/Passport: {userData.GetValueOrDefault("idNumber", "N/A")}", font, XBrushes.Black, leftMargin, yPosition);
                    yPosition += 25;

                    // Personal Information
                    gfx.DrawString("Personal Information", boldFont, XBrushes.Black, leftMargin, yPosition);
                    yPosition += 20;
                    gfx.DrawString($"Date of Birth: {userData.GetValueOrDefault("dateOfBirth", "N/A")}", font, XBrushes.Black, leftMargin, yPosition);
                    yPosition += 15;
                    gfx.DrawString($"Gender: {userData.GetValueOrDefault("gender", "N/A")}", font, XBrushes.Black, leftMargin, yPosition);
                    yPosition += 25;

                    // Employment Information
                    gfx.DrawString("Employment Information", boldFont, XBrushes.Black, leftMargin, yPosition);
                    yPosition += 20;
                    gfx.DrawString($"Employee ID: {userData.GetValueOrDefault("employeeId", "N/A")}", font, XBrushes.Black, leftMargin, yPosition);
                    yPosition += 15;
                    gfx.DrawString($"Job Title: {userData.GetValueOrDefault("jobTitle", "N/A")}", font, XBrushes.Black, leftMargin, yPosition);
                    yPosition += 15;
                    gfx.DrawString($"Department: {userData.GetValueOrDefault("department", "N/A")}", font, XBrushes.Black, leftMargin, yPosition);
                    yPosition += 15;
                    gfx.DrawString($"Head of Department: {userData.GetValueOrDefault("hod", "N/A")}", font, XBrushes.Black, leftMargin, yPosition);
                    yPosition += 25;

                    // Skills Section
                    gfx.DrawString("Skills", boldFont, XBrushes.Black, leftMargin, yPosition);
                    yPosition += 20;
                    if (skills.Any())
                    {
                        foreach (var skill in skills)
                        {
                            if (skill != null && !string.IsNullOrEmpty(skill.Name))
                            {
                                gfx.DrawString($"• {skill.Name} - {skill.Category ?? "N/A"} ({skill.Proficiency ?? "N/A"})", font, XBrushes.Black, leftMargin, yPosition);
                                yPosition += 15;
                            }
                        }
                    }
                    else
                    {
                        gfx.DrawString("No skills recorded", font, XBrushes.Black, leftMargin, yPosition);
                        yPosition += 15;
                    }
                    yPosition += 10;

                    // Qualifications Section
                    gfx.DrawString("Qualifications", boldFont, XBrushes.Black, leftMargin, yPosition);
                    yPosition += 20;
                    if (qualifications.Any())
                    {
                        foreach (var qualification in qualifications)
                        {
                            if (qualification != null && !string.IsNullOrEmpty(qualification.Name))
                            {
                                gfx.DrawString($"• {qualification.Name} - {qualification.Institution ?? "N/A"} ({qualification.Date ?? "N/A"})", font, XBrushes.Black, leftMargin, yPosition);
                                yPosition += 15;
                            }
                        }
                    }
                    else
                    {
                        gfx.DrawString("No qualifications recorded", font, XBrushes.Black, leftMargin, yPosition);
                        yPosition += 15;
                    }
                    yPosition += 10;

                    // Trainings Section
                    gfx.DrawString("Planned Trainings", boldFont, XBrushes.Black, leftMargin, yPosition);
                    yPosition += 20;
                    var plannedTrainings = trainings.Where(t => t.Status != "Completed" && t != null).ToList();
                    if (plannedTrainings.Any())
                    {
                        foreach (var training in plannedTrainings)
                        {
                            if (training != null && !string.IsNullOrEmpty(training.TrainingName))
                            {
                                gfx.DrawString($"• {training.TrainingName ?? "N/A"} - {training.Provider ?? "N/A"} ({training.StartDate ?? "N/A"} to {training.EndDate ?? "N/A"})", font, XBrushes.Black, leftMargin, yPosition);
                                yPosition += 15;
                            }
                        }
                    }
                    else
                    {
                        gfx.DrawString("No planned trainings found", font, XBrushes.Black, leftMargin, yPosition);
                    }

                    // Add rectangular company stamp at bottom-right (20mm from edges)
                    // Convert mm to points (1 mm ≈ 2.8346 points)
                    double stampWidth = 55 * 2.8346; // 55mm
                    double stampHeight = 32 * 2.8346; // 32mm
                    double stampX = page.Width - stampWidth - (20 * 2.8346); // 20mm from right
                    double stampY = page.Height - stampHeight - (20 * 2.8346); // 20mm from bottom

                    // Pen for border
                    var stampPen = new XPen(XColor.FromArgb(15, 23, 42), 2); // #0F172A

                    // Brush with 90% opacity
                    var stampBrush = new XSolidBrush(XColor.FromArgb(230, 15, 23, 42)); // 90% opacity

                    // Draw rectangle border
                    gfx.DrawRectangle(stampPen, stampX, stampY, stampWidth, stampHeight);

                    // Fonts
                    var stampHeaderFont = new XFont("Arial", 12, XFontStyleEx.Bold);
                    var infoFont = new XFont("Arial", 10, XFontStyleEx.Regular);

                    // Text layout centered
                    double centerX = stampX + stampWidth / 2;
                    double textY = stampY + 10;

                    gfx.DrawString("SKILLS AUDIT SYSTEM", stampHeaderFont, stampBrush, new XPoint(centerX, textY), XStringFormats.Center);
                    textY += 12;
                    gfx.DrawString("1 Mothusi Road Thabong", infoFont, stampBrush, new XPoint(centerX, textY), XStringFormats.Center);
                    textY += 10;
                    gfx.DrawString("Welkom 9460", infoFont, stampBrush, new XPoint(centerX, textY), XStringFormats.Center);
                    textY += 10;
                    gfx.DrawString("Tel: 057 2526 242", infoFont, stampBrush, new XPoint(centerX, textY), XStringFormats.Center);
                    textY += 10;
                    gfx.DrawString($"AdminID: {employeeId}", infoFont, stampBrush, new XPoint(centerX, textY), XStringFormats.Center);

                    // Add note below the stamp
                    double noteY = stampY + stampHeight + 10; // 10 points below the stamp
                    var noteFont = new XFont("Arial", 10, XFontStyleEx.Regular);
                    var noteBrush = XBrushes.Red;
                    string noteText1 = "Note: ONLY Administrators and HRs staff will have access to this Confidential Employee Details.";
                    string noteText2 = "Confidentiality of this document must be maintained.";
                    gfx.DrawString(noteText1, noteFont, noteBrush, new XPoint(leftMargin, noteY), XStringFormats.TopLeft);
                    noteY += 12;
                    gfx.DrawString(noteText2, noteFont, noteBrush, new XPoint(leftMargin, noteY), XStringFormats.TopLeft);

                    document.Save(memoryStream);
                    return File(memoryStream.ToArray(), "application/pdf", $"{firstName}_{lastName}_Employee_Details.pdf");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating PDF for user {UserId}", userId);
                return StatusCode(500, "Error generating PDF");
            }
        }

        public async Task<IActionResult> GenerateEmployeeWord(string userId)
        {
            // Check admin authentication
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (!isAdmin)
            {
                return Unauthorized();
            }

            if (string.IsNullOrEmpty(userId))
            {
                return BadRequest("User ID is required");
            }

            try
            {
                // Fetch user profile data
                var userDoc = await _firestore.Collection("users").Document(userId).GetSnapshotAsync();
                if (!userDoc.Exists)
                {
                    return NotFound("User not found");
                }

                var userData = userDoc.ToDictionary();

                // Fetch skills
                var skillsRef = _firestore.Collection("users").Document(userId).Collection("skills");
                var skillsSnapshot = await skillsRef.GetSnapshotAsync();
                var skills = new List<Skill>();
                foreach (var doc in skillsSnapshot.Documents)
                {
                    try
                    {
                        var skill = Skill.FromMap(doc.ToDictionary(), doc.Id);
                        if (skill != null)
                            skills.Add(skill);
                    }
                    catch
                    {
                        // Skip invalid skill data
                    }
                }

                // Fetch qualifications
                var qualificationsRef = _firestore.Collection("users").Document(userId).Collection("qualifications");
                var qualificationsSnapshot = await qualificationsRef.GetSnapshotAsync();
                var qualifications = new List<Qualification>();
                foreach (var doc in qualificationsSnapshot.Documents)
                {
                    try
                    {
                        var qualification = Qualification.FromMap(doc.ToDictionary(), doc.Id);
                        if (qualification != null)
                            qualifications.Add(qualification);
                    }
                    catch
                    {
                        // Skip invalid qualification data
                    }
                }

                // Fetch trainings
                var trainingsRef = _firestore.Collection("users").Document(userId).Collection("trainings");
                var trainingsSnapshot = await trainingsRef.GetSnapshotAsync();
                var trainings = new List<Training>();
                foreach (var doc in trainingsSnapshot.Documents)
                {
                    try
                    {
                        var training = Training.FromMap(doc.ToDictionary(), doc.Id);
                        if (training != null)
                            trainings.Add(training);
                    }
                    catch
                    {
                        // Skip invalid training data
                    }
                }

                // Generate password hash for document protection
                var userEmployeeId = userData.GetValueOrDefault("employeeId", "") as string ?? "";
                var salt = GenerateSalt();
                var passwordHash = GenerateWordPasswordHash(userEmployeeId, salt);

                // Generate Word document in CV format
                using (var memoryStream = new MemoryStream())
                {
                    using (var wordDocument = WordprocessingDocument.Create(memoryStream, WordprocessingDocumentType.Document))
                    {
                        var mainPart = wordDocument.AddMainDocumentPart();
                        mainPart.Document = new DocumentFormat.OpenXml.Wordprocessing.Document();
                        var body = mainPart.Document.AppendChild(new WP.Body());

                        // Add document settings for password protection
                        var settingsPart = mainPart.AddNewPart<DocumentSettingsPart>();
                        settingsPart.Settings = new WP.Settings();
                        settingsPart.Settings.AppendChild(new WP.DocumentProtection
                        {
                            Edit = WP.DocumentProtectionValues.ReadOnly,
                            Enforcement = true,
                            CryptographicProviderType = WP.CryptProviderValues.RsaFull,
                            CryptographicAlgorithmClass = WP.CryptAlgorithmClassValues.Hash,
                            CryptographicAlgorithmType = WP.CryptAlgorithmValues.TypeAny,
                            CryptographicAlgorithmSid = 4, // MD5
                            Hash = passwordHash,
                            SpinCount = 100000,
                            Salt = salt
                        });

                        // CV Header: Name and Photo
                        var headerParagraph = body.AppendChild(new WP.Paragraph());
                        var headerRun = headerParagraph.AppendChild(new WP.Run());
                        headerRun.AppendChild(new WP.Text($"{userData.GetValueOrDefault("firstName", "N/A")} {userData.GetValueOrDefault("lastName", "N/A")}"));
                        headerRun.RunProperties = new WP.RunProperties { Bold = new WP.Bold(), FontSize = new WP.FontSize() { Val = "28" } };

                        // Photo placeholder (image embedding removed to ensure document opens correctly)
                        var photoParagraph = body.AppendChild(new WP.Paragraph());
                        var photoRun = photoParagraph.AppendChild(new WP.Run());
                        photoRun.AppendChild(new WP.Text("[Profile Photo Placeholder]"));
                        photoRun.RunProperties = new WP.RunProperties { Italic = new WP.Italic() };

                        // Contact Information
                        body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text("Contact Information")) { RunProperties = new WP.RunProperties { Bold = new WP.Bold() } }));
                        body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text($"Email: {userData.GetValueOrDefault("email", "N/A")}"))));
                        body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text($"Phone: {userData.GetValueOrDefault("contact", "N/A")}"))));
                        body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text($"ID/Passport: {userData.GetValueOrDefault("idNumber", "N/A")}"))));

                        // Personal Information
                        body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text("Personal Information")) { RunProperties = new WP.RunProperties { Bold = new WP.Bold() } }));
                        body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text($"Date of Birth: {userData.GetValueOrDefault("dateOfBirth", "N/A")}"))));
                        body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text($"Gender: {userData.GetValueOrDefault("gender", "N/A")}"))));

                        // Employment Information
                        body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text("Employment Information")) { RunProperties = new WP.RunProperties { Bold = new WP.Bold() } }));
                        body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text($"Employee ID: {userData.GetValueOrDefault("employeeId", "N/A")}"))));
                        body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text($"Job Title: {userData.GetValueOrDefault("jobTitle", "N/A")}"))));
                        body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text($"Department: {userData.GetValueOrDefault("department", "N/A")}"))));
                        body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text($"Head of Department: {userData.GetValueOrDefault("hod", "N/A")}"))));

                        // Skills Section
                        body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text("Skills")) { RunProperties = new WP.RunProperties { Bold = new WP.Bold() } }));
                        if (skills.Any())
                        {
                            foreach (var skill in skills)
                            {
                                if (skill != null && !string.IsNullOrEmpty(skill.Name))
                                {
                                    body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text($"• {skill.Name} - {skill.Category ?? "N/A"} ({skill.Proficiency ?? "N/A"})"))));
                                }
                            }
                        }
                        else
                        {
                            body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text("No skills recorded"))));
                        }

                        // Qualifications Section
                        body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text("Qualifications")) { RunProperties = new WP.RunProperties { Bold = new WP.Bold() } }));
                        if (qualifications.Any())
                        {
                            foreach (var qualification in qualifications)
                            {
                                if (qualification != null && !string.IsNullOrEmpty(qualification.Name))
                                {
                                    body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text($"• {qualification.Name} - {qualification.Institution ?? "N/A"} ({qualification.Date ?? "N/A"})"))));
                                }
                            }
                        }
                        else
                        {
                            body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text("No qualifications recorded"))));
                        }

                        // Trainings Section
                        body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text("Planned Trainings")) { RunProperties = new WP.RunProperties { Bold = new WP.Bold() } }));
                        var plannedTrainings = trainings.Where(t => t.Status != "Completed" && t != null).ToList();
                        if (plannedTrainings.Any())
                        {
                            foreach (var training in plannedTrainings)
                            {
                                if (training != null && !string.IsNullOrEmpty(training.TrainingName))
                                {
                                    body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text($"• {training.TrainingName ?? "N/A"} - {training.Provider ?? "N/A"} ({training.StartDate ?? "N/A"} to {training.EndDate ?? "N/A"})"))));
                                }
                            }
                        }
                        else
                        {
                            body.AppendChild(new WP.Paragraph(new WP.Run(new WP.Text("No planned trainings found"))));
                        }

                        wordDocument.Save();
                    }

                    var firstName = userData.GetValueOrDefault("firstName", "") as string ?? "";
                    var lastName = userData.GetValueOrDefault("lastName", "") as string ?? "";
                    return File(memoryStream.ToArray(), "application/vnd.openxmlformats-officedocument.wordprocessingml.document", $"{firstName}_{lastName}_Employee_Details.docx");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating Word document for user {UserId}", userId);
                return StatusCode(500, "Error generating Word document");
            }
        }
    }
}
