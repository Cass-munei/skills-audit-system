using System.Collections.Generic;

namespace SkillsAuditSystem.Models
{
    public class DashboardStats
    {
        public int TotalEmployees { get; set; }
        public double VerifiedDocumentsPercentage { get; set; }
        public int PendingApprovals { get; set; }
        public int UpcomingTraining { get; set; }
        public Dictionary<string, int> EmployeesByDepartment { get; set; } = new Dictionary<string, int>();
        public Dictionary<string, int> MissingDocuments { get; set; } = new Dictionary<string, int>();
        public string AdminId { get; set; } = "ADMIN";
    }
}
