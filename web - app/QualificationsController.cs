using Microsoft.AspNetCore.Mvc;
using Google.Cloud.Firestore;
using SkillsAuditSystem.Models;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;

namespace SkillsAuditSystem.Controllers
{
    public class QualificationsController : Controller
    {
        private readonly FirestoreDb _firestoreDb;

        public QualificationsController(FirestoreDb firestoreDb)
        {
            _firestoreDb = firestoreDb;
        }

        // GET: /Qualifications/Index
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

            // Load user's qualifications from Firestore
            var qualifications = new List<Qualification>();
            if (!string.IsNullOrEmpty(userId))
            {
                var qualificationsRef = _firestoreDb.Collection("users").Document(userId).Collection("qualifications");
                var snapshot = await qualificationsRef.GetSnapshotAsync();
                foreach (var document in snapshot.Documents)
                {
                    var qualification = document.ConvertTo<Qualification>();
                    qualification.Id = document.Id;
                    qualifications.Add(qualification);
                }
            }

            ViewBag.Qualifications = qualifications;
            ViewBag.UserName = userName;
            ViewBag.PhotoBase64 = photoBase64;
            ViewBag.ProfilePhotoUrl = profilePhotoUrl;

            return View();
        }

        // POST: /Qualifications/CreateQualification
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CreateQualification(QualificationCreateDto model)
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
                var qualification = new Qualification
                {
                    Name = model.Name,
                    Institution = model.Institution,
                    Date = model.Date,
                    CreatedAt = DateTime.UtcNow
                };

                var qualificationsRef = _firestoreDb.Collection("users").Document(userId).Collection("qualifications");
                await qualificationsRef.AddAsync(qualification.ToMap());

                TempData["Success"] = "Qualification added successfully.";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error adding qualification: " + ex.Message;
            }

            return RedirectToAction("Index");
        }

        // POST: /Qualifications/UpdateQualification/{id}
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateQualification(string id, QualificationCreateDto model)
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
                var qualificationRef = _firestoreDb.Collection("users").Document(userId).Collection("qualifications").Document(id);
                var qualificationDoc = await qualificationRef.GetSnapshotAsync();

                if (!qualificationDoc.Exists)
                {
                    TempData["Error"] = "Qualification not found.";
                    return RedirectToAction("Index");
                }

                var updateData = new Dictionary<string, object>
                {
                    { "name", model.Name },
                    { "institution", model.Institution },
                    { "date", model.Date }
                };

                await qualificationRef.UpdateAsync(updateData);
                TempData["Success"] = "Qualification updated successfully.";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error updating qualification: " + ex.Message;
            }

            return RedirectToAction("Index");
        }

        // POST: /Qualifications/DeleteQualification/{id}
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteQualification(string id)
        {
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                TempData["Error"] = "User not authenticated.";
                return RedirectToAction("Index");
            }

            try
            {
                var qualificationRef = _firestoreDb.Collection("users").Document(userId).Collection("qualifications").Document(id);
                await qualificationRef.DeleteAsync();
                TempData["Success"] = "Qualification deleted successfully.";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error deleting qualification: " + ex.Message;
            }

            return RedirectToAction("Index");
        }
    }
}
