using Microsoft.AspNetCore.Mvc;
using Google.Cloud.Firestore;
using SkillsAuditSystem.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace SkillsAuditSystem.Controllers
{
    public class SkillsManagementController : Controller
    {
        private readonly FirestoreDb _firestore;

        public SkillsManagementController(FirestoreDb firestore)
        {
            _firestore = firestore;
        }

        public async Task<IActionResult> Index()
        {
            // Check if user is authenticated and is admin
            var userId = HttpContext.Session.GetString("userId");
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (string.IsNullOrEmpty(userId) || !isAdmin)
            {
                return RedirectToAction("Index", "Login");
            }

            var viewModel = new SkillsManagementViewModel
            {
                AdminId = employeeId ?? "ADMIN",
                Skills = new List<SkillDemand>()
            };

            try
            {
                // Get all skills in demand from Firestore
                var skillsRef = _firestore.Collection("skillsDemand");
                var snapshot = await skillsRef.GetSnapshotAsync();

                foreach (var document in snapshot.Documents)
                {
                    var skillDemand = SkillDemand.FromMap(document.ToDictionary(), document.Id);
                    viewModel.Skills.Add(skillDemand);
                }
            }
            catch (Exception ex)
            {
                // Handle errors gracefully
                Console.WriteLine($"Error loading skills management data: {ex.Message}");
            }

            return View(viewModel);
        }

        [HttpPost]
        public async Task<IActionResult> AddSkillRequirement(string name, string department, string requiredLevel, string employeesMatching, string totalEmployees)
        {
            // Check admin authentication
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (!isAdmin)
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            try
            {
                // Parse total employees from string, or calculate if not provided
                int parsedTotalEmployees;
                if (!string.IsNullOrEmpty(totalEmployees) && int.TryParse(totalEmployees, out parsedTotalEmployees))
                {
                    // Use provided value
                }
                else
                {
                    // Calculate total employees
                    parsedTotalEmployees = await GetTotalEmployeesInDepartment(department);
                }

                // Parse employees matching from string, or calculate if not provided
                int parsedEmployeesMatching;
                if (!string.IsNullOrEmpty(employeesMatching) && int.TryParse(employeesMatching, out parsedEmployeesMatching))
                {
                    // Use provided value
                }
                else
                {
                    // Calculate employees matching
                    parsedEmployeesMatching = await CalculateEmployeesMatching(department, name, requiredLevel, parsedTotalEmployees);
                }

                // Calculate gap percentage automatically: gap = (total employees - employees matching) / total employees
                double parsedGapPercentage = parsedTotalEmployees > 0 ? (double)(parsedTotalEmployees - parsedEmployeesMatching) / parsedTotalEmployees : 0.0;

                // Auto-generate description based on skill name
                string generatedDescription = $"{name} is a valuable skill in our organization. Mastering this competency will enhance your professional development and contribute to team success. Consider exploring training opportunities and practical applications to strengthen this skill.";

                var skillDemand = new SkillDemand
                {
                    Name = name,
                    Department = department,
                    RequiredLevel = requiredLevel,
                    GapPercentage = parsedGapPercentage,
                    EmployeesMatching = parsedEmployeesMatching,
                    TotalEmployees = parsedTotalEmployees,
                    Description = generatedDescription
                };

                var skillsRef = _firestore.Collection("skillsDemand");
                await skillsRef.AddAsync(skillDemand.ToMap());

                return Json(new { success = true, message = "Skill requirement added successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error: {ex.Message}" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> UpdateSkillRequirement(string id, string name, string department, string requiredLevel, string employeesMatching, string totalEmployees)
        {
            // Check admin authentication
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (!isAdmin)
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            try
            {
                // Parse total employees from string, or calculate if not provided
                int parsedTotalEmployees;
                if (!string.IsNullOrEmpty(totalEmployees) && int.TryParse(totalEmployees, out parsedTotalEmployees))
                {
                    // Use provided value
                }
                else
                {
                    // Calculate total employees
                    parsedTotalEmployees = await GetTotalEmployeesInDepartment(department);
                }

                // Parse employees matching from string, or calculate if not provided
                int parsedEmployeesMatching;
                if (!string.IsNullOrEmpty(employeesMatching) && int.TryParse(employeesMatching, out parsedEmployeesMatching))
                {
                    // Use provided value
                }
                else
                {
                    // Calculate employees matching
                    parsedEmployeesMatching = await CalculateEmployeesMatching(department, name, requiredLevel, parsedTotalEmployees);
                }

                // Calculate gap percentage automatically: gap = (total employees - employees matching) / total employees
                double parsedGapPercentage = parsedTotalEmployees > 0 ? (double)(parsedTotalEmployees - parsedEmployeesMatching) / parsedTotalEmployees : 0.0;

                // Auto-generate description based on skill name
                string generatedDescription = $"{name} is a valuable skill in our organization. Mastering this competency will enhance your professional development and contribute to team success. Consider exploring training opportunities and practical applications to strengthen this skill.";

                var skillDemand = new SkillDemand
                {
                    Name = name,
                    Department = department,
                    RequiredLevel = requiredLevel,
                    GapPercentage = parsedGapPercentage,
                    EmployeesMatching = parsedEmployeesMatching,
                    TotalEmployees = parsedTotalEmployees,
                    Description = generatedDescription
                };

                var skillRef = _firestore.Collection("skillsDemand").Document(id);
                await skillRef.SetAsync(skillDemand.ToMap());

                return Json(new { success = true, message = "Skill requirement updated successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error: {ex.Message}" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> DeleteSkillRequirement(string id)
        {
            // Check admin authentication
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (!isAdmin)
            {
                return Json(new { success = false, message = "Unauthorized" });
            }

            try
            {
                var skillRef = _firestore.Collection("skillsDemand").Document(id);
                await skillRef.DeleteAsync();

                return Json(new { success = true, message = "Skill requirement deleted successfully" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error: {ex.Message}" });
            }
        }

        // Helper methods for gap analysis calculations
        private double CalculateGapPercentage(string department, string skillName, string requiredLevel)
        {
            // Mock calculation - in real implementation, this would analyze employee skills data
            // For now, return a random gap between 10-50%
            var random = new Random();
            return random.Next(10, 51) / 100.0;
        }

        private async Task<int> CalculateEmployeesMatching(string department, string skillName, string requiredLevel, int totalEmployees)
        {
            // Mock calculation - in real implementation, this would count employees with the required skill level
            var random = new Random();
            return random.Next(0, totalEmployees + 1);
        }

        private async Task<int> GetTotalEmployeesInDepartment(string department)
        {
            try
            {
                // Query Firestore to count users in the specified department
                var usersRef = _firestore.Collection("users");
                var query = usersRef.WhereEqualTo("department", department);
                var snapshot = await query.GetSnapshotAsync();

                // Count only non-admin users
                int count = 0;
                foreach (var document in snapshot.Documents)
                {
                    var userData = document.ToDictionary();
                    var employeeId = userData.GetValueOrDefault("employeeId", "") as string;
                    if (!string.IsNullOrEmpty(employeeId) && !employeeId.StartsWith("ADM-"))
                    {
                        count++;
                    }
                }

                return count > 0 ? count : 1; // Return at least 1 to avoid division by zero
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error getting total employees for department {department}: {ex.Message}");
                // Fallback to mock data if query fails
                var departmentSizes = new Dictionary<string, int>
                {
                    { "Office of the Director-General", 15 },
                    { "Intergovernmental Relations", 20 },
                    { "Office of the General Counsel", 10 },
                    { "Budget Preparation / Budget Office", 25 },
                    { "Economic Policy and International Cooperation", 30 },
                    { "Office of the Accountant-General", 18 },
                    { "Tax & Financial Sector Policy", 22 },
                    { "Assets & Liability Management", 16 },
                    { "Public Finance / Expenditure Control", 28 },
                    { "Corporate / Support Services (HR, ICT, Facilities, Legal, Security, etc.)", 35 },
                    { "Chief Procurement Office", 12 }
                };

                return departmentSizes.ContainsKey(department) ? departmentSizes[department] : 10;
            }
        }
    }
}
