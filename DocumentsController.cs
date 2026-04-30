using Microsoft.AspNetCore.Mvc;
using Google.Cloud.Firestore;
using SkillsAuditSystem.Models;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Google.Cloud.Storage.V1;
using System.IO;
using System.Linq;
using System;

namespace SkillsAuditSystem.Controllers
{
    public class DocumentsController : Controller
    {
        private readonly FirestoreDb _firestoreDb;
        private readonly StorageClient _storageClient;

        public DocumentsController(FirestoreDb firestoreDb, StorageClient storageClient)
        {
            _firestoreDb = firestoreDb;
            _storageClient = storageClient;
        }

        // GET: /Documents/Index
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

            // Load user's documents from Firestore
            var documents = new List<Document>();
            if (!string.IsNullOrEmpty(userId))
            {
                var documentsRef = _firestoreDb.Collection("users").Document(userId).Collection("documents");
                var snapshot = await documentsRef.GetSnapshotAsync();
                foreach (var document in snapshot.Documents)
                {
                    var doc = document.ConvertTo<Document>();
                    doc.Id = document.Id;
                    documents.Add(doc);
                }
            }

            ViewBag.Documents = documents;
            ViewBag.UserName = userName;
            ViewBag.PhotoBase64 = photoBase64;
            ViewBag.ProfilePhotoUrl = profilePhotoUrl;

            return View();
        }

        // POST: /Documents/CreateDocument
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CreateDocument(DocumentCreateDto model)
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
                string fileUrl = "";
                string fileName = model.File.FileName;

                // Upload file to Google Cloud Storage
                var bucketName = "skills-audit-system.appspot.com"; // Replace with your bucket name
                using (var stream = model.File.OpenReadStream())
                {
                    var objectName = $"{userId}/documents/{fileName}";
                    await _storageClient.UploadObjectAsync(bucketName, objectName, null, stream);
                    fileUrl = $"https://storage.googleapis.com/{bucketName}/{objectName}";
                }

                var document = new Document
                {
                    Name = model.Name,
                    Type = model.Type,
                    Url = fileUrl,
                    FileName = fileName,
                    Status = "Awaiting Review",
                    UploadedAt = DateTime.UtcNow
                };

                var documentsRef = _firestoreDb.Collection("users").Document(userId).Collection("documents");
                await documentsRef.AddAsync(document.ToMap());

                TempData["Success"] = "Document uploaded successfully.";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error uploading document: " + ex.Message;
            }

            return RedirectToAction("Index");
        }

        // POST: /Documents/UpdateDocument/{id}
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateDocument(string id, DocumentCreateDto model)
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
                var documentRef = _firestoreDb.Collection("users").Document(userId).Collection("documents").Document(id);
                var documentDoc = await documentRef.GetSnapshotAsync();

                if (!documentDoc.Exists)
                {
                    TempData["Error"] = "Document not found.";
                    return RedirectToAction("Index");
                }

                string fileUrl = "";
                string fileName = model.File.FileName;

                // Upload new file to Google Cloud Storage
                var bucketName = "skills-audit-system.appspot.com"; // Replace with your bucket name
                using (var stream = model.File.OpenReadStream())
                {
                    var objectName = $"{userId}/documents/{fileName}";
                    await _storageClient.UploadObjectAsync(bucketName, objectName, null, stream);
                    fileUrl = $"https://storage.googleapis.com/{bucketName}/{objectName}";
                }

                var updateData = new Dictionary<string, object>
                {
                    { "name", model.Name },
                    { "type", model.Type },
                    { "url", fileUrl },
                    { "fileName", fileName }
                };

                await documentRef.UpdateAsync(updateData);
                TempData["Success"] = "Document updated successfully.";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error updating document: " + ex.Message;
            }

            return RedirectToAction("Index");
        }

        // POST: /Documents/DeleteDocument/{id}
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteDocument(string id)
        {
            var userId = HttpContext.Session.GetString("userId");
            if (string.IsNullOrEmpty(userId))
            {
                TempData["Error"] = "User not authenticated.";
                return RedirectToAction("Index");
            }

            try
            {
                var documentRef = _firestoreDb.Collection("users").Document(userId).Collection("documents").Document(id);
                var documentDoc = await documentRef.GetSnapshotAsync();

                if (documentDoc.Exists)
                {
                    var document = documentDoc.ConvertTo<Document>();

                    // Delete file from Google Cloud Storage
                    var bucketName = "skills-audit-system.appspot.com"; // Replace with your bucket name
                    var objectName = $"{userId}/documents/{document.FileName}";
                    await _storageClient.DeleteObjectAsync(bucketName, objectName);
                }

                await documentRef.DeleteAsync();
                TempData["Success"] = "Document deleted successfully.";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error deleting document: " + ex.Message;
            }

            return RedirectToAction("Index");
        }
    }
}
