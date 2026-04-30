using Google.Cloud.Firestore;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace SkillsAuditSystem.Models
{
    [FirestoreData]
    public class Qualification
    {
        [JsonIgnore]
        [FirestoreProperty]
        public string? Id { get; set; }

        [Required]
        [JsonPropertyName("name")]
        [FirestoreProperty("name")]
        public string Name { get; set; }

        [Required]
        [JsonPropertyName("institution")]
        [FirestoreProperty("institution")]
        public string Institution { get; set; }

        [Required]
        [JsonPropertyName("date")]
        [FirestoreProperty("date")]
        public string Date { get; set; } // e.g., "2023"

        [JsonPropertyName("createdAt")]
        [FirestoreProperty("createdAt")]
        public DateTime CreatedAt { get; set; }

        public Qualification()
        {
            Name = string.Empty;
            Institution = string.Empty;
            Date = string.Empty;
        }

        public Qualification(string id, string name, string institution, string date)
        {
            Id = id;
            Name = name;
            Institution = institution;
            Date = date;
        }

        public static Qualification FromMap(Dictionary<string, object> data, string id)
        {
            if (data == null) return null;

            string GetString(string key)
                => data.TryGetValue(key, out var value) && value is string str ? str : null;

            return new Qualification(
                id: id,
                name: GetString("name") ?? "",
                institution: GetString("institution") ?? "",
                date: GetString("date") ?? ""
            );
        }

        public Dictionary<string, object> ToMap()
        {
            return new Dictionary<string, object>
            {
                { "name", Name },
                { "institution", Institution },
                { "date", Date }
            };
        }
    }

    public class QualificationCreateDto
    {
        [Required]
        public string Name { get; set; }

        [Required]
        public string Institution { get; set; }

        [Required]
        public string Date { get; set; }
    }
}
