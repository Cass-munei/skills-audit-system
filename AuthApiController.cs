using Microsoft.AspNetCore.Mvc;
using FirebaseAdmin.Auth;
using Google.Cloud.Firestore;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using System;
using SkillsAuditSystem.Services;

namespace SkillsAuditSystem.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthApiController : ControllerBase
    {
        private readonly FirestoreDb _firestore;
        private readonly JwtService _jwtService;

        public AuthApiController(FirestoreDb firestore, JwtService jwtService)
        {
            _firestore = firestore;
            _jwtService = jwtService;
        }

        [HttpPost("loginByEmployeeId")]
        public async Task<IActionResult> LoginByEmployeeId([FromBody] LoginByEmployeeIdRequest request)
        {
            try
            {
                // Validate Employee ID format
                if (string.IsNullOrEmpty(request.EmployeeId))
                {
                    return BadRequest(new { error = "Please enter Employee ID" });
                }

                if (request.EmployeeId.Length != 10)
                {
                    return BadRequest(new { error = "Employee ID must be 10 characters" });
                }

                if (!request.EmployeeId.StartsWith("EMP-00"))
                {
                    return BadRequest(new { error = "Employee ID must start with EMP-00" });
                }

                string lastFour = request.EmployeeId.Substring(6);
                if (!Regex.IsMatch(lastFour, @"^\d{4}$"))
                {
                    return BadRequest(new { error = "Last four characters must be digits" });
                }

                if (string.IsNullOrEmpty(request.Password))
                {
                    return BadRequest(new { error = "Please enter password" });
                }

                // First, check the employee_ids collection to get the Firebase user ID
                DocumentReference employeeDoc = _firestore.Collection("employee_ids").Document(request.EmployeeId);
                DocumentSnapshot employeeSnapshot = await employeeDoc.GetSnapshotAsync();

                if (!employeeSnapshot.Exists)
                {
                    return BadRequest(new { error = "Invalid Employee ID or Password" });
                }

                var employeeData = employeeSnapshot.ToDictionary();
                string firebaseUserId = employeeData.GetValueOrDefault("uid", "").ToString();

                if (string.IsNullOrEmpty(firebaseUserId))
                {
                    return BadRequest(new { error = "User account not properly configured" });
                }

                // Now fetch user data from the users collection using the Firebase user ID
                DocumentReference userDoc = _firestore.Collection("users").Document(firebaseUserId);
                DocumentSnapshot userSnapshot = await userDoc.GetSnapshotAsync();

                if (!userSnapshot.Exists)
                {
                    return BadRequest(new { error = "Invalid Employee ID or Password" });
                }

                var userData = userSnapshot.ToDictionary();

                // Verify with Firebase Auth - check password
                try
                {
                    // For Firebase Auth, we need to verify the user exists and is valid
                    // Since we're using employee ID login, we'll assume the password is stored securely
                    // In a real implementation, you'd use Firebase Auth custom authentication
                    var firebaseUser = await FirebaseAuth.DefaultInstance.GetUserAsync(firebaseUserId);

                    // Check if user account is disabled
                    if (firebaseUser.Disabled)
                    {
                        return BadRequest(new { error = "The user account has been disabled by an administrator." });
                    }

                    // Generate JWT token
                    var token = _jwtService.GenerateToken(
                        firebaseUserId,
                        request.EmployeeId,
                        firebaseUser.Email,
                        userData.GetValueOrDefault("firstName", "Unknown").ToString(),
                        userData.GetValueOrDefault("lastName", "User").ToString()
                    );

                    // For now, we'll just return success if the user exists
                    // In production, implement proper password verification
                    return Ok(new
                    {
                        token = token,
                        user = new
                        {
                            userId = firebaseUserId,
                            email = firebaseUser.Email,
                            firstName = userData.GetValueOrDefault("firstName", "Unknown"),
                            lastName = userData.GetValueOrDefault("lastName", "User"),
                            employeeId = request.EmployeeId,
                            photoUrl = userData.GetValueOrDefault("photoUrl", "/images/default-avatar.png")
                        }
                    });
                }
                catch (FirebaseAuthException)
                {
                    return BadRequest(new { error = "Account not found" });
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Employee login API error: {ex.Message}");
                return StatusCode(500, new { error = "An error occurred during login. Please try again." });
            }
        }

        [HttpGet("getUserPhotoBase64ByEmployeeId")]
        public async Task<IActionResult> GetUserPhotoBase64ByEmployeeId(string employeeId)
        {
            try
            {
                if (string.IsNullOrEmpty(employeeId) || employeeId.Length != 10 || !employeeId.StartsWith("EMP-00"))
                {
                    return Ok(new { imagePath = "/images/default-avatar.png" });
                }

                // First, get the Firebase user ID from employee_ids collection
                DocumentReference employeeDoc = _firestore.Collection("employee_ids").Document(employeeId);
                DocumentSnapshot employeeSnapshot = await employeeDoc.GetSnapshotAsync();

                if (!employeeSnapshot.Exists)
                {
                    return Ok(new { imagePath = "/images/default-avatar.png" });
                }

                var employeeData = employeeSnapshot.ToDictionary();
                string firebaseUserId = employeeData.GetValueOrDefault("uid", "").ToString();

                if (string.IsNullOrEmpty(firebaseUserId))
                {
                    return Ok(new { imagePath = "/images/default-avatar.png" });
                }

                // Now fetch user photo from the users collection using Firebase user ID
                DocumentReference userDoc = _firestore.Collection("users").Document(firebaseUserId);
                DocumentSnapshot userSnapshot = await userDoc.GetSnapshotAsync();

                if (userSnapshot.Exists)
                {
                    var userData = userSnapshot.ToDictionary();
                    string photoUrl = userData.GetValueOrDefault("photoUrl", "/images/default-avatar.png")?.ToString() ?? "/images/default-avatar.png";
                    return Ok(new { imagePath = photoUrl });
                }

                return Ok(new { imagePath = "/images/default-avatar.png" });
            }
            catch
            {
                return Ok(new { imagePath = "/images/default-avatar.png" });
            }
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            try
            {
                // Validate Email
                if (string.IsNullOrEmpty(request.Email))
                {
                    return BadRequest(new { error = "Please enter email" });
                }

                if (string.IsNullOrEmpty(request.Password))
                {
                    return BadRequest(new { error = "Please enter password" });
                }

                // Query users collection to find user by email
                Query query = _firestore.Collection("users").WhereEqualTo("email", request.Email);
                QuerySnapshot querySnapshot = await query.GetSnapshotAsync();

                if (querySnapshot.Documents.Count == 0)
                {
                    return BadRequest(new { error = "Invalid email or password" });
                }

                var userDoc = querySnapshot.Documents[0];
                var userData = userDoc.ToDictionary();
                string firebaseUserId = userDoc.Id;

                // Now get employeeId from employee_ids collection
                Query employeeQuery = _firestore.Collection("employee_ids").WhereEqualTo("uid", firebaseUserId);
                QuerySnapshot employeeSnapshot = await employeeQuery.GetSnapshotAsync();

                if (employeeSnapshot.Documents.Count == 0)
                {
                    return BadRequest(new { error = "User account not properly configured" });
                }

                var employeeDoc = employeeSnapshot.Documents[0];
                var employeeData = employeeDoc.ToDictionary();
                string employeeId = employeeDoc.Id;

                // Verify with Firebase Auth - check if user exists
                try
                {
                    var firebaseUser = await FirebaseAuth.DefaultInstance.GetUserAsync(firebaseUserId);

                    // Check if user account is disabled
                    if (firebaseUser.Disabled)
                    {
                        return BadRequest(new { error = "The user account has been disabled by an administrator." });
                    }

                    // Generate JWT token
                    var token = _jwtService.GenerateToken(
                        firebaseUserId,
                        employeeId,
                        firebaseUser.Email,
                        userData.GetValueOrDefault("firstName", "Unknown").ToString(),
                        userData.GetValueOrDefault("lastName", "User").ToString()
                    );

                    // For now, we'll just return success if the user exists
                    // In production, implement proper password verification
                    return Ok(new
                    {
                        token = token,
                        user = new
                        {
                            userId = firebaseUserId,
                            email = firebaseUser.Email,
                            firstName = userData.GetValueOrDefault("firstName", "Unknown"),
                            lastName = userData.GetValueOrDefault("lastName", "User"),
                            employeeId = employeeId,
                            department = userData.GetValueOrDefault("department", ""),
                            hod = userData.GetValueOrDefault("hod", ""),
                            jobTitle = userData.GetValueOrDefault("jobTitle", ""),
                            photoUrl = userData.GetValueOrDefault("photoUrl", "/images/default-avatar.png")
                        }
                    });
                }
                catch (FirebaseAuthException)
                {
                    return BadRequest(new { error = "Account not found" });
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Login API error: {ex.Message}");
                return StatusCode(500, new { error = "An error occurred during login. Please try again." });
            }
        }
    }

    public class LoginByEmployeeIdRequest
    {
        public string EmployeeId { get; set; }
        public string Password { get; set; }
    }

    public class LoginRequest
    {
        public string Email { get; set; }
        public string Password { get; set; }
    }
}
