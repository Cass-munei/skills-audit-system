using Microsoft.AspNetCore.Mvc;
using Google.Cloud.Firestore;
using SkillsAuditSystem.Models;
using System.Collections.Generic;
using System.Threading.Tasks;
using Google.Cloud.Storage.V1;
using System.IO;
using System.Net.Http;
using System;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Authorization;

namespace SkillsAuditSystem.Controllers
{
    [ApiController]
    [Route("api/users/{userId}/documents")]
    public class DocumentsApiController : ControllerBase
    {
        private readonly FirestoreDb _firestoreDb;
        private readonly string _firebaseStorageBucket = "skills-audit-system-a5ba3.firebasestorage.app";
        private readonly ILogger<DocumentsApiController> _logger;
        private readonly StorageClient _storageClient;

        public DocumentsApiController(FirestoreDb firestoreDb, ILogger<DocumentsApiController> logger, StorageClient storageClient)
        {
            _firestoreDb = firestoreDb;
            _logger = logger;
            _storageClient = storageClient;
        }

        // GET: api/users/{userId}/documents
        [HttpGet]
        public async Task<IActionResult> GetAllDocuments(string userId)
        {
            try
            {
                var documentsRef = _firestoreDb.Collection("users").Document(userId).Collection("documents");
                var snapshot = await documentsRef.GetSnapshotAsync();
                var documents = new List<Document>();

                foreach (var document in snapshot.Documents)
                {
                    var doc = document.ConvertTo<Document>();
                    doc.Id = document.Id;
                    documents.Add(doc);
                }

                return Ok(documents);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // GET: api/users/{userId}/documents/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetDocument(string userId, string id)
        {
            try
            {
                var documentRef = _firestoreDb.Collection("users").Document(userId).Collection("documents").Document(id);
                var snapshot = await documentRef.GetSnapshotAsync();

                if (!snapshot.Exists)
                {
                    return NotFound($"Document with ID {id} not found.");
                }

                var document = snapshot.ConvertTo<Document>();
                document.Id = snapshot.Id;

                return Ok(document);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // POST: api/users/{userId}/documents
        [HttpPost]
        public async Task<IActionResult> CreateDocument(string userId, [FromForm] DocumentCreateDto documentDto)
        {
            _logger.LogInformation("Starting document upload for user {UserId}, document name: {DocumentName}", userId, documentDto.Name);

            try
            {
                if (!ModelState.IsValid)
                {
                    _logger.LogWarning("Model validation failed for document upload: {ModelState}", ModelState);
                    return BadRequest(ModelState);
                }

                if (documentDto.File == null || documentDto.File.Length == 0)
                {
                    return BadRequest("No file uploaded");
                }

                // Generate a unique file name
                var fileName = $"{DateTime.Now.Ticks}_{documentDto.File.FileName}";
                var uploadsPath = Path.Combine("wwwroot", "uploads");
                var filePath = Path.Combine(uploadsPath, fileName);

                // Ensure uploads directory exists
                Directory.CreateDirectory(uploadsPath);

                // Save file to server
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await documentDto.File.CopyToAsync(stream);
                }

                // Generate relative URL
                var relativeUrl = $"/uploads/{fileName}";
                _logger.LogInformation("Successfully saved file to server, relative URL: {RelativeUrl}", relativeUrl);

                var document = new Document
                {
                    Name = documentDto.Name,
                    Type = documentDto.Type,
                    Url = relativeUrl,
                    FileName = documentDto.File.FileName,
                    Status = "Awaiting Review",
                    UploadedAt = DateTime.UtcNow
                };

                // Save to Firestore
                try
                {
                    var documentsRef = _firestoreDb.Collection("users").Document(userId).Collection("documents");
                    var docRef = await documentsRef.AddAsync(document);
                    _logger.LogInformation("Successfully saved document metadata to Firestore, document ID: {DocumentId}", docRef.Id);

                    // Retrieve the created document to return it
                    var snapshot = await docRef.GetSnapshotAsync();
                    var createdDocument = snapshot.ConvertTo<Document>();
                    createdDocument.Id = snapshot.Id;

                    _logger.LogInformation("Document upload completed successfully for user {UserId}", userId);
                    return CreatedAtAction(nameof(GetDocument), new { userId, id = createdDocument.Id }, createdDocument);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to save document metadata to Firestore");
                    // If Firestore save fails, delete the uploaded file
                    if (System.IO.File.Exists(filePath))
                    {
                        System.IO.File.Delete(filePath);
                    }
                    throw;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error during document upload for user {UserId}: {Message}. Stack trace: {StackTrace}", userId, ex.Message, ex.StackTrace);
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // PUT: api/users/{userId}/documents/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateDocument(string userId, string id, [FromBody] Document document)
        {
            try
            {
                if (document == null)
                {
                    return BadRequest("Document data is required.");
                }

                var documentRef = _firestoreDb.Collection("users").Document(userId).Collection("documents").Document(id);
                var snapshot = await documentRef.GetSnapshotAsync();

                if (!snapshot.Exists)
                {
                    return NotFound($"Document with ID {id} not found.");
                }

                await documentRef.SetAsync(document, SetOptions.Overwrite);

                document.Id = id;
                return Ok(document);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // DELETE: api/users/{userId}/documents/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteDocument(string userId, string id)
        {
            try
            {
                var documentRef = _firestoreDb.Collection("users").Document(userId).Collection("documents").Document(id);
                var snapshot = await documentRef.GetSnapshotAsync();

                if (!snapshot.Exists)
                {
                    return NotFound($"Document with ID {id} not found.");
                }

                var document = snapshot.ConvertTo<Document>();

                // Delete from server if URL is from server uploads
                if (document.Url.StartsWith("/uploads/"))
                {
                    var filePath = Path.Combine("wwwroot", document.Url.TrimStart('/'));
                    if (System.IO.File.Exists(filePath))
                    {
                        System.IO.File.Delete(filePath);
                    }
                }
                // Delete from Firebase Storage if URL is from Firebase Storage
                else if (document.Url.Contains("storage.googleapis.com"))
                {
                    // Extract object name from URL
                    var urlParts = document.Url.Split('/');
                    var objectName = string.Join('/', urlParts.Skip(4)); // Skip https://storage.googleapis.com/bucket/
                    await _storageClient.DeleteObjectAsync(_firebaseStorageBucket, objectName);
                }

                // Delete from Firestore
                await documentRef.DeleteAsync();

                return NoContent();
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
    }
}
