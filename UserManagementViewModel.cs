using System.Collections.Generic;

namespace SkillsAuditSystem.Models
{
    public class UserManagementViewModel
    {
        public List<UserInfo> Users { get; set; } = new List<UserInfo>();
        public string AdminId { get; set; }
    }

    public class UserInfo
    {
        public string UserId { get; set; }
        public string Email { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string EmployeeId { get; set; }
        public string Department { get; set; }
        public bool IsDisabled { get; set; }
        public string CreatedAt { get; set; }
        public string PhotoBase64 { get; set; }
        public string PhotoUrl { get; set; }
    }
}
