using Microsoft.AspNetCore.Mvc;
using FirebaseAdmin.Auth;
using Google.Cloud.Firestore;
using System.Threading.Tasks;

namespace SkillsAuditSystem.Controllers
{
    public class LoginController : Controller
    {
        private readonly FirestoreDb _firestore;

        public LoginController(FirestoreDb firestore)
        {
            _firestore = firestore;
        }

        public IActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Login(string email, string password, bool rememberMe, string userId)
        {
            try
            {
                if (string.IsNullOrEmpty(userId))
                {
                    TempData["ErrorMessage"] = "User ID is required";
                    return RedirectToAction("Index");
                }

                // Verify user exists in Firebase Auth
                UserRecord firebaseUser;
                try
                {
                    firebaseUser = await FirebaseAuth.DefaultInstance.GetUserAsync(userId);
                }
                catch (FirebaseAuthException ex)
                {
                    Console.WriteLine($"Firebase Auth verification failed: {ex.Message}");
                    TempData["ErrorMessage"] = "Invalid credentials. Only registered users can access the dashboard.";
                    return RedirectToAction("Index");
                }

                // Check if user account is disabled
                if (firebaseUser.Disabled)
                {
                    TempData["ErrorMessage"] = "The user account has been disabled by an administrator.";
                    return RedirectToAction("Index");
                }

                // Fetch user data from Firestore
                DocumentReference userDoc = _firestore.Collection("users").Document(userId);
                DocumentSnapshot snapshot = await userDoc.GetSnapshotAsync();

                if (!snapshot.Exists)
                {
                    TempData["ErrorMessage"] = "User profile not found. Please contact administrator.";
                    return RedirectToAction("Index");
                }

                var userData = snapshot.ToDictionary();

                // Set session data
                HttpContext.Session.SetString("userId", userId);
                HttpContext.Session.SetString("userEmail", firebaseUser.Email ?? email);
                HttpContext.Session.SetString("userFirstName", userData.GetValueOrDefault("firstName", "Unknown")?.ToString() ?? "Unknown");
                HttpContext.Session.SetString("userLastName", userData.GetValueOrDefault("lastName", "User")?.ToString() ?? "User");
                HttpContext.Session.SetString("employeeId", userData.GetValueOrDefault("employeeId", "N/A")?.ToString() ?? "N/A");

                // Redirect to dashboard on successful login
                return RedirectToAction("Index", "Dashboard");
            }
            catch (Exception ex)
            {
                // Log the error and show generic message
                Console.WriteLine($"Login error: {ex.Message}");
                TempData["ErrorMessage"] = "An error occurred during login. Please try again.";
                return RedirectToAction("Index");
            }
        }
    }
}
