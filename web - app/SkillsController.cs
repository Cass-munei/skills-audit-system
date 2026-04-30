using Microsoft.AspNetCore.Mvc;
using Google.Cloud.Firestore;
using SkillsAuditSystem.Models;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;

namespace SkillsAuditSystem.Controllers
{
    [ApiController]
    [Route("api/users/{userId}/[controller]")]
    [Authorize]
    public class SkillsController : ControllerBase
    {
        private readonly FirestoreDb _firestoreDb;

        public SkillsController(FirestoreDb firestoreDb)
        {
            _firestoreDb = firestoreDb;
        }

        // GET: api/users/{userId}/skills
        [HttpGet]
        public async Task<IActionResult> GetAllSkills(string userId)
        {
            try
            {
                var skillsRef = _firestoreDb.Collection("users").Document(userId).Collection("skills");
                var snapshot = await skillsRef.GetSnapshotAsync();
                var skills = new List<Skill>();

                foreach (var document in snapshot.Documents)
                {
                    var skill = document.ConvertTo<Skill>();
                    skill.Id = document.Id;
                    skills.Add(skill);
                }

                return Ok(skills);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // GET: api/users/{userId}/skills/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetSkill(string userId, string id)
        {
            try
            {
                var skillRef = _firestoreDb.Collection("users").Document(userId).Collection("skills").Document(id);
                var snapshot = await skillRef.GetSnapshotAsync();

                if (!snapshot.Exists)
                {
                    return NotFound($"Skill with ID {id} not found.");
                }

                var skill = snapshot.ConvertTo<Skill>();
                skill.Id = snapshot.Id;

                return Ok(skill);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // POST: api/users/{userId}/skills
        [HttpPost]
        public async Task<IActionResult> CreateSkill(string userId, [FromBody] SkillCreateDto skillDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
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

                // Retrieve the created document to return it
                var snapshot = await docRef.GetSnapshotAsync();
                var createdSkill = snapshot.ConvertTo<Skill>();
                createdSkill.Id = snapshot.Id;

                return CreatedAtAction(nameof(GetSkill), new { userId, id = createdSkill.Id }, createdSkill);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // PUT: api/users/{userId}/skills/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateSkill(string userId, string id, [FromBody] SkillCreateDto skillDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var skillRef = _firestoreDb.Collection("users").Document(userId).Collection("skills").Document(id);
                var snapshot = await skillRef.GetSnapshotAsync();

                if (!snapshot.Exists)
                {
                    return NotFound($"Skill with ID {id} not found.");
                }

                var updatedSkill = new Skill
                {
                    Name = skillDto.Name,
                    Category = skillDto.Category,
                    Proficiency = skillDto.Proficiency,
                    CreatedAt = snapshot.ConvertTo<Skill>().CreatedAt, // Preserve original CreatedAt
                    UpdatedAt = DateTime.UtcNow
                };

                await skillRef.SetAsync(updatedSkill, SetOptions.Overwrite);

                updatedSkill.Id = id;
                return Ok(updatedSkill);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // DELETE: api/users/{userId}/skills/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteSkill(string userId, string id)
        {
            try
            {
                var skillRef = _firestoreDb.Collection("users").Document(userId).Collection("skills").Document(id);
                var snapshot = await skillRef.GetSnapshotAsync();

                if (!snapshot.Exists)
                {
                    return NotFound($"Skill with ID {id} not found.");
                }

                await skillRef.DeleteAsync();

                return NoContent();
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
    }
}
