using Microsoft.AspNetCore.Mvc;
using FirebaseAdmin.Auth;
using Google.Cloud.Firestore;
using System.Threading.Tasks;
using System.Text.RegularExpressions;
using System.Net.Http;
using System.Text;
using System.Text.Json;

namespace SkillsAuditSystem.Controllers
{
    public class EmployeeLoginController : Controller
    {
        private readonly FirestoreDb _firestore;

        public EmployeeLoginController(FirestoreDb firestore)
        {
            _firestore = firestore;
        }

        public IActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Login(string employeeId, string password)
        {
            try
            {
                // Validate Employee ID format (supports both EMP-00XXXX and ADM-01XXXX)
                if (string.IsNullOrEmpty(employeeId))
                {
                    TempData["ErrorMessage"] = "Please enter Employee ID";
                    return RedirectToAction("Index");
                }

                if (employeeId.Length != 10)
                {
                    TempData["ErrorMessage"] = "Employee ID must be 10 characters";
                    return RedirectToAction("Index");
                }

                bool isAdmin = employeeId.StartsWith("ADM-01");
                bool isEmployee = employeeId.StartsWith("EMP-00");

                if (!isAdmin && !isEmployee)
                {
                    TempData["ErrorMessage"] = "Employee ID must start with EMP-00 or ADM-01";
                    return RedirectToAction("Index");
                }

                string lastFour = employeeId.Substring(6);
                if (!Regex.IsMatch(lastFour, @"^\d{4}$"))
                {
                    TempData["ErrorMessage"] = "Last four characters must be digits";
                    return RedirectToAction("Index");
                }

                if (string.IsNullOrEmpty(password))
                {
                    TempData["ErrorMessage"] = "Please enter password";
                    return RedirectToAction("Index");
                }

                // Check the appropriate collection based on ID type
                string collectionName = isAdmin ? "admin_ids" : "employee_ids";
                DocumentReference employeeDoc = _firestore.Collection(collectionName).Document(employeeId);
                DocumentSnapshot employeeSnapshot = await employeeDoc.GetSnapshotAsync();

                if (!employeeSnapshot.Exists)
                {
                    Console.WriteLine($"Employee ID {employeeId} not found in collection {collectionName}");
                    TempData["ErrorMessage"] = "Invalid Employee ID or Password";
                    return RedirectToAction("Index");
                }

                var employeeData = employeeSnapshot.ToDictionary();
                string firebaseUserId = employeeData.GetValueOrDefault("uid", "").ToString();

                if (string.IsNullOrEmpty(firebaseUserId))
                {
                    // Try to repair by finding user by email
                    string email = employeeData.GetValueOrDefault("email", "").ToString();
                    if (!string.IsNullOrEmpty(email))
                    {
                        try
                        {
                            var userByEmail = await FirebaseAuth.DefaultInstance.GetUserByEmailAsync(email);
                            firebaseUserId = userByEmail.Uid;
                            // Update the document with the uid
                            await employeeDoc.UpdateAsync(new Dictionary<string, object> { { "uid", firebaseUserId } });
                        }
                        catch (FirebaseAuthException)
                        {
                            TempData["ErrorMessage"] = "User account not properly configured. Please contact administrator.";
                            return RedirectToAction("Index");
                        }
                    }
                    else
                    {
                        TempData["ErrorMessage"] = "User account not properly configured. Please contact administrator.";
                        return RedirectToAction("Index");
                    }
                }

                // Now fetch user data from the users collection using the Firebase user ID
                DocumentReference userDoc = _firestore.Collection("users").Document(firebaseUserId);
                DocumentSnapshot userSnapshot = await userDoc.GetSnapshotAsync();

                if (!userSnapshot.Exists)
                {
                    TempData["ErrorMessage"] = "Invalid Employee ID or Password";
                    return RedirectToAction("Index");
                }

                var userData = userSnapshot.ToDictionary();

                // Get Firebase user record first
                UserRecord firebaseUser;
                try
                {
                    firebaseUser = await FirebaseAuth.DefaultInstance.GetUserAsync(firebaseUserId);
                }
                catch (FirebaseAuthException)
                {
                    TempData["ErrorMessage"] = "Account not found";
                    return RedirectToAction("Index");
                }

                // Check if user account is disabled
                if (firebaseUser.Disabled)
                {
                    TempData["ErrorMessage"] = "The user account has been disabled by an administrator.";
                    return RedirectToAction("Index");
                }

                // Verify password with Firebase Auth using REST API
                string userEmail = firebaseUser.Email ?? userData.GetValueOrDefault("email", "").ToString();
                if (string.IsNullOrEmpty(userEmail))
                {
                    TempData["ErrorMessage"] = "User account not properly configured. Please contact administrator.";
                    return RedirectToAction("Index");
                }

                // Verify password using Firebase Auth REST API
                using (var httpClient = new HttpClient())
                {
                    var apiKey = "AIzaSyDpSVmMWgp8tv0WbAk38tDpyV25Aae2mWE"; // Replace with your actual Firebase API key
                    var verifyPasswordUrl = $"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={apiKey}";

                    var payload = new
                    {
                        email = userEmail,
                        password = password,
                        returnSecureToken = true
                    };

                    var jsonPayload = JsonSerializer.Serialize(payload);
                    var content = new StringContent(jsonPayload, Encoding.UTF8, "application/json");

                    var response = await httpClient.PostAsync(verifyPasswordUrl, content);
                    if (!response.IsSuccessStatusCode)
                    {
                        // Check if the user account is disabled
                        if (firebaseUser.Disabled)
                        {
                            TempData["ErrorMessage"] = "The user account has been disabled by an administrator.";
                        }
                        else
                        {
                            TempData["ErrorMessage"] = "Invalid Employee ID or Password";
                        }
                        return RedirectToAction("Index");
                    }
                }

                // Set session data
                HttpContext.Session.SetString("userId", firebaseUserId);
                HttpContext.Session.SetString("userEmail", firebaseUser.Email ?? "");
                HttpContext.Session.SetString("userFirstName", userData.GetValueOrDefault("firstName", "Unknown")?.ToString() ?? "Unknown");
                HttpContext.Session.SetString("userLastName", userData.GetValueOrDefault("lastName", "User")?.ToString() ?? "User");
                HttpContext.Session.SetString("employeeId", employeeId);
                HttpContext.Session.SetString("isAdmin", isAdmin ? "true" : "false");
                HttpContext.Session.SetString("userDepartment", userData.GetValueOrDefault("department", "DefaultDepartment") as string);

                Console.WriteLine($"Login successful - EmployeeId: {employeeId}, IsAdmin: {isAdmin}");

                // Redirect to dashboard
                return RedirectToAction("Index", "Dashboard");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Employee login error: {ex.Message}");
                TempData["ErrorMessage"] = "An error occurred during login. Please try again.";
                return RedirectToAction("Index");
            }
        }

