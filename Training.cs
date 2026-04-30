using Google.Cloud.Firestore;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace SkillsAuditSystem.Models
{
    [FirestoreData]
    public class Training
    {
        [JsonIgnore]
        [FirestoreProperty]
        public string? Id { get; set; }

        [Required]
        [FirestoreProperty]
        public string TrainingName { get; set; }

        [Required]
        [FirestoreProperty]
        public string Provider { get; set; }

        [Required]
        [FirestoreProperty]
        public string StartDate { get; set; }

        [Required]
        [FirestoreProperty]
        public string EndDate { get; set; }

        [FirestoreProperty]
        public DateTime CreatedAt { get; set; }

        public string Status => GetCalculatedStatus();

        public Training()
        {
            TrainingName = string.Empty;
            Provider = string.Empty;
            StartDate = string.Empty;
            EndDate = string.Empty;
        }

        public Training(string id, string trainingName, string provider, string startDate, string endDate)
        {
            Id = id;
            TrainingName = trainingName;
            Provider = provider;
            StartDate = startDate;
            EndDate = endDate;
        }

        public static Training FromMap(Dictionary<string, object> data, string id)
        {
            if (data == null) return null;

            string GetString(string key)
                => data.TryGetValue(key, out var value) && value is string str ? str : null;

            return new Training(
                id: id,
                trainingName: GetString("TrainingName") ?? GetString("trainingName") ?? "",
                provider: GetString("Provider") ?? GetString("provider") ?? "",
                startDate: GetString("StartDate") ?? GetString("startDate") ?? "",
                endDate: GetString("EndDate") ?? GetString("endDate") ?? ""
            );
        }

        public Dictionary<string, object> ToMap()
        {
            return new Dictionary<string, object>
            {
                { "TrainingName", TrainingName },
                { "Provider", Provider },
                { "StartDate", StartDate },
                { "EndDate", EndDate }
            };
        }

        public string GetCalculatedStatus()
        {
            if (!string.IsNullOrEmpty(StartDate) && !string.IsNullOrEmpty(EndDate) &&
                DateTime.TryParse(StartDate, out var start) && DateTime.TryParse(EndDate, out var end))
            {
                var now = DateTime.Now;
                if (now < start)
                    return "Upcoming";
                else if (now > end)
                    return "Completed";
                else
                    return "In Progress";
            }
            return "Unknown";
        }
    }

    public class TrainingCreateDto
    {
        [Required]
        public string TrainingName { get; set; }

        [Required]
        public string Provider { get; set; }

        [Required]
        public string StartDate { get; set; }

        [Required]
        public string EndDate { get; set; }
    }
}
