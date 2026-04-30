using Microsoft.AspNetCore.Mvc;
using FirebaseAdmin.Auth;
using Google.Cloud.Firestore;
using System.Threading.Tasks;
using System.Text.RegularExpressions;
using System.Collections.Generic;

namespace SkillsAuditSystem.Controllers
{
    public class RegistrationController : Controller
    {
        private readonly FirestoreDb _firestore;

        public RegistrationController(FirestoreDb firestore)
        {
            _firestore = firestore;
        }

        public IActionResult Index()
        {
            ViewBag.Departments = GetDepartments();
            ViewBag.HodMap = GetHodMap();
            ViewBag.JobTitleMap = GetJobTitleMap();
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Index(string firstName, string lastName, string employeeEmail,
            string employeeId, string contact, string department, string hod, string jobTitle, string password,
            string confirmPassword, bool termsAccepted)
        {
            // Clear previous errors
            ModelState.Clear();

            // Validation
            bool isValid = true;

            if (string.IsNullOrWhiteSpace(firstName))
            {
                ModelState.AddModelError("firstName", "First name is required");
                isValid = false;
            }

            if (string.IsNullOrWhiteSpace(lastName))
            {
                ModelState.AddModelError("lastName", "Last name is required");
                isValid = false;
            }

            if (string.IsNullOrWhiteSpace(employeeEmail))
            {
                ModelState.AddModelError("employeeEmail", "Email is required");
                isValid = false;
            }
            else if (!employeeEmail.Contains("@"))
            {
                ModelState.AddModelError("employeeEmail", "Email must contain '@'");
                isValid = false;
            }
            else if (!employeeEmail.EndsWith("treasury.gov.za"))
            {
                ModelState.AddModelError("employeeEmail", "Email must end with 'treasury.gov.za'");
                isValid = false;
            }

            if (string.IsNullOrWhiteSpace(employeeId))
            {
                ModelState.AddModelError("employeeId", "Employee ID is required");
                isValid = false;
            }
            else if (employeeId.Length != 10 || !employeeId.StartsWith("EMP-00") ||
                     !Regex.IsMatch(employeeId.Substring(6), @"^\d{4}$"))
            {
                ModelState.AddModelError("employeeId", "Employee ID must be in format EMP-00XXXX");
                isValid = false;
            }

            if (string.IsNullOrWhiteSpace(contact))
            {
                ModelState.AddModelError("contact", "Contact number is required");
                isValid = false;
            }
            else if (!Regex.IsMatch(contact, @"^0\d{9}$"))
            {
                ModelState.AddModelError("contact", "Contact number must be 10 digits starting with 0 (e.g., 0123456789)");
                isValid = false;
            }

            if (string.IsNullOrWhiteSpace(department))
            {
                ModelState.AddModelError("department", "Department is required");
                isValid = false;
            }

            if (string.IsNullOrWhiteSpace(hod))
            {
                ModelState.AddModelError("hod", "Head of Department is required");
                isValid = false;
            }

            if (string.IsNullOrWhiteSpace(jobTitle))
            {
                ModelState.AddModelError("jobTitle", "Role / Job Title is required");
                isValid = false;
            }

            if (string.IsNullOrWhiteSpace(password))
            {
                ModelState.AddModelError("password", "Password is required");
                isValid = false;
            }
            else if (!IsValidPassword(password))
            {
                ModelState.AddModelError("password", "Password must contain special characters such as \"0-9/\\ @#$\" with both lower and upper cases and the password must be at least 8 characters long");
                isValid = false;
            }

            if (string.IsNullOrWhiteSpace(confirmPassword))
            {
                ModelState.AddModelError("confirmPassword", "Confirm password is required");
                isValid = false;
            }
            else if (password != confirmPassword)
            {
                ModelState.AddModelError("confirmPassword", "Passwords do not match");
                isValid = false;
            }

            if (!termsAccepted)
            {
                ModelState.AddModelError("termsAccepted", "You must accept the Terms of Service and Privacy Policy");
                isValid = false;
            }

            if (!isValid)
            {
                ViewBag.Departments = GetDepartments();
                ViewBag.HodMap = GetHodMap();
                ViewBag.JobTitleMap = GetJobTitleMap();
                return View();
            }

            // Generate 6-digit OTP
            var otp = new Random().Next(100000, 999999).ToString();
            HttpContext.Session.SetString($"otp_{employeeEmail}", otp);
            Console.WriteLine($"OTP for {employeeEmail}: {otp}");

            // Store registration data in TempData
            TempData["firstName"] = firstName;
            TempData["lastName"] = lastName;
            TempData["employeeEmail"] = employeeEmail;
            TempData["employeeId"] = employeeId;
            TempData["contact"] = contact;
            TempData["department"] = department;
            TempData["hod"] = hod;
            TempData["jobTitle"] = jobTitle;
            TempData["password"] = password;

            return RedirectToAction("VerifyOtp");

            try
            {
                // Check if user already exists
                try
                {
                    var existingUser = await FirebaseAuth.DefaultInstance.GetUserByEmailAsync(employeeEmail);
                    ModelState.AddModelError("authError", "An account with this email already exists");
                    ViewBag.Departments = GetDepartments();
                    ViewBag.HodMap = GetHodMap();
                    ViewBag.JobTitleMap = GetJobTitleMap();
                    return View();
                }
                catch (FirebaseAuthException)
                {
                    // User doesn't exist, continue with registration
                }

                // Check if employee ID already exists
                var employeeDoc = _firestore.Collection("employee_ids").Document(employeeId);
                var employeeSnapshot = await employeeDoc.GetSnapshotAsync();
                if (employeeSnapshot.Exists)
                {
                    ModelState.AddModelError("employeeId", "Employee ID already exists");
                    ViewBag.Departments = GetDepartments();
                    ViewBag.HodMap = GetHodMap();
                    ViewBag.JobTitleMap = GetJobTitleMap();
                    return View();
                }

                // Create Firebase user
                var userRecordArgs = new UserRecordArgs()
                {
                    Email = employeeEmail,
                    Password = password,
                    DisplayName = $"{firstName} {lastName}",
                    EmailVerified = false,
                    Disabled = false,
                };

                var userRecord = await FirebaseAuth.DefaultInstance.CreateUserAsync(userRecordArgs);

                // Store user data in Firestore
                var userDoc = _firestore.Collection("users").Document(userRecord.Uid);
                var userData = new Dictionary<string, object>
                {
                    { "firstName", firstName },
                    { "lastName", lastName },
                    { "email", employeeEmail },
                    { "employeeId", employeeId },
                    { "department", department },
                    { "hod", hod },
                    { "jobTitle", jobTitle },
                    { "createdAt", Timestamp.GetCurrentTimestamp() },
                    { "photoUrl", "/images/default-avatar.png" }
                };

                await userDoc.SetAsync(userData);

                // Store employee ID mapping
                var employeeData = new Dictionary<string, object>
                {
                    { "uid", userRecord.Uid },
                    { "email", employeeEmail },
                    { "createdAt", Timestamp.GetCurrentTimestamp() }
                };

                await employeeDoc.SetAsync(employeeData);

                // Success - redirect back to registration page with snackbar message
                TempData["SnackbarMessage"] = $"User({employeeId}) has successfully registered. Navigating to Login....";
                return RedirectToAction("Index", "Registration");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Registration error: {ex.Message}");
                ModelState.AddModelError("authError", "Registration failed. Please try again.");
                ViewBag.Departments = GetDepartments();
                ViewBag.HodMap = GetHodMap();
                ViewBag.JobTitleMap = GetJobTitleMap();
                return View();
            }
        }

        private List<string> GetDepartments()
        {
            return new List<string>
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
        }

        private Dictionary<string, List<string>> GetHodMap()
        {
            return new Dictionary<string, List<string>>
            {
                { "Office of the Director-General", new List<string> { "Tlotlo Mokaleng" } },
                { "Intergovernmental Relations", new List<string> { "Kamohelo Mkhatshwa" } },
                { "Office of the General Counsel", new List<string> { "Lethabo Rabothata" } },
                { "Budget Preparation / Budget Office", new List<string> { "Noncedo Ngcobo" } },
                { "Economic Policy and International Cooperation", new List<string> { "Noxolo Mabunda" } },
                { "Office of the Accountant-General", new List<string> { "Cassandra Munyai" } },
                { "Tax & Financial Sector Policy", new List<string> { "Fana Mokhotu" } },
                { "Assets & Liability Management", new List<string> { "Muzi Mkhize" } },
                { "Public Finance / Expenditure Control", new List<string> { "Tumelo Legodi" } },
                { "Corporate / Support Services (HR, ICT, Facilities, Legal, Security, etc.)", new List<string> { "Dikatlego Kgopane" } },
                { "Chief Procurement Office", new List<string> { "Wesley Magata" } }
            };
        }

        private Dictionary<string, List<string>> GetJobTitleMap()
        {
            return new Dictionary<string, List<string>>
            {
                { "Budget Preparation / Budget Office", new List<string> {
                    "Expenditure Planning",
                    "Public Finance Statistics",
                    "International Development Co-operation",
                    "Fiscal Policy",
                    "Public Sector Remuneration Unit",
                    "Infrastructure Regulation and Assessment Unit"
                }},
                { "Chief Procurement Office", new List<string> {
                    "Transversal Contracting",
                    "SCM Policy, Norms & Standards",
                    "Strategic Procurement",
                    "SCM Client Support",
                    "SCM Information, Communication & Technology",
                    "SCM Governance, Monitoring & Compliance"
                }},
                { "Corporate / Support Services (HR, ICT, Facilities, Legal, Security, etc.)", new List<string> {
                    "Strategic Projects & Support",
                    "Human Resources Management",
                    "Information & Communications Technology",
                    "Facilities Management",
                    "Security Management",
                    "Media Liaison & Communications"
                }},
                { "Intergovernmental Relations", new List<string> {
                    "Local Government Budget Analysis",
                    "Intergovernmental Policy & Planning",
                    "Provincial & Local Government Infrastructure",
                    "Provincial Budget Analysis",
                    "Neighbourhood Development Unit"
                }},
                { "Assets & Liability Management", new List<string> {
                    "Sectoral Oversight",
                    "Liability Management",
                    "Financial Operations",
                    "Strategy & Risk Management",
                    "Governance & Financial Analysis"
                }},
                { "Public Finance / Expenditure Control", new List<string> {
                    "Justice & Protection Services",
                    "Economic Services",
                    "Administrative Services",
                    "Education & Related Departments & Labour",
                    "Health & Social Development",
                    "Urban Development & Infrastructure"
                }},
                { "Tax & Financial Sector Policy", new List<string> {
                    "Financial Sector Development",
                    "Financial Services",
                    "Financial Stability",
                    "Economic Tax Analysis",
                    "Legal Tax Design"
                }},
                { "Office of the General Counsel", new List<string> {
                    "Legal Services",
                    "Legislation",
                    "Public Entities Governance Unit (PEGU)"
                }},
                { "Economic Policy and International Cooperation", new List<string> {
                    "Modelling & Forecasting",
                    "Microeconomic Policy",
                    "Macroeconomic Policy",
                    "African Economic Integration",
                    "Multilateral Development Banks & Concessional Finance",
                    "Global and Emerging Markets"
                }},
                { "Office of the Accountant-General", new List<string> {
                    "Capacity Building",
                    "MFMA Implementation",
                    "Accounting Support & Integration",
                    "Internal Audit Support",
                    "Risk Management",
                    "Technical Support Services",
                    "Governance Monitoring & Compliance",
                    "Specialised Audit Services",
                    "Financial Systems",
                    "Integrated Financial Management Systems (IFMS)"
                }},
                { "Office of the Director-General", new List<string> {
                    "Financial Management (including Supply Chain Management)",
                    "Data Analytics",
                    "Strategic Management & Oversight",
                    "Enterprise Risk Management",
                    "Internal Audit"
                }}
            };
        }

        public IActionResult VerifyOtp()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> VerifyOtp(string otp)
        {
            // Retrieve registration data from TempData
            var firstName = TempData["firstName"] as string;
            var lastName = TempData["lastName"] as string;
            var employeeEmail = TempData["employeeEmail"] as string;
            var employeeId = TempData["employeeId"] as string;
            var contact = TempData["contact"] as string;
            var department = TempData["department"] as string;
            var hod = TempData["hod"] as string;
            var jobTitle = TempData["jobTitle"] as string;
            var password = TempData["password"] as string;

            if (string.IsNullOrWhiteSpace(employeeEmail) || string.IsNullOrWhiteSpace(otp))
            {
                ModelState.AddModelError("otp", "Invalid request");
                return View();
            }

            var storedOtp = HttpContext.Session.GetString($"otp_{employeeEmail}");
            if (storedOtp == null || storedOtp != otp)
            {
                ModelState.AddModelError("otp", "Invalid OTP. Please try again.");
                return View();
            }

            // Clear OTP from session
            HttpContext.Session.Remove($"otp_{employeeEmail}");

            // Proceed with registration
            try
            {
                // Check if user already exists
                try
                {
                    var existingUser = await FirebaseAuth.DefaultInstance.GetUserByEmailAsync(employeeEmail);
                    ModelState.AddModelError("authError", "An account with this email already exists");
                    return View();
                }
                catch (FirebaseAuthException)
                {
                    // User doesn't exist, continue with registration
                }

                // Check if employee ID already exists
                var employeeDoc = _firestore.Collection("employee_ids").Document(employeeId);
                var employeeSnapshot = await employeeDoc.GetSnapshotAsync();
                if (employeeSnapshot.Exists)
                {
                    ModelState.AddModelError("employeeId", "Employee ID already exists");
                    return View();
                }

                // Create Firebase user
                var userRecordArgs = new UserRecordArgs()
                {
                    Email = employeeEmail,
                    Password = password,
                    DisplayName = $"{firstName} {lastName}",
                    EmailVerified = false,
                    Disabled = false,
                };

                var userRecord = await FirebaseAuth.DefaultInstance.CreateUserAsync(userRecordArgs);

                // Store user data in Firestore
                var userDoc = _firestore.Collection("users").Document(userRecord.Uid);
                var userData = new Dictionary<string, object>
                {
                    { "firstName", firstName },
                    { "lastName", lastName },
                    { "email", employeeEmail },
                    { "employeeId", employeeId },
                    { "contact", contact },
                    { "department", department },
                    { "hod", hod },
                    { "jobTitle", jobTitle },
                    { "createdAt", Timestamp.GetCurrentTimestamp() },
                    { "photoUrl", "/images/default-avatar.png" }
                };

                await userDoc.SetAsync(userData);

                // Store employee ID mapping
                var employeeData = new Dictionary<string, object>
                {
                    { "uid", userRecord.Uid },
                    { "email", employeeEmail },
                    { "createdAt", Timestamp.GetCurrentTimestamp() }
                };

                await employeeDoc.SetAsync(employeeData);

                // Clear TempData
                TempData.Clear();

                // Success - redirect back to registration page with snackbar message
                TempData["SnackbarMessage"] = $"User({employeeId}) has successfully registered. Navigating to Login....";
                return RedirectToAction("Index", "Registration");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Registration error: {ex.Message}");
                ModelState.AddModelError("authError", "Registration failed. Please try again.");
                return View();
            }
        }

        private bool IsValidPassword(string password)
        {
            if (password.Length < 8) return false;
            if (!Regex.IsMatch(password, @"[A-Z]")) return false;
            if (!Regex.IsMatch(password, @"[a-z]")) return false;
            if (!Regex.IsMatch(password, @"[0-9/\\ @#$]")) return false;
            return true;
        }
    }
}
