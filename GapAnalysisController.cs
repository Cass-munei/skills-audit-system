using Microsoft.AspNetCore.Mvc;
using Google.Cloud.Firestore;
using SkillsAuditSystem.Models;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using PdfSharp.Pdf;
using PdfSharp.Drawing;
using System.IO;
using System.Text;
using System.Drawing;
using PdfSharp.Fonts;

namespace SkillsAuditSystem.Controllers
{
    public class GapAnalysisController : Controller
    {
        private readonly FirestoreDb _firestore;

        public GapAnalysisController(FirestoreDb firestore)
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

            var viewModel = new GapAnalysisViewModel
            {
                AdminId = employeeId ?? "ADMIN"
            };

            // Fetch real skills data from Firestore (using SkillDemand model)
            var skillsCollection = _firestore.Collection("skills");
            var skillsSnapshot = await skillsCollection.GetSnapshotAsync();
            var skills = new List<SkillDemand>();

            foreach (var document in skillsSnapshot.Documents)
            {
                var skill = document.ConvertTo<SkillDemand>();
                skills.Add(skill);
            }

            // Fetch skills in demand from the skillsDemand collection
            var skillsDemandCollection = _firestore.Collection("skillsDemand");
            var skillsDemandSnapshot = await skillsDemandCollection.GetSnapshotAsync();
            var skillsInDemand = new List<SkillDemand>();

            foreach (var document in skillsDemandSnapshot.Documents)
            {
                var skillDemand = SkillDemand.FromMap(document.ToDictionary(), document.Id);
                skillsInDemand.Add(skillDemand);
            }

            // Fetch qualifications data
            var qualificationsCollection = _firestore.Collection("qualifications");
            var qualificationsSnapshot = await qualificationsCollection.GetSnapshotAsync();
            var qualifications = new List<Qualification>();

            foreach (var document in qualificationsSnapshot.Documents)
            {
                var qualification = document.ConvertTo<Qualification>();
                qualifications.Add(qualification);
            }

            // Fetch training data
            var trainingCollection = _firestore.Collection("training");
            var trainingSnapshot = await trainingCollection.GetSnapshotAsync();
            var trainings = new List<Training>();

            foreach (var document in trainingSnapshot.Documents)
            {
                var training = document.ConvertTo<Training>();
                trainings.Add(training);
            }

            // Calculate top skills gaps (top 5 by gap percentage)
            viewModel.TopSkillsGaps = skills
                .OrderByDescending(s => s.GapPercentage)
                .Take(5)
                .Select(s => new TopSkillGap { Name = s.Name, GapPercentage = s.GapPercentage })
                .ToList();

            // Calculate key metrics
            var totalSkills = skills.Count;
            var averageGap = skills.Any() ? skills.Average(s => s.GapPercentage) : 0;
            var criticalGaps = skills.Count(s => s.GapPercentage >= 0.7); // Critical if gap >= 70%
            var employeesWithGaps = skills.Where(s => s.GapPercentage > 0).Select(s => s.TotalEmployees - s.EmployeesMatching).Sum();
            var departmentsAnalyzed = skills.Select(s => s.Department).Distinct().Count();

            // Calculate average qualification match from real qualification data
            var totalQualifications = qualifications.Count;
            var matchedQualifications = qualifications.Count(q => q.Name.Contains("Master") || q.Name.Contains("PhD") || q.Name.Contains("Bachelor"));
            var avgQualificationMatch = totalQualifications > 0 ? (double)matchedQualifications / totalQualifications * 100 : 76.0;

            viewModel.KeyMetrics = new KeyMetrics
            {
                TopSkills = totalSkills,
                AverageGap = averageGap,
                CriticalGaps = criticalGaps,
                AvgQualificationMatch = avgQualificationMatch
            };

            // Calculate gap distribution per department using skills in demand
            var departmentGaps = skillsInDemand
                .GroupBy(s => s.Department)
                .Select(g => new
                {
                    Department = g.Key,
                    AverageGap = g.Average(s => s.GapPercentage)
                })
                .OrderByDescending(g => g.AverageGap)
                .ToDictionary(g => g.Department, g => g.AverageGap);

            viewModel.GapDistribution = departmentGaps;

