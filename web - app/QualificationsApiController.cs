/*using Microsoft.AspNetCore.Mvc;
using Google.Cloud.Firestore;
using SkillsAuditSystem.Models;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;

namespace SkillsAuditSystem.Controllers
{
    [ApiController]
    [Route("api/users/{userId}/qualifications")]
    [Authorize]
    public class QualificationsApiController : ControllerBase
    {
        private readonly FirestoreDb _firestoreDb;

        public QualificationsApiController(FirestoreDb firestoreDb)
        {
            _firestoreDb = firestoreDb;
        }

        // GET: api/users/{userId}/qualifications
        [HttpGet]
        public async Task<IActionResult> GetAllQualifications(string userId)
        {
            try
            {
                var qualificationsRef = _firestoreDb.Collection("users").Document(userId).Collection("qualifications");
                var snapshot = await qualificationsRef.GetSnapshotAsync();
                var qualifications = new List<Qualification>();

                foreach (var document in snapshot.Documents)
                {
                    var qualification = document.ConvertTo<Qualification>();
                    qualification.Id = document.Id;
                    qualifications.Add(qualification);
                }

                return Ok(qualifications);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // GET: api/users/{userId}/qualifications/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetQualification(string userId, string id)
        {
            try
            {
                var qualificationRef = _firestoreDb.Collection("users").Document(userId).Collection("qualifications").Document(id);
                var snapshot = await qualificationRef.GetSnapshotAsync();

                if (!snapshot.Exists)
                {
                    return NotFound($"Qualification with ID {id} not found.");
                }

                var qualification = snapshot.ConvertTo<Qualification>();
                qualification.Id = snapshot.Id;

                return Ok(qualification);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // POST: api/users/{userId}/qualifications
        [HttpPost]
        public async Task<IActionResult> CreateQualification(string userId, [FromBody] QualificationCreateDto qualificationDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var qualification = new Qualification
                {
                    Name = qualificationDto.Name,
                    Institution = qualificationDto.Institution,
                    Date = qualificationDto.Date,
                    CreatedAt = DateTime.UtcNow
                };

                var qualificationsRef = _firestoreDb.Collection("users").Document(userId).Collection("qualifications");
                var docRef = await qualificationsRef.AddAsync(qualification);

                // Retrieve the created document to return it
                var snapshot = await docRef.GetSnapshotAsync();
                var createdQualification = snapshot.ConvertTo<Qualification>();
                createdQualification.Id = snapshot.Id;

                return CreatedAtAction(nameof(GetQualification), new { userId, id = createdQualification.Id }, createdQualification);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // PUT: api/users/{userId}/qualifications/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateQualification(string userId, string id, [FromBody] QualificationCreateDto qualificationDto)
        {
            try
            {
                if (qualificationDto == null)
                {
                    return BadRequest("Qualification data is required.");
                }

                var qualificationRef = _firestoreDb.Collection("users").Document(userId).Collection("qualifications").Document(id);
                var snapshot = await qualificationRef.GetSnapshotAsync();

                if (!snapshot.Exists)
                {
                    return NotFound($"Qualification with ID {id} not found.");
                }

                var qualification = new Qualification
                {
                    Id = id,
                    Name = qualificationDto.Name,
                    Institution = qualificationDto.Institution,
                    Date = qualificationDto.Date,
                    CreatedAt = snapshot.ConvertTo<Qualification>().CreatedAt
                };

                await qualificationRef.SetAsync(qualification, SetOptions.Overwrite);

                return Ok(qualification);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // DELETE: api/users/{userId}/qualifications/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteQualification(string userId, string id)
        {
            try
            {
                var qualificationRef = _firestoreDb.Collection("users").Document(userId).Collection("qualifications").Document(id);
                var snapshot = await qualificationRef.GetSnapshotAsync();

                if (!snapshot.Exists)
                {
                    return NotFound($"Qualification with ID {id} not found.");
                }

                await qualificationRef.DeleteAsync();

                return NoContent();
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
    }
}
*/
