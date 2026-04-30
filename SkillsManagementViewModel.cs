using System.Collections.Generic;

namespace SkillsAuditSystem.Models
{
    public class SkillsManagementViewModel
    {
        public List<SkillDemand> Skills { get; set; } = new List<SkillDemand>();
        public string AdminId { get; set; }
    }
}