            // Populate departments and skill categories
            viewModel.Departments = new List<string>
            {
                "Office of the Director-General",
                "Intergovernmental Relations",
                "Office of the General Counsel",
                "Budget Preparation / Budget Office",
                "Economic Policy and International Cooperation",
                "Office of the Accountant-General",
                "Tax & Financial Sector Policy",
                "Assets & Liability Management",
                "Public Finance / Expenditure Control",
                "Corporate / Support Services (HR, ICT, Facilities, Legal, Security, etc.)",
                "Chief Procurement Office"
            };
            viewModel.SkillCategories = new List<string>
            {
                "Cognitive & Analytical Skills",
                "Technical & IT Skills",
                "Accountant",
                "Business & Management Skills",
                "Interpersonal & Communication Skills",
                "Leadership & Supervisory Skills",
                "Creative & Design Skills",
                "Engineering & Technical Trade Skills",
                "Compliance & Legal Skills",
                "Digital & Media Skills",
                "Education & Training Skills",
                "Personal Effectiveness Skills",
                "Language & Communication Skills",
                "Operational & Field Skills",
                "Environmental & Sustainability Skills",
                "Other"
            };

            // Qualification Distribution (Donut Chart)
            var qualificationGroups = qualifications
                .GroupBy(q => q.Name)
                .Select(g => new QualificationDistribution
                {
                    Qualification = g.Key,
                    Count = g.Count(),
                    Percentage = (double)g.Count() / qualifications.Count * 100
                })
                .ToList();

            // Add default qualifications if none exist
            if (!qualificationGroups.Any())
            {
                qualificationGroups = new List<QualificationDistribution>
                {
                    new QualificationDistribution { Qualification = "PhD", Count = 5, Percentage = 10 },
                    new QualificationDistribution { Qualification = "Master's", Count = 20, Percentage = 40 },
                    new QualificationDistribution { Qualification = "Bachelor's", Count = 15, Percentage = 30 },
                    new QualificationDistribution { Qualification = "Diploma", Count = 8, Percentage = 16 },
                    new QualificationDistribution { Qualification = "Matric", Count = 2, Percentage = 4 }
                };
            }

            viewModel.QualificationDistributions = qualificationGroups;

            // Initialize SkillCategoryTrends with default values
            viewModel.SkillCategoryTrends = new List<SkillCategoryTrend>
            {
                new SkillCategoryTrend { Category = "Technical", Values = new List<double> { 20, 25, 30, 35, 40 } },
                new SkillCategoryTrend { Category = "Leadership", Values = new List<double> { 15, 18, 22, 28, 32 } },
                new SkillCategoryTrend { Category = "Soft Skills", Values = new List<double> { 10, 12, 15, 18, 20 } },
                new SkillCategoryTrend { Category = "Domain Specific", Values = new List<double> { 25, 28, 32, 38, 42 } }
            };

            // Department Gap Ranking (Horizontal Bar Chart)
            viewModel.DepartmentGapRankings = departmentGaps
                .Select(d => new DepartmentGapRanking { Department = d.Key, GapPercentage = d.Value })
                .OrderByDescending(d => d.GapPercentage)
                .ToList();

            // Training Progress (Gauge Chart)
            viewModel.TrainingProgress = new TrainingProgress
            {
                BeforeTraining = 65.0,
                AfterTraining = 85.0
            };

            // Employee-Level Gap Table - Fetch real employee data from Firestore
            var usersCollection = _firestore.Collection("users");
            var usersSnapshot = await usersCollection.GetSnapshotAsync();
            var employeeGaps = new List<EmployeeGap>();

            foreach (var userDoc in usersSnapshot.Documents)
            {
                var userData = userDoc.ToDictionary();
                var empId = userData.GetValueOrDefault("employeeId", "") as string;

                // Skip admin users
                if (!string.IsNullOrEmpty(empId) && !empId.StartsWith("ADM-"))
                {
                    var firstName = userData.GetValueOrDefault("firstName", "") as string;
                    var lastName = userData.GetValueOrDefault("lastName", "") as string;
                    var employeeName = $"{firstName} {lastName}".Trim();
                    var department = userData.GetValueOrDefault("department", "Unknown") as string;

                    // Fetch employee's skills
                    var skillsRef = _firestore.Collection("users").Document(userDoc.Id).Collection("skills");
                    var empSkillsSnapshot = await skillsRef.GetSnapshotAsync();
                    var employeeSkills = empSkillsSnapshot.Documents.Select(doc => Skill.FromMap(doc.ToDictionary(), doc.Id)).ToList();

                    // Get required skills from skills in demand for this department
                    var requiredSkills = skillsInDemand.Where(s => s.Department == department).Select(s => s.Name).Distinct().ToList();
                    var acquiredSkills = employeeSkills.Select(s => s.Name).ToList();
                    var missingSkills = requiredSkills.Except(acquiredSkills).ToList();

                    // Calculate gap percentage
                    var gapPercentage = requiredSkills.Any() ? (double)missingSkills.Count / requiredSkills.Count : 0;

                    // Determine training status based on trainings
                    var trainingsRef = _firestore.Collection("users").Document(userDoc.Id).Collection("trainings");
                    var empTrainingsSnapshot = await trainingsRef.GetSnapshotAsync();
                    var empTrainings = empTrainingsSnapshot.Documents.Select(doc => Training.FromMap(doc.ToDictionary(), doc.Id)).ToList();

                    var trainingStatus = "Not Assigned";
                    if (empTrainings.Any())
                    {
                        if (empTrainings.Any(t => t.Status == "Completed"))
                            trainingStatus = "Completed";
                        else if (empTrainings.Any(t => t.Status == "In Progress"))
                            trainingStatus = "In Progress";
                        else
                            trainingStatus = "Upcoming";
                    }

                    // Only include employees who have skill gaps (gapPercentage > 0)
                    if (!string.IsNullOrEmpty(employeeName) && gapPercentage > 0 && requiredSkills.Any())
                    {
                        employeeGaps.Add(new EmployeeGap
                        {
                            Employee = employeeName,
                            Department = department,
                            RequiredSkills = string.Join(", ", requiredSkills),
                            MissingSkills = string.Join(", ", missingSkills),
                            GapPercentage = gapPercentage,
                            TrainingStatus = trainingStatus
                        });
                    }
                }
            }

