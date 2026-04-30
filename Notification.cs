using System;
using Google.Cloud.Firestore;

namespace SkillsAuditSystem.Models
{
    [FirestoreData]
    public class Notification
    {
        [FirestoreProperty]
        public string Id { get; set; }

        [FirestoreProperty]
        public string Title { get; set; }

        [FirestoreProperty]
        public string Message { get; set; }

        [FirestoreProperty]
        public DateTime Timestamp { get; set; }

        [FirestoreProperty]
        public bool IsRead { get; set; }

        [FirestoreProperty]
        public string UserId { get; set; }

        [FirestoreProperty]
        public string RecipientType { get; set; }

        [FirestoreProperty]
        public string Department { get; set; }

        [FirestoreProperty]
        public string EmployeeId { get; set; }

        [FirestoreProperty]
        public string AttachmentUrl { get; set; }

        [FirestoreProperty]
        public string AttachmentName { get; set; }

        // Helper method to convert to Firestore map
        public Dictionary<string, object> ToMap()
        {
            return new Dictionary<string, object>
            {
                { "Id", Id },
                { "Title", Title },
                { "Message", Message },
                { "Timestamp", Timestamp },
                { "IsRead", IsRead },
                { "UserId", UserId },
                { "RecipientType", RecipientType },
                { "Department", Department },
                { "EmployeeId", EmployeeId },
                { "AttachmentUrl", AttachmentUrl },
                { "AttachmentName", AttachmentName }
            };
        }
    }
}
