using System.ComponentModel.DataAnnotations;

namespace SkillsAuditSystem.Models
{
    public class ProfileViewModel
    {
        // Personal Information
        [Display(Name = "First Name")]
        public string FirstName { get; set; } = "";

        [Display(Name = "Last Name")]
        public string LastName { get; set; } = "";

        [Display(Name = "Date of Birth")]
        public string DateOfBirth { get; set; } = "";

        [Display(Name = "Gender")]
        public string Gender { get; set; } = "";

        [Display(Name = "Contact Number")]
        public string Contact { get; set; } = "";

        [Display(Name = "Email")]
        public string Email { get; set; } = "";

        [Display(Name = "Address")]
        public string Address { get; set; } = "";

        [Display(Name = "ID/PASSPORT")]
        public string IdNumber { get; set; } = "";

        // Employment Information
        [Display(Name = "Employee ID")]
        public string EmployeeId { get; set; } = "";

        [Display(Name = "Job Title/Role")]
        public string JobTitle { get; set; } = "";

        [Display(Name = "Department/Unit")]
        public string Department { get; set; } = "";

        [Display(Name = "Head Of Department")]
        public string Hod { get; set; } = "";

        // Additional Information
        [Display(Name = "Additional Information")]
        public string AdditionalInfo { get; set; } = "";

        // Profile Photo
        public string PhotoUrl { get; set; } = "";
        public string PhotoBase64 { get; set; } = "";

        // Edit Mode
        public bool IsEditing { get; set; } = false;

        // Password Reset (for edit mode)
        [Display(Name = "Current Password")]
        public string CurrentPassword { get; set; } = "";

        [Display(Name = "New Password")]
        public string NewPassword { get; set; } = "";

        [Display(Name = "Confirm New Password")]
        public string ConfirmPassword { get; set; } = "";
    }
}
