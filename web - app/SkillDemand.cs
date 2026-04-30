using Google.Cloud.Firestore;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace SkillsAuditSystem.Models
{
    [FirestoreData]
    public class SkillDemand
    {
        [JsonIgnore]
        [FirestoreProperty]
        public string? Id { get; set; }

        [Required]
        [FirestoreProperty("name")]
        public string Name { get; set; }

        [Required]
        [FirestoreProperty("department")]
        public string Department { get; set; }



        [Required]
        [FirestoreProperty("requiredLevel")]
        public string RequiredLevel { get; set; } // e.g., Beginner, Intermediate, Advanced, Expert

        [Required]
        [FirestoreProperty("gapPercentage")]
        public double GapPercentage { get; set; } // 0.0 to 1.0

        public double DemandLevel => 1 - GapPercentage; // Computed property: higher demand when gap is lower

        [Required]
        [FirestoreProperty("employeesMatching")]
        public int EmployeesMatching { get; set; }

        [Required]
        [FirestoreProperty("totalEmployees")]
        public int TotalEmployees { get; set; }

        [FirestoreProperty("description")]
        public string Description { get; set; }

        public SkillDemand()
        {
            Name = string.Empty;
            Department = string.Empty;
            RequiredLevel = string.Empty;
            Description = string.Empty;
        }

        public SkillDemand(string id, string name, string department, string requiredLevel, double gapPercentage, int employeesMatching, int totalEmployees)
        {
            Id = id;
            Name = name;
            Department = department;
            RequiredLevel = requiredLevel;
            GapPercentage = gapPercentage;
            EmployeesMatching = employeesMatching;
            TotalEmployees = totalEmployees;
        }

        public static SkillDemand FromMap(Dictionary<string, object> data, string id)
        {
            var skillDemand = new SkillDemand(
                id: id,
                name: data.ContainsKey("name") ? (string)data["name"] : "",
                department: data.ContainsKey("department") ? (string)data["department"] : "",
                requiredLevel: data.ContainsKey("requiredLevel") ? (string)data["requiredLevel"] : "Intermediate",
                gapPercentage: data.ContainsKey("gapPercentage") ? Convert.ToDouble(data["gapPercentage"]) : 0.0,
                employeesMatching: data.ContainsKey("employeesMatching") ? Convert.ToInt32(data["employeesMatching"]) : 0,
                totalEmployees: data.ContainsKey("totalEmployees") ? Convert.ToInt32(data["totalEmployees"]) : 0);
            skillDemand.Description = data.ContainsKey("description") ? (string)data["description"] : "";
            return skillDemand;
        }

        public Dictionary<string, object> ToMap()
        {
            return new Dictionary<string, object>
            {
                { "name", Name },
                { "department", Department },
                { "requiredLevel", RequiredLevel },
                { "gapPercentage", GapPercentage },
                { "employeesMatching", EmployeesMatching },
                { "totalEmployees", TotalEmployees },
                { "description", Description }
            };
        }
    }
}