            viewModel.EmployeeGaps = employeeGaps.OrderByDescending(e => e.GapPercentage).ToList(); // Show all employees with gaps, not just top 10

            // Skills Gap Overview (Bar Chart)
            viewModel.SkillsGapOverview = new SkillsGapOverview
            {
                Departments = departmentGaps.Keys.ToList(),
                RequiredLevels = departmentGaps.Values.Select(v => 1.0).ToList(), // Required is always 1.0
                ActualLevels = departmentGaps.Values.Select(v => 1.0 - v).ToList() // Actual = 1 - gap
            };

            return View(viewModel);
        }

        public async Task<IActionResult> Export()
        {
            // Check if user is authenticated and is admin
            var userId = HttpContext.Session.GetString("userId");
            var employeeId = HttpContext.Session.GetString("employeeId");
            var isAdmin = !string.IsNullOrEmpty(employeeId) && employeeId.StartsWith("ADM-01");

            if (string.IsNullOrEmpty(userId) || !isAdmin)
            {
                return RedirectToAction("Index", "Login");
            }

            // Fetch data similar to Index action
            var skillsCollection = _firestore.Collection("skills");
            var skillsSnapshot = await skillsCollection.GetSnapshotAsync();
            var skills = new List<SkillDemand>();
            foreach (var document in skillsSnapshot.Documents)
            {
                var skill = document.ConvertTo<SkillDemand>();
                skills.Add(skill);
            }

            var qualificationsCollection = _firestore.Collection("qualifications");
            var qualificationsSnapshot = await qualificationsCollection.GetSnapshotAsync();
            var qualifications = new List<Qualification>();
            foreach (var document in qualificationsSnapshot.Documents)
            {
                var qualification = document.ConvertTo<Qualification>();
                qualifications.Add(qualification);
            }

            // Fetch skills in demand from the skillsDemand collection
            var skillsDemandCollection = _firestore.Collection("skillsDemand");
            var skillsDemandSnapshot = await skillsDemandCollection.GetSnapshotAsync();
            var skillsInDemand = new List<SkillDemand>();

            foreach (var document in skillsDemandSnapshot.Documents)
            {
                var skillDemand = SkillDemand.FromMap(document.ToDictionary(), document.Id);
                skillsInDemand.Add(skillDemand);
            }

            // Employee Gaps Table
            var usersCollection = _firestore.Collection("users");
            var usersSnapshot = await usersCollection.GetSnapshotAsync();
            var employeeGaps = new List<EmployeeGap>();

            foreach (var userDoc in usersSnapshot.Documents)
            {
                var userData = userDoc.ToDictionary();
                var empId = userData.GetValueOrDefault("employeeId", "") as string;

                if (!string.IsNullOrEmpty(empId) && !empId.StartsWith("ADM-"))
                {
                    var firstName = userData.GetValueOrDefault("firstName", "") as string;
                    var lastName = userData.GetValueOrDefault("lastName", "") as string;
                    var employeeName = $"{firstName} {lastName}".Trim();
                    var department = userData.GetValueOrDefault("department", "Unknown") as string;

                    var skillsRef = _firestore.Collection("users").Document(userDoc.Id).Collection("skills");
                    var empSkillsSnapshot = await skillsRef.GetSnapshotAsync();
                    var employeeSkills = empSkillsSnapshot.Documents.Select(doc => Skill.FromMap(doc.ToDictionary(), doc.Id)).ToList();

                    var requiredSkills = skillsInDemand.Where(s => s.Department == department).Select(s => s.Name).Distinct().ToList();
                    var acquiredSkills = employeeSkills.Select(s => s.Name).ToList();
                    var missingSkills = requiredSkills.Except(acquiredSkills).ToList();
                    var gapPercentage = requiredSkills.Any() ? (double)missingSkills.Count / requiredSkills.Count : 0;

                    // Determine training status based on trainings
                    var trainingsRef = _firestore.Collection("users").Document(userDoc.Id).Collection("trainings");
                    var empTrainingsSnapshot = await trainingsRef.GetSnapshotAsync();
                    var empTrainings = empTrainingsSnapshot.Documents.Select(doc => Training.FromMap(doc.ToDictionary(), doc.Id)).ToList();

                    var trainingStatus = "Not Assigned";
                    if (empTrainings.Any())
                    {
                        if (empTrainings.Any(t => t.Status == "Completed"))
                            trainingStatus = "Completed";
                        else if (empTrainings.Any(t => t.Status == "In Progress"))
                            trainingStatus = "In Progress";
                        else
                            trainingStatus = "Upcoming";
                    }

                    if (!string.IsNullOrEmpty(employeeName) && gapPercentage > 0 && requiredSkills.Any())
                    {
                        employeeGaps.Add(new EmployeeGap
                        {
                            Employee = employeeName,
                            Department = department,
                            RequiredSkills = string.Join(", ", requiredSkills),
                            MissingSkills = string.Join(", ", missingSkills),
                            GapPercentage = gapPercentage,
                            TrainingStatus = trainingStatus
                        });
                    }
                }
            }

            var allEmployeeGaps = employeeGaps.OrderByDescending(e => e.GapPercentage).ToList();

            // Build CSV content
            var csv = new StringBuilder();
            csv.AppendLine("Gap Analysis Report");
            csv.AppendLine($"Generated on: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
            csv.AppendLine();

            // Key Metrics
            var totalSkills = skills.Count;
            var averageGap = skills.Any() ? skills.Average(s => s.GapPercentage) : 0;
            var criticalGaps = skills.Count(s => s.GapPercentage >= 0.7);
            var totalQualifications = qualifications.Count;
            var matchedQualifications = qualifications.Count(q => q.Name.Contains("Master") || q.Name.Contains("PhD") || q.Name.Contains("Bachelor"));
            var avgQualificationMatch = totalQualifications > 0 ? (double)matchedQualifications / totalQualifications * 100 : 76.0;

            csv.AppendLine("Key Metrics");
            csv.AppendLine($"Total Skills Assessed,{totalSkills}");
            csv.AppendLine($"Average Gap,{averageGap:P2}");
            csv.AppendLine($"Critical Gaps,{criticalGaps}");
            csv.AppendLine($"Average Qualification Match,{avgQualificationMatch:F1}%");
            csv.AppendLine();

            // Top Skills Gaps
            if (skills.Any())
            {
                csv.AppendLine("Top Skills Gaps");
                var topGaps = skills.OrderByDescending(s => s.GapPercentage).Take(5);
                foreach (var skill in topGaps)
                {
                    csv.AppendLine($"{skill.Name},{skill.GapPercentage:P2}");
                }
                csv.AppendLine();
            }

            // Qualification Distribution
            if (qualifications.Any())
            {
                csv.AppendLine("Qualification Distribution");
                var qualGroups = qualifications.GroupBy(q => q.Name);
                foreach (var group in qualGroups)
                {
                    var percentage = (double)group.Count() / qualifications.Count * 100;
                    csv.AppendLine($"{group.Key},{percentage:F1}%,{group.Count()}");
                }
                csv.AppendLine();
            }

            // Employee Gaps
            csv.AppendLine("Employee-Level Gap Analysis");
            csv.AppendLine("Employee,Department,Required Skills,Missing Skills,Gap %,Training Status");
            foreach (var emp in allEmployeeGaps)
            {
                csv.AppendLine($"\"{emp.Employee}\",\"{emp.Department}\",\"{emp.RequiredSkills}\",\"{emp.MissingSkills}\",{emp.GapPercentage:P0},\"{emp.TrainingStatus}\"");
            }

            // Return CSV file
            return File(Encoding.UTF8.GetBytes(csv.ToString()), "text/csv", $"GapAnalysisReport_{DateTime.Now:yyyyMMdd_HHmmss}.csv");
        }
    }
}
