using Microsoft.AspNetCore.Mvc;
using Google.Cloud.Firestore;
using SkillsAuditSystem.Models;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;

namespace SkillsAuditSystem.Controllers
{
    public class TrainingController : Controller
    {
        private readonly FirestoreDb _firestoreDb;

        public TrainingController(FirestoreDb firestoreDb)
        {
            _firestoreDb = firestoreDb;
        }

        // GET: /Training/Index
        public async Task<IActionResult> Index()
        {
            var userId = HttpContext.Session.GetString("userId");

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
                }
            }

            // Load user's trainings from Firestore
            var trainings = new List<Training>();
            if (!string.IsNullOrEmpty(userId))
            {
                var trainingsRef = _firestoreDb.Collection("users").Document(userId).Collection("trainings");
                var snapshot = await trainingsRef.GetSnapshotAsync();
                foreach (var document in snapshot.Documents)
                {
                    var training = document.ConvertTo<Training>();
                    training.Id = document.Id;
                    trainings.Add(training);
                }
            }

            ViewBag.Trainings = trainings;
            ViewBag.UserName = userName;
            ViewBag.PhotoBase64 = photoBase64;
            ViewBag.ProfilePhotoUrl = profilePhotoUrl;

            return View();
        }

        // POST: /Training/CreateTraining
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CreateTraining(TrainingCreateDto model)
        {
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                TempData["Error"] = "User not authenticated.";
                return RedirectToAction("Index");
            }

            if (!ModelState.IsValid)
            {
                TempData["Error"] = "Please fill in all required fields.";
                return RedirectToAction("Index");
            }

            try
            {
                var training = new Training
                {
                    TrainingName = model.TrainingName,
                    Provider = model.Provider,
                    StartDate = model.StartDate,
                    EndDate = model.EndDate,
                    CreatedAt = DateTime.UtcNow
                };

                var trainingsRef = _firestoreDb.Collection("users").Document(userId).Collection("trainings");
                await trainingsRef.AddAsync(training.ToMap());

                TempData["Success"] = "Training added successfully.";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error adding training: " + ex.Message;
            }

            return RedirectToAction("Index");
        }

        // POST: /Training/UpdateTraining/{id}
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateTraining(string id, TrainingCreateDto model)
        {
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                TempData["Error"] = "User not authenticated.";
                return RedirectToAction("Index");
            }

            if (!ModelState.IsValid)
            {
                TempData["Error"] = "Please fill in all required fields.";
                return RedirectToAction("Index");
            }

            try
            {
                var trainingRef = _firestoreDb.Collection("users").Document(userId).Collection("trainings").Document(id);
                var trainingDoc = await trainingRef.GetSnapshotAsync();

                if (!trainingDoc.Exists)
                {
                    TempData["Error"] = "Training not found.";
                    return RedirectToAction("Index");
                }

                var updateData = new Dictionary<string, object>
                {
                    { "TrainingName", model.TrainingName },
                    { "Provider", model.Provider },
                    { "StartDate", model.StartDate },
                    { "EndDate", model.EndDate }
                };

                await trainingRef.UpdateAsync(updateData);
                TempData["Success"] = "Training updated successfully.";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error updating training: " + ex.Message;
            }

            return RedirectToAction("Index");
        }

        // POST: /Training/DeleteTraining/{id}
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteTraining(string id)
        {
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                TempData["Error"] = "User not authenticated.";
                return RedirectToAction("Index");
            }

            try
            {
                var trainingRef = _firestoreDb.Collection("users").Document(userId).Collection("trainings").Document(id);
                await trainingRef.DeleteAsync();
                TempData["Success"] = "Training deleted successfully.";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error deleting training: " + ex.Message;
            }

            return RedirectToAction("Index");
        }
    }
}
