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

namespace SkillsAuditSystem.Controllers
{
    public class TrainingRecordsController : Controller
    {
        private readonly FirestoreDb _firestore;

        public TrainingRecordsController(FirestoreDb firestore)
        {
            _firestore = firestore;

            // Set up font resolver for PDF generation
            if (GlobalFontSettings.FontResolver == null)
            {
                GlobalFontSettings.FontResolver = new FontResolver();
            }
        }

        public async Task<IActionResult> Index()
        {
            // Check if user is authenticated and is admin
            var userId = HttpContext.Session.GetString("userId");
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (string.IsNullOrEmpty(userId) || !isAdmin)
            {
                return RedirectToAction("Index", "Login");
            }

            var viewModel = new TrainingRecordsViewModel
            {
                AdminId = employeeId ?? "ADMIN",
                TrainingRecords = new List<TrainingRecordViewModel>(),
                Employees = new List<EmployeeViewModel>()
            };

            try
            {
                // Get all users from Firebase Auth to ensure we have all users
                var listUsersAsync = FirebaseAuth.DefaultInstance.ListUsersAsync(null);

                await foreach (var firebaseUser in listUsersAsync)
                {
                    // Get user details from Firestore
                    var userDoc = await _firestore.Collection("users").Document(firebaseUser.Uid).GetSnapshotAsync();

                    if (userDoc.Exists)
                    {
                        var userData = userDoc.ToDictionary();
                        var employeeIdFromUser = userData.GetValueOrDefault("employeeId", "") as string;

                        // Skip admin users and inactive users in the employee selection (only active regular employees should be available)
                        var isActive = userData.GetValueOrDefault("isActive", true) as bool?;
                        if (!string.IsNullOrEmpty(employeeIdFromUser) && employeeIdFromUser.StartsWith("ADM-"))
                        {
                            continue;
                        }

                        if (isActive != true)
                        {
                            continue;
                        }

                        var firstName = userData.GetValueOrDefault("firstName", "") as string;
                        var lastName = userData.GetValueOrDefault("lastName", "") as string;
                        var employeeName = $"{firstName} {lastName}".Trim();

                        if (string.IsNullOrWhiteSpace(employeeName))
                        {
                            employeeName = employeeIdFromUser ?? "Unknown";
                        }

                        // Add to employees list
                        viewModel.Employees.Add(new EmployeeViewModel
                        {
                            UserId = firebaseUser.Uid,
                            EmployeeId = employeeIdFromUser ?? "",
                            EmployeeName = employeeName
                        });

                        // Get trainings for this user
                        var trainingsRef = _firestore.Collection("users").Document(firebaseUser.Uid).Collection("trainings");
                        var trainingsSnapshot = await trainingsRef.GetSnapshotAsync();

                        foreach (var trainingDoc in trainingsSnapshot.Documents)
                        {
                            var training = trainingDoc.ConvertTo<Training>();
                            training.Id = trainingDoc.Id;

                            var trainingRecord = new TrainingRecordViewModel
                            {
                                UserId = firebaseUser.Uid,
                                EmployeeId = employeeIdFromUser ?? "",
                                EmployeeName = employeeName,
                                Department = userData.GetValueOrDefault("department", "") as string,
                                TrainingName = training.TrainingName,
                                Provider = training.Provider,
                                StartDate = training.StartDate,
                                EndDate = training.EndDate,
                                Status = training.GetCalculatedStatus(),
                                TrainingId = training.Id
                            };

                            viewModel.TrainingRecords.Add(trainingRecord);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                // Handle errors gracefully
                Console.WriteLine($"Error loading training records data: {ex.Message}");
            }

            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> AddTraining(string userId, string trainingName, string provider, string startDate, string endDate)
        {
            // Check if user is authenticated and is admin
            var sessionUserId = HttpContext.Session.GetString("userId");
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (string.IsNullOrEmpty(sessionUserId) || !isAdmin)
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            try
            {
                var training = new Training
                {
                    TrainingName = trainingName,
                    Provider = provider,
                    StartDate = startDate,
                    EndDate = endDate,
                    CreatedAt = DateTime.UtcNow
                };

                var userRef = _firestore.Collection("users").Document(userId);
                var trainingsRef = userRef.Collection("trainings");
                await trainingsRef.AddAsync(training);

                return Json(new { success = true, message = "Training added successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error adding training: {ex.Message}" });
            }
        }

        [HttpPut]
        public async Task<IActionResult> UpdateTraining(string userId, string trainingId, string trainingName, string provider, string startDate, string endDate)
        {
            // Check if user is authenticated and is admin
            var sessionUserId = HttpContext.Session.GetString("userId");
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (string.IsNullOrEmpty(sessionUserId) || !isAdmin)
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            try
            {
                var userRef = _firestore.Collection("users").Document(userId);
                var trainingRef = userRef.Collection("trainings").Document(trainingId);

                var updateData = new Dictionary<string, object>
                {
                    { "TrainingName", trainingName },
                    { "Provider", provider },
                    { "StartDate", startDate },
                    { "EndDate", endDate }
                };

                await trainingRef.UpdateAsync(updateData);

                return Json(new { success = true, message = "Training updated successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error updating training: {ex.Message}" });
            }
        }

        [HttpGet]
        public async Task<IActionResult> GetTraining(string userId, string trainingId)
        {
            // Check if user is authenticated and is admin
            var sessionUserId = HttpContext.Session.GetString("userId");
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (string.IsNullOrEmpty(sessionUserId) || !isAdmin)
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            try
            {
                var userRef = _firestore.Collection("users").Document(userId);
                var trainingRef = userRef.Collection("trainings").Document(trainingId);
                var trainingDoc = await trainingRef.GetSnapshotAsync();

                if (!trainingDoc.Exists)
                {
                    return Json(new { success = false, message = "Training not found" });
                }

                var training = trainingDoc.ConvertTo<Training>();
                return Json(new { success = true, training = training });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error retrieving training: {ex.Message}" });
            }
        }

        [HttpDelete]
        public async Task<IActionResult> DeleteTraining(string userId, string trainingId)
        {
            // Check if user is authenticated and is admin
            var sessionUserId = HttpContext.Session.GetString("userId");
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (string.IsNullOrEmpty(sessionUserId) || !isAdmin)
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            try
            {
                var userRef = _firestore.Collection("users").Document(userId);
                var trainingRef = userRef.Collection("trainings").Document(trainingId);

                await trainingRef.DeleteAsync();

                return Json(new { success = true, message = "Training deleted successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error deleting training: {ex.Message}" });
            }
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
                // Get all training records
                var trainingRecords = new List<TrainingRecordViewModel>();

                // Get all users from Firebase Auth to ensure we have all users
                var listUsersAsync = FirebaseAuth.DefaultInstance.ListUsersAsync(null);

                await foreach (var firebaseUser in listUsersAsync)
                {
                    // Get user details from Firestore
                    var userDoc = await _firestore.Collection("users").Document(firebaseUser.Uid).GetSnapshotAsync();

                    if (userDoc.Exists)
                    {
                        var userData = userDoc.ToDictionary();
                        var employeeIdFromUser = userData.GetValueOrDefault("employeeId", "") as string;
                        var firstName = userData.GetValueOrDefault("firstName", "") as string;
                        var lastName = userData.GetValueOrDefault("lastName", "") as string;
                        var employeeName = $"{firstName} {lastName}".Trim();

                        if (string.IsNullOrWhiteSpace(employeeName))
                        {
                            employeeName = employeeIdFromUser ?? "Unknown";
                        }

                        // Get trainings for this user
                        var trainingsRef = _firestore.Collection("users").Document(firebaseUser.Uid).Collection("trainings");
                        var trainingsSnapshot = await trainingsRef.GetSnapshotAsync();

                        foreach (var trainingDoc in trainingsSnapshot.Documents)
                        {
                            var training = trainingDoc.ConvertTo<Training>();
                            training.Id = trainingDoc.Id;

                            var trainingRecord = new TrainingRecordViewModel
                            {
                                UserId = firebaseUser.Uid,
                                EmployeeId = employeeIdFromUser ?? "",
                                EmployeeName = employeeName,
                                Department = userData.GetValueOrDefault("department", "") as string,
                                TrainingName = training.TrainingName,
                                Provider = training.Provider,
                                StartDate = training.StartDate,
                                EndDate = training.EndDate,
                                Status = training.GetCalculatedStatus(),
                                TrainingId = training.Id
                            };

                            trainingRecords.Add(trainingRecord);
                        }
                    }
                }

                // Generate CSV
                var csvContent = new System.Text.StringBuilder();
                csvContent.AppendLine("Employee Name,Training Name,Provider,Start Date,End Date,Status");

                foreach (var record in trainingRecords)
                {
                    var line = $"{EscapeCsvField(record.EmployeeName)},{EscapeCsvField(record.TrainingName)},{EscapeCsvField(record.Provider)},{EscapeCsvField(record.StartDate)},{EscapeCsvField(record.EndDate)},{EscapeCsvField(record.Status)}";
                    csvContent.AppendLine(line);
                }

                // Return CSV file
                var csvBytes = System.Text.Encoding.UTF8.GetBytes(csvContent.ToString());
                return File(csvBytes, "text/csv", $"Training_Records_Report_{DateTime.Now.ToString("yyyyMMdd_HHmmss")}.csv");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error generating training records report: {ex.Message}");
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
    }
}
