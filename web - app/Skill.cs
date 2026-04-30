using Google.Cloud.Firestore;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace SkillsAuditSystem.Models
{
    [FirestoreData]
    public class Skill
    {
        [JsonIgnore]
        [FirestoreProperty]
        public string? Id { get; set; }

        [Required]
        [FirestoreProperty("name")]
        public string Name { get; set; }

        [Required]
        [FirestoreProperty("category")]
        public string Category { get; set; }

        [Required]
        [FirestoreProperty("proficiency")]
        public string Proficiency { get; set; } // e.g., Beginner, Intermediate, Advanced, Expert

        [FirestoreProperty("createdAt")]
        public DateTime CreatedAt { get; set; }

        [FirestoreProperty("updatedAt")]
        public DateTime UpdatedAt { get; set; }

        public Skill()
        {
            Name = string.Empty;
            Category = string.Empty;
            Proficiency = string.Empty;
        }

        public Skill(string id, string name, string category, string proficiency)
        {
            Id = id;
            Name = name;
            Category = category;
            Proficiency = proficiency;
        }

        public static Skill FromMap(Dictionary<string, object> data, string id)
        {
            if (data == null) return null;

            string GetString(string key)
                => data.TryGetValue(key, out var value) && value is string str ? str : null;

            return new Skill(
                id: id,
                name: GetString("name") ?? "",
                category: GetString("category") ?? "",
                proficiency: GetString("proficiency") ?? ""
            );
        }

        public Dictionary<string, object> ToMap()
        {
            return new Dictionary<string, object>
            {
                { "name", Name },
                { "category", Category },
                { "proficiency", Proficiency }
            };
        }
    }

    public class SkillCreateDto
    {
        [Required]
        public string Name { get; set; }

        [Required]
        public string Category { get; set; }

        [Required]
        public string Proficiency { get; set; } // e.g., Beginner, Intermediate, Advanced, Expert
    }
}
