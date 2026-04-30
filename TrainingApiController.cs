//using Microsoft.AspNetCore.Mvc;
//using Google.Cloud.Firestore;
// SkillsAuditSystem.Models;
//using System.Collections.Generic;
/*using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;

namespace SkillsAuditSystem.Controllers
{
    [ApiController]
    [Route("api/users/{userId}/trainings")]
    [Authorize]
    public class TrainingApiController : ControllerBase
    {
        private readonly FirestoreDb _firestoreDb;

        public TrainingApiController(FirestoreDb firestoreDb)
        {
            _firestoreDb = firestoreDb;
        }

        // GET: api/users/{userId}/trainings
        [HttpGet]
        public async Task<IActionResult> GetAllTrainings(string userId)
        {
            try
            {
                var trainingsRef = _firestoreDb.Collection("users").Document(userId).Collection("trainings");
                var snapshot = await trainingsRef.GetSnapshotAsync();
                var trainings = new List<Training>();

                foreach (var document in snapshot.Documents)
                {
                    var training = document.ConvertTo<Training>();
                    training.Id = document.Id;
                    trainings.Add(training);
                }

                return Ok(trainings);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // GET: api/users/{userId}/trainings/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetTraining(string userId, string id)
        {
            try
            {
                var trainingRef = _firestoreDb.Collection("users").Document(userId).Collection("trainings").Document(id);
                var snapshot = await trainingRef.GetSnapshotAsync();

                if (!snapshot.Exists)
                {
                    return NotFound($"Training with ID {id} not found.");
                }

                var training = snapshot.ConvertTo<Training>();
                training.Id = snapshot.Id;

                return Ok(training);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // POST: api/users/{userId}/trainings
        [HttpPost]
        public async Task<IActionResult> CreateTraining(string userId, [FromBody] TrainingCreateDto trainingDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var training = new Training
                {
                    TrainingName = trainingDto.TrainingName,
                    Provider = trainingDto.Provider,
                    StartDate = trainingDto.StartDate,
                    EndDate = trainingDto.EndDate,
                    CreatedAt = DateTime.UtcNow
                };

                var trainingsRef = _firestoreDb.Collection("users").Document(userId).Collection("trainings");
                var docRef = await trainingsRef.AddAsync(training);

                // Retrieve the created document to return it
                var snapshot = await docRef.GetSnapshotAsync();
                var createdTraining = snapshot.ConvertTo<Training>();
                createdTraining.Id = snapshot.Id;

                return CreatedAtAction(nameof(GetTraining), new { userId, id = createdTraining.Id }, createdTraining);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // PUT: api/users/{userId}/trainings/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateTraining(string userId, string id, [FromBody] TrainingCreateDto trainingDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var trainingRef = _firestoreDb.Collection("users").Document(userId).Collection("trainings").Document(id);
                var snapshot = await trainingRef.GetSnapshotAsync();

                if (!snapshot.Exists)
                {
                    return NotFound($"Training with ID {id} not found.");
                }

                var training = new Training
                {
                    TrainingName = trainingDto.TrainingName,
                    Provider = trainingDto.Provider,
                    StartDate = trainingDto.StartDate,
                    EndDate = trainingDto.EndDate,
                    CreatedAt = DateTime.UtcNow
                };

                await trainingRef.SetAsync(training, SetOptions.Overwrite);

                training.Id = id;
                return Ok(training);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // DELETE: api/users/{userId}/trainings/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteTraining(string userId, string id)
        {
            try
            {
                var trainingRef = _firestoreDb.Collection("users").Document(userId).Collection("trainings").Document(id);
                var snapshot = await trainingRef.GetSnapshotAsync();

                if (!snapshot.Exists)
                {
                    return NotFound($"Training with ID {id} not found.");
                }

                await trainingRef.DeleteAsync();

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
