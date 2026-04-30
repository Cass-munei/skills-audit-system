using System.Collections.Generic;

namespace SkillsAuditSystem.Models
{
    public class TrainingRecordViewModel
    {
        public string UserId { get; set; }
        public string EmployeeId { get; set; }
        public string EmployeeName { get; set; }
        public string Department { get; set; }
        public string TrainingName { get; set; }
        public string Provider { get; set; }
        public string StartDate { get; set; }
        public string EndDate { get; set; }
        public string Status { get; set; }
        public string TrainingId { get; set; }
    }

    public class EmployeeViewModel
    {
        public string UserId { get; set; }
        public string EmployeeId { get; set; }
        public string EmployeeName { get; set; }
    }

    public class TrainingRecordsViewModel
    {
        public List<TrainingRecordViewModel> TrainingRecords { get; set; } = new List<TrainingRecordViewModel>();
        public List<EmployeeViewModel> Employees { get; set; } = new List<EmployeeViewModel>();
        public string AdminId { get; set; }
    }
}
