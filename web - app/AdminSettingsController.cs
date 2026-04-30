using Microsoft.AspNetCore.Mvc;
using Google.Cloud.Firestore;
using SkillsAuditSystem.Models;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using Microsoft.Extensions.Logging;

namespace SkillsAuditSystem.Controllers
{
    public class AdminSettingsController : Controller
    {
        private readonly FirestoreDb _firestore;
        private readonly ILogger<AdminSettingsController> _logger;

        public AdminSettingsController(FirestoreDb firestore, ILogger<AdminSettingsController> logger)
        {
            _firestore = firestore;
            _logger = logger;
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

            // Fetch current settings from Firestore
            var settingsDoc = await _firestore.Collection("settings").Document("system").GetSnapshotAsync();
            var settings = new AdminSettingsViewModel
            {
                AdminId = employeeId ?? "ADMIN"
            };

            if (settingsDoc.Exists)
            {
                var data = settingsDoc.ToDictionary();
                settings.MaintenanceMode = data.GetValueOrDefault("maintenanceMode", false) as bool?;
                settings.EmailNotifications = data.GetValueOrDefault("emailNotifications", true) as bool?;
                settings.AutoBackup = data.GetValueOrDefault("autoBackup", true) as bool?;
                settings.TwoFactorAuth = data.GetValueOrDefault("twoFactorAuth", false) as bool?;
                settings.SessionTimeout = Convert.ToInt32(data.GetValueOrDefault("sessionTimeout", 30));
                settings.PasswordLength = Convert.ToInt32(data.GetValueOrDefault("passwordLength", 8));
                settings.DocVerificationAlerts = data.GetValueOrDefault("docVerificationAlerts", true) as bool?;
                settings.TrainingCompletionAlerts = data.GetValueOrDefault("trainingCompletionAlerts", true) as bool?;
                settings.SystemErrorAlerts = data.GetValueOrDefault("systemErrorAlerts", true) as bool?;
            }
            else
            {
                // Default settings
                settings.MaintenanceMode = false;
                settings.EmailNotifications = true;
                settings.AutoBackup = true;
                settings.TwoFactorAuth = false;
                settings.SessionTimeout = 30;
                settings.PasswordLength = 8;
                settings.DocVerificationAlerts = true;
                settings.TrainingCompletionAlerts = true;
                settings.SystemErrorAlerts = true;
            }

            return View(settings);
        }

        [HttpPost]
        public async Task<IActionResult> SaveSettings([FromBody] AdminSettingsViewModel settings)
        {
            try
            {
                // Check if user is authenticated and is admin
                var userId = HttpContext.Session.GetString("userId");
                var employeeId = HttpContext.Session.GetString("employeeId");
                var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

                if (string.IsNullOrEmpty(userId) || !isAdmin)
                {
                    return Json(new { success = false, message = "Unauthorized access" });
                }

                // Save settings to Firestore
                var settingsDoc = _firestore.Collection("settings").Document("system");
                var settingsData = new Dictionary<string, object>
                {
                    { "maintenanceMode", settings.MaintenanceMode ?? false },
                    { "emailNotifications", settings.EmailNotifications ?? true },
                    { "autoBackup", settings.AutoBackup ?? true },
                    { "twoFactorAuth", settings.TwoFactorAuth ?? false },
                    { "sessionTimeout", settings.SessionTimeout ?? 30 },
                    { "passwordLength", settings.PasswordLength ?? 8 },
                    { "docVerificationAlerts", settings.DocVerificationAlerts ?? true },
                    { "trainingCompletionAlerts", settings.TrainingCompletionAlerts ?? true },
                    { "systemErrorAlerts", settings.SystemErrorAlerts ?? true },
                    { "updatedAt", Timestamp.GetCurrentTimestamp() },
                    { "updatedBy", employeeId }
                };

                await settingsDoc.SetAsync(settingsData, SetOptions.Overwrite);

                _logger.LogInformation($"Settings updated by admin {employeeId}");

                return Json(new { success = true, message = "Settings saved successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error saving settings");
                return Json(new { success = false, message = "Error saving settings: " + ex.Message });
            }
        }
    }
}
