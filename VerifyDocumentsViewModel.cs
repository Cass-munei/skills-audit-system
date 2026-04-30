using System.Collections.Generic;

namespace SkillsAuditSystem.Models
{
    public class DocumentVerificationRecord
    {
        public string UserId { get; set; }
        public string EmployeeName { get; set; }
        public string Department { get; set; }
        public string DocumentId { get; set; }
        public string Type { get; set; }
        public string Name { get; set; }
        public string FileName { get; set; }
        public string Status { get; set; }
        public DateTime UploadedAt { get; set; }
    }

    public class VerifyDocumentsViewModel
    {
        public List<DocumentVerificationRecord> Documents { get; set; } = new List<DocumentVerificationRecord>();
        public string AdminId { get; set; }
        public string FilterStatus { get; set; }
    }
}
