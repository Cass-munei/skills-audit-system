using Microsoft.AspNetCore.Mvc;
using Google.Cloud.Firestore;
using SkillsAuditSystem.Models;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;

namespace SkillsAuditSystem.Controllers
{
    public class SkillsDemandController : Controller
    {
        private readonly FirestoreDb _firestoreDb;

        public SkillsDemandController(FirestoreDb firestoreDb)
        {
            _firestoreDb = firestoreDb;
        }

        // GET: /SkillsDemand
        public async Task<IActionResult> Index()
        {
            var userId = HttpContext.Session.GetString("userId");
            var department = HttpContext.Session.GetString("userDepartment") ?? "DefaultDepartment";

            // Fetch user details for profile name and photo
            string userName = "My Profile";
            string photoBase64 = "";
            string profilePhotoUrl = "";
            if (!string.IsNullOrEmpty(userId))
            {
                var userDoc = await _firestoreDb.Collection("users").Document(userId).GetSnapshotAsync();
                if (userDoc.Exists)
                {
                    var userData = userDoc.ToDictionary();
                    var firstName = userData.GetValueOrDefault("firstName", "") as string;
                    var lastName = userData.GetValueOrDefault("lastName", "") as string;
                    userName = $"{firstName} {lastName}".Trim();
                    if (string.IsNullOrWhiteSpace(userName))
                    {
                        userName = "My Profile";
                    }
                    photoBase64 = userData.GetValueOrDefault("photoBase64", "") as string;
                    profilePhotoUrl = userData.GetValueOrDefault("photoUrl", "") as string;

                    // Get department from user data if not in session
                    if (department == "DefaultDepartment")
                    {
                        department = userData.GetValueOrDefault("department", "DefaultDepartment") as string;
                    }
                }
            }

            // Load skills in demand from Firestore, filtered by department
            var skillsInDemand = await GetSkillsInDemandFromFirestore(department);

            // Load user's skills from Firestore
            var userSkills = new List<Skill>();
            if (!string.IsNullOrEmpty(userId))
            {
                var skillsRef = _firestoreDb.Collection("users").Document(userId).Collection("skills");
                var snapshot = await skillsRef.GetSnapshotAsync();
                foreach (var document in snapshot.Documents)
                {
                    var skill = document.ConvertTo<Skill>();
                    skill.Id = document.Id;
                    userSkills.Add(skill);
                }
            }

            ViewBag.SkillsInDemand = skillsInDemand;
            ViewBag.UserSkills = userSkills;
            ViewBag.UserName = userName;
            ViewBag.PhotoBase64 = photoBase64;
            ViewBag.ProfilePhotoUrl = profilePhotoUrl;

            return View();
        }

        private async Task<List<SkillDemand>> GetSkillsInDemandFromFirestore(string department)
        {
            var skillsInDemand = new List<SkillDemand>();

            try
            {
                var skillsRef = _firestoreDb.Collection("skillsDemand");
                var query = skillsRef.WhereEqualTo("department", department);
                var snapshot = await query.GetSnapshotAsync();

                foreach (var document in snapshot.Documents)
                {
                    var skillDemand = SkillDemand.FromMap(document.ToDictionary(), document.Id);
                    skillsInDemand.Add(skillDemand);
                }
            }
            catch (Exception ex)
            {
                // If Firestore query fails, fall back to mock data
                Console.WriteLine($"Error loading skills in demand from Firestore: {ex.Message}");
                skillsInDemand = GetMockSkillsInDemand(department);
            }

            return skillsInDemand;
        }

        private List<SkillDemand> GetMockSkillsInDemand(string department)
        {
            return new List<SkillDemand>
            {
                new SkillDemand("mock1", "Sample Skill 1", department, "Intermediate", 0.3, 15, 20) { Description = "Mock description 1" },
                new SkillDemand("mock2", "Sample Skill 2", department, "Advanced", 0.7, 5, 20) { Description = "Mock description 2" }
            };
        }

        // POST: /SkillsDemand/CreateSkill
        [HttpPost]
        public async Task<IActionResult> CreateSkill([FromForm] SkillCreateDto skillDto)
        {
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                return RedirectToAction("Index", "Login");
            }

            try
            {
                if (!ModelState.IsValid)
                {
                    TempData["Error"] = "Invalid skill data.";
                    return RedirectToAction("Index");
                }

                var skill = new Skill
                {
                    Name = skillDto.Name,
                    Category = skillDto.Category,
                    Proficiency = skillDto.Proficiency,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                var skillsRef = _firestoreDb.Collection("users").Document(userId).Collection("skills");
                var docRef = await skillsRef.AddAsync(skill);

                TempData["Success"] = "Skill added successfully.";
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                TempData["Error"] = $"Error saving skill: {ex.Message}";
                return RedirectToAction("Index");
            }
        }

        // POST: /SkillsDemand/UpdateSkill/{id}
        [HttpPost]
        public async Task<IActionResult> UpdateSkill(string id, [FromForm] SkillCreateDto skillDto)
        {
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                return RedirectToAction("Index", "Login");
            }

            try
            {
                if (!ModelState.IsValid)
                {
                    TempData["Error"] = "Invalid skill data.";
                    return RedirectToAction("Index");
                }

                var skillRef = _firestoreDb.Collection("users").Document(userId).Collection("skills").Document(id);
                var snapshot = await skillRef.GetSnapshotAsync();

                if (!snapshot.Exists)
                {
                    TempData["Error"] = "Skill not found.";
                    return RedirectToAction("Index");
                }

                var updatedSkill = new Skill
                {
                    Name = skillDto.Name,
                    Category = skillDto.Category,
                    Proficiency = skillDto.Proficiency,
                    CreatedAt = snapshot.ConvertTo<Skill>().CreatedAt,
                    UpdatedAt = DateTime.UtcNow
                };

                await skillRef.SetAsync(updatedSkill, SetOptions.Overwrite);

                TempData["Success"] = "Skill updated successfully.";
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                TempData["Error"] = $"Error updating skill: {ex.Message}";
                return RedirectToAction("Index");
            }
        }

        // POST: /SkillsDemand/DeleteSkill/{id}
        [HttpPost]
        public async Task<IActionResult> DeleteSkill(string id)
        {
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                return RedirectToAction("Index", "Login");
            }

            try
            {
                var skillRef = _firestoreDb.Collection("users").Document(userId).Collection("skills").Document(id);
                var snapshot = await skillRef.GetSnapshotAsync();

                if (!snapshot.Exists)
                {
                    TempData["Error"] = "Skill not found.";
                    return RedirectToAction("Index");
                }

                await skillRef.DeleteAsync();

                TempData["Success"] = "Skill deleted successfully.";
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                TempData["Error"] = $"Error deleting skill: {ex.Message}";
                return RedirectToAction("Index");
            }
        }
    }
}
