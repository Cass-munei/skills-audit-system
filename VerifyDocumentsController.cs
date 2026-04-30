using Microsoft.AspNetCore.Mvc;
using Google.Cloud.Firestore;
using SkillsAuditSystem.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace SkillsAuditSystem.Controllers
{
    public class VerifyDocumentsController : Controller
    {
        private readonly FirestoreDb _firestore;

        public VerifyDocumentsController(FirestoreDb firestore)
        {
            _firestore = firestore;
        }

        public async Task<IActionResult> Index(string status = null)
        {
            // Check if user is authenticated and is admin
            var userId = HttpContext.Session.GetString("userId");
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (string.IsNullOrEmpty(userId) || !isAdmin)
            {
                return RedirectToAction("Index", "Login");
            }

            var viewModel = new VerifyDocumentsViewModel
            {
                AdminId = employeeId ?? "ADMIN",
                Documents = new List<DocumentVerificationRecord>(),
                FilterStatus = status // Add filter status to view model
            };

            try
            {
                // Get all users from Firestore
                var usersRef = _firestore.Collection("users");
                var usersSnapshot = await usersRef.GetSnapshotAsync();

                foreach (var userDoc in usersSnapshot.Documents)
                {
                    var userData = userDoc.ToDictionary();
                    var userEmployeeId = userData.GetValueOrDefault("employeeId", "") as string;

                    // Skip admin users
                    if (!string.IsNullOrEmpty(userEmployeeId) && !userEmployeeId.StartsWith("ADM-"))
                    {
                        var firstName = userData.GetValueOrDefault("firstName", "") as string;
                        var lastName = userData.GetValueOrDefault("lastName", "") as string;
                        var department = userData.GetValueOrDefault("department", "Unknown") as string;
                        var employeeName = $"{firstName} {lastName}".Trim();

                        // Get documents for this user
                        var documentsRef = _firestore.Collection("users").Document(userDoc.Id).Collection("documents");
                        var documentsSnapshot = await documentsRef.GetSnapshotAsync();

                        foreach (var docSnapshot in documentsSnapshot.Documents)
                        {
                            var document = docSnapshot.ConvertTo<Document>();
                            document.Id = docSnapshot.Id;

                            var record = new DocumentVerificationRecord
                            {
                                UserId = userDoc.Id,
                                EmployeeName = employeeName,
                                Department = department,
                                DocumentId = document.Id,
                                Type = document.Type,
                                Name = document.Name,
                                FileName = document.FileName,
                                Status = document.Status,
                                UploadedAt = document.UploadedAt
                            };

                            viewModel.Documents.Add(record);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                // Handle errors gracefully
                Console.WriteLine($"Error loading verify documents data: {ex.Message}");
            }

            // Sort documents by upload date, most recent first
            viewModel.Documents = viewModel.Documents.OrderByDescending(d => d.UploadedAt).ToList();

            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> VerifyDocument(string userId, string documentId, string status)
        {
            // Check admin authentication
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (!isAdmin)
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            // Validate status values and map to lowercase
            string mappedStatus;
            switch (status.ToLower())
            {
                case "verify":
                    mappedStatus = "verified";
                    break;
                case "reject":
                    mappedStatus = "rejected";
                    break;
                case "pending":
                    mappedStatus = "pending";
                    break;
                default:
                    return Json(new { success = false, message = "Invalid status value" });
            }

            try
            {
                var documentRef = _firestore.Collection("users").Document(userId).Collection("documents").Document(documentId);
                await documentRef.UpdateAsync(new Dictionary<string, object>
                {
                    { "status", mappedStatus }
                });

                return Json(new { success = true, message = $"Document status updated to {mappedStatus}" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error: {ex.Message}" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> DeleteDocument(string userId, string documentId)
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
                var documentRef = _firestore.Collection("users").Document(userId).Collection("documents").Document(documentId);
                await documentRef.DeleteAsync();

                return Json(new { success = true, message = "Document deleted successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error: {ex.Message}" });
            }
        }
    }
}
