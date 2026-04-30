using Google.Cloud.Firestore;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace SkillsAuditSystem.Models
{
    [FirestoreData]
    public class Document
    {
        [FirestoreProperty]
        public string? Id { get; set; }

        [Required]
        [FirestoreProperty("name")]
        public string Name { get; set; }

        [Required]
        [FirestoreProperty("type")]
        public string Type { get; set; }

        [Required]
        [FirestoreProperty("url")]
        public string Url { get; set; }

        [FirestoreProperty("fileName")]
        public string FileName { get; set; }

        [FirestoreProperty("status")]
        public string Status { get; set; }

        [FirestoreProperty("uploadedAt")]
        public DateTime UploadedAt { get; set; }

        public Document()
        {
            Name = string.Empty;
            Type = string.Empty;
            Url = string.Empty;
            FileName = string.Empty;
            Status = string.Empty;
        }

        public Document(string id, string name, string type, string url, string fileName, string status, DateTime uploadedAt)
        {
            Id = id;
            Name = name;
            Type = type;
            Url = url;
            FileName = fileName;
            Status = status;
            UploadedAt = uploadedAt;
        }

        public static Document FromMap(Dictionary<string, object> data, string id)
        {
            return new Document(
                id: id,
                name: data.ContainsKey("name") ? (string)data["name"] : "",
                type: data.ContainsKey("type") ? (string)data["type"] : "",
                url: data.ContainsKey("url") ? (string)data["url"] : "",
                fileName: data.ContainsKey("fileName") ? (string)data["fileName"] : "",
                status: data.ContainsKey("status") ? (string)data["status"] : "",
                uploadedAt: data.ContainsKey("uploadedAt") ? ((Timestamp)data["uploadedAt"]).ToDateTime() : DateTime.UtcNow
            );
        }

        public Dictionary<string, object> ToMap()
        {
            return new Dictionary<string, object>
            {
                { "name", Name },
                { "type", Type },
                { "url", Url },
                { "fileName", FileName },
                { "status", Status },
                { "uploadedAt", Timestamp.FromDateTime(UploadedAt.ToUniversalTime()) }
            };
        }
    }

    public class DocumentCreateDto
    {
        [Required]
        public string Name { get; set; }

        [Required]
        public string Type { get; set; }

        [Required]
        public IFormFile File { get; set; }
    }
}
