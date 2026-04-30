using Microsoft.AspNetCore.Mvc;
using FirebaseAdmin.Auth;
using System.Threading.Tasks;

namespace SkillsAuditSystem.Controllers
{
    public class ForgotPasswordController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> SendResetEmail(string email)
        {
            try
            {
                if (string.IsNullOrEmpty(email))
                {
                    TempData["ErrorMessage"] = "Please enter your email address";
                    return RedirectToAction("Index");
                }

                if (!email.Contains("@") || !email.EndsWith("treasury.gov.za"))
                {
                    TempData["ErrorMessage"] = "Please enter a valid work email ending with treasury.gov.za";
                    return RedirectToAction("Index");
                }

                // Send password reset email using Firebase
                await FirebaseAuth.DefaultInstance.GeneratePasswordResetLinkAsync(email);

                TempData["SuccessMessage"] = "Password reset email sent! Check your inbox and follow the instructions.";
                return RedirectToAction("Index");
            }
            catch (FirebaseAuthException ex)
            {
                Console.WriteLine($"Firebase Auth error: {ex.Message}");
                TempData["ErrorMessage"] = ex.Message ?? "Failed to send reset email. Please try again.";
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"General error: {ex.Message}");
                TempData["ErrorMessage"] = "An error occurred. Please try again.";
                return RedirectToAction("Index");
            }
        }
    }
}
