using Google.Cloud.Firestore;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace SkillsAuditSystem.Models
{
    [FirestoreData]
    public class TrainingFeedback
    {
        [JsonIgnore]
        [FirestoreProperty]
        public string? Id { get; set; }

        [Required]
        [FirestoreProperty]
        public string UserId { get; set; }

        [Required]
        [FirestoreProperty]
        public string TrainingId { get; set; }

        [Required]
        [FirestoreProperty]
        public string TrainingName { get; set; }

        [Required]
        [FirestoreProperty]
        public string FeedbackText { get; set; }

        [FirestoreProperty]
        public double SentimentScore { get; set; } // -1 to 1 (negative to positive)

        [FirestoreProperty]
        public string SentimentLabel { get; set; } // "positive", "neutral", "negative"

        [FirestoreProperty]
        public double ConfidenceScore { get; set; } // 0 to 1

        [FirestoreProperty]
        public DateTime SubmittedAt { get; set; }

        [FirestoreProperty]
        public bool IsAnalyzed { get; set; }

        // Additional metadata
        [FirestoreProperty]
        public string EmployeeId { get; set; }

        [FirestoreProperty]
        public string Department { get; set; }

        public TrainingFeedback()
        {
            UserId = string.Empty;
            TrainingId = string.Empty;
            TrainingName = string.Empty;
            FeedbackText = string.Empty;
            SentimentLabel = "neutral";
            EmployeeId = string.Empty;
            Department = string.Empty;
            SubmittedAt = DateTime.UtcNow;
        }

        public Dictionary<string, object> ToMap()
        {
            return new Dictionary<string, object>
            {
                { "UserId", UserId },
                { "TrainingId", TrainingId },
                { "TrainingName", TrainingName },
                { "FeedbackText", FeedbackText },
                { "SentimentScore", SentimentScore },
                { "SentimentLabel", SentimentLabel },
                { "ConfidenceScore", ConfidenceScore },
                { "SubmittedAt", SubmittedAt },
                { "IsAnalyzed", IsAnalyzed },
                { "EmployeeId", EmployeeId },
                { "Department", Department }
            };
        }
    }

    public class TrainingFeedbackDto
    {
        [Required]
        public string TrainingId { get; set; }

        [Required]
        [StringLength(1000, MinimumLength = 10)]
        public string FeedbackText { get; set; }
    }

    public class SentimentAnalysisResult
    {
        public double SentimentScore { get; set; }
        public string SentimentLabel { get; set; }
        public double ConfidenceScore { get; set; }
    }
}
