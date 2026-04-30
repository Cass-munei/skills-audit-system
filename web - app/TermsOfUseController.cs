using Microsoft.AspNetCore.Mvc;

namespace SkillsAuditSystem.Controllers
{
    public class TermsOfUseController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