        [HttpGet]
        public async Task<IActionResult> GetProfileImage(string employeeId)
        {
            try
            {
                if (string.IsNullOrEmpty(employeeId) || employeeId.Length != 10 || !employeeId.StartsWith("EMP-00"))
                {
                    return Json(new { imagePath = "/images/default-avatar.png" });
                }

                // First, get the Firebase user ID from employee_ids collection
                DocumentReference employeeDoc = _firestore.Collection("employee_ids").Document(employeeId);
                DocumentSnapshot employeeSnapshot = await employeeDoc.GetSnapshotAsync();

                if (!employeeSnapshot.Exists)
                {
                    return Json(new { imagePath = "/images/default-avatar.png" });
                }

                var employeeData = employeeSnapshot.ToDictionary();
                string firebaseUserId = employeeData.GetValueOrDefault("uid", "").ToString();

                if (string.IsNullOrEmpty(firebaseUserId))
                {
                    return Json(new { imagePath = "/images/default-avatar.png" });
                }

                // Now fetch user photo from the users collection using Firebase user ID
                DocumentReference userDoc = _firestore.Collection("users").Document(firebaseUserId);
                DocumentSnapshot userSnapshot = await userDoc.GetSnapshotAsync();

                if (userSnapshot.Exists)
                {
                    var userData = userSnapshot.ToDictionary();
                    string photoUrl = userData.GetValueOrDefault("photoUrl", "/images/default-avatar.png")?.ToString() ?? "/images/default-avatar.png";
                    return Json(new { imagePath = photoUrl });
                }

                return Json(new { imagePath = "/images/default-avatar.png" });
            }
            catch
            {
                return Json(new { imagePath = "/images/default-avatar.png" });
            }
        }
    }
}
