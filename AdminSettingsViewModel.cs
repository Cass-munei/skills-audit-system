using System.ComponentModel.DataAnnotations;

namespace SkillsAuditSystem.Models
{
    public class AdminSettingsViewModel
    {
        public string AdminId { get; set; }

        // General Settings
        public bool? MaintenanceMode { get; set; }
        public bool? EmailNotifications { get; set; }
        public bool? AutoBackup { get; set; }

        // Security Settings
        public bool? TwoFactorAuth { get; set; }

        [Range(5, 480, ErrorMessage = "Session timeout must be between 5 and 480 minutes")]
        public int? SessionTimeout { get; set; }

        [Range(6, 20, ErrorMessage = "Password length must be between 6 and 20 characters")]
        public int? PasswordLength { get; set; }

        // Notification Settings
        public bool? DocVerificationAlerts { get; set; }
        public bool? TrainingCompletionAlerts { get; set; }
        public bool? SystemErrorAlerts { get; set; }
    }
}
