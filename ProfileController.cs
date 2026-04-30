
using Microsoft.AspNetCore.Mvc;
using Google.Cloud.Firestore;
using SkillsAuditSystem.Models;
using System.Threading.Tasks;
using FirebaseAdmin.Auth;
using System.Net.Http;
using System.Text;
using System.Text.Json;

namespace SkillsAuditSystem.Controllers
{
    public class ProfileController : Controller
    {
        private readonly FirestoreDb _firestore;

        public ProfileController(FirestoreDb firestore)
        {
            _firestore = firestore;
        }

        public async Task<IActionResult> Index()
        {
            // Check if user is authenticated
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                return RedirectToAction("Index", "Login");
            }

            var viewModel = new ProfileViewModel();

            try
            {
                // Fetch user data from Firestore
                var userDoc = await _firestore.Collection("users").Document(userId).GetSnapshotAsync();
                if (userDoc.Exists)
                {
                    var userData = userDoc.ToDictionary();

                    viewModel.FirstName = userData.GetValueOrDefault("firstName", "") as string ?? "";
                    viewModel.LastName = userData.GetValueOrDefault("lastName", "") as string ?? "";
                    viewModel.DateOfBirth = userData.GetValueOrDefault("dateOfBirth", "") as string ?? "";
                    viewModel.Gender = userData.GetValueOrDefault("gender", "") as string ?? "";
                    viewModel.Contact = userData.GetValueOrDefault("contact", "") as string ?? "";
                    viewModel.Email = userData.GetValueOrDefault("email", "") as string ?? "";
                    viewModel.Address = userData.GetValueOrDefault("address", "") as string ?? "";
                    viewModel.IdNumber = userData.GetValueOrDefault("idNumber", "") as string ?? "";
                    viewModel.EmployeeId = userData.GetValueOrDefault("employeeId", "") as string ?? "";
                    viewModel.JobTitle = userData.GetValueOrDefault("jobTitle", "") as string ?? "";
                    viewModel.Department = userData.GetValueOrDefault("department", "") as string ?? "";
                    viewModel.Hod = userData.GetValueOrDefault("hod", "") as string ?? "";
                    viewModel.AdditionalInfo = userData.GetValueOrDefault("additionalInfo", "") as string ?? "";
                    viewModel.PhotoUrl = userData.GetValueOrDefault("photoUrl", "") as string ?? "";
                    viewModel.PhotoBase64 = userData.GetValueOrDefault("photoBase64", "") as string ?? "";
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading profile data: {ex.Message}");
                // Continue with empty view model
            }

            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> UpdateProfile([FromBody] ProfileViewModel model)
        {
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                return Json(new { success = false, message = "User not authenticated" });
            }

            try
            {
                // Update user data in Firestore
                var userDoc = _firestore.Collection("users").Document(userId);

                var updates = new Dictionary<string, object>
                {
                    ["firstName"] = model.FirstName,
                    ["lastName"] = model.LastName,
                    ["dateOfBirth"] = model.DateOfBirth,
                    ["gender"] = model.Gender,
                    ["contact"] = model.Contact,
                    ["email"] = model.Email,
                    ["address"] = model.Address,
                    ["idNumber"] = model.IdNumber,
                    ["employeeId"] = model.EmployeeId,
                    ["jobTitle"] = model.JobTitle,
                    ["department"] = model.Department,
                    ["hod"] = model.Hod,
                    ["additionalInfo"] = model.AdditionalInfo,
                    ["updatedAt"] = DateTime.UtcNow
                };

                await userDoc.UpdateAsync(updates);

                return Json(new { success = true, message = "Profile updated successfully" });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error updating profile: {ex.Message}");
                return Json(new { success = false, message = "Failed to update profile" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordModel model)
        {
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                return Json(new { success = false, message = "User not authenticated" });
            }

            if (model == null || string.IsNullOrEmpty(model.CurrentPassword) || string.IsNullOrEmpty(model.NewPassword))
            {
                return Json(new { success = false, message = "Invalid password data" });
            }

            try
            {
                // Update the password using Firebase Auth Admin SDK
                // Since the user is authenticated via session, we can update the password directly
                var updateArgs = new UserRecordArgs()
                {
                    Uid = userId,
                    Password = model.NewPassword
                };

                await FirebaseAuth.DefaultInstance.UpdateUserAsync(updateArgs);

                return Json(new { success = true, message = "Password changed successfully" });
            }
            catch (FirebaseAuthException ex)
            {
                Console.WriteLine($"Firebase Auth error changing password: {ex.Message}");
                return Json(new { success = false, message = "Failed to change password. Please try again." });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error changing password: {ex.Message}");
                return Json(new { success = false, message = "Failed to change password" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> UploadPhoto(IFormFile photo)
        {
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                return Json(new { success = false, message = "User not authenticated" });
            }

            if (photo == null || photo.Length == 0)
            {
                return Json(new { success = false, message = "No file uploaded" });
            }

            try
            {
                // Convert photo to base64
                using (var memoryStream = new MemoryStream())
                {
                    await photo.CopyToAsync(memoryStream);
                    var photoBytes = memoryStream.ToArray();
                    var photoBase64 = Convert.ToBase64String(photoBytes);

                    // Update Firestore with base64 photo
                    var userDoc = _firestore.Collection("users").Document(userId);
                    await userDoc.UpdateAsync(new Dictionary<string, object> { ["photoBase64"] = photoBase64 });

                    return Json(new { success = true, message = "Photo uploaded successfully", photoBase64 = photoBase64 });
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error uploading photo: {ex.Message}");
                return Json(new { success = false, message = "Failed to upload photo" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> DeletePhoto()
        {
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                return Json(new { success = false, message = "User not authenticated" });
            }

            try
            {
                // Remove photoUrl and photoBase64 from Firestore
                var userDoc = _firestore.Collection("users").Document(userId);
                await userDoc.UpdateAsync(new Dictionary<string, object> { ["photoUrl"] = "", ["photoBase64"] = "" });

                return Json(new { success = true, message = "Photo deleted successfully" });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error deleting photo: {ex.Message}");
                return Json(new { success = false, message = "Failed to delete photo" });
            }
        }
    }
}
