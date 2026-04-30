using System.Collections.Generic;

namespace SkillsAuditSystem.Models
{
    public class GapAnalysisViewModel
    {
        public string AdminId { get; set; }
        public List<TopSkillGap> TopSkillsGaps { get; set; } = new List<TopSkillGap>();
        public List<GapTrend> GapTrends { get; set; } = new List<GapTrend>();
        public KeyMetrics KeyMetrics { get; set; } = new KeyMetrics();
        public Dictionary<string, double> GapDistribution { get; set; } = new Dictionary<string, double>();

        // New properties for the redesigned page
        public List<string> Departments { get; set; } = new List<string>();
        public List<string> SkillCategories { get; set; } = new List<string>();
        public List<QualificationDistribution> QualificationDistributions { get; set; } = new List<QualificationDistribution>();
        public List<SkillCategoryTrend> SkillCategoryTrends { get; set; } = new List<SkillCategoryTrend>();
        public List<DepartmentGapRanking> DepartmentGapRankings { get; set; } = new List<DepartmentGapRanking>();
        public TrainingProgress TrainingProgress { get; set; } = new TrainingProgress();
        public List<EmployeeGap> EmployeeGaps { get; set; } = new List<EmployeeGap>();
        public SkillsGapOverview SkillsGapOverview { get; set; } = new SkillsGapOverview();
    }

    public class TopSkillGap
    {
        public string Name { get; set; }
        public double GapPercentage { get; set; }
    }

    public class GapTrend
    {
        public int Year { get; set; }
        public List<double> PositiveGaps { get; set; } = new List<double>();
        public List<double> NegativeGaps { get; set; } = new List<double>();
    }

    public class KeyMetrics
    {
        public int TopSkills { get; set; }
        public double AverageGap { get; set; }
        public int CriticalGaps { get; set; }
        public double AvgQualificationMatch { get; set; }
    }

    public class QualificationDistribution
    {
        public string Qualification { get; set; }
        public int Count { get; set; }
        public double Percentage { get; set; }
    }

    public class SkillCategoryTrend
    {
        public string Category { get; set; }
        public List<double> Values { get; set; } = new List<double>();
    }

    public class DepartmentGapRanking
    {
        public string Department { get; set; }
        public double GapPercentage { get; set; }
    }

    public class TrainingProgress
    {
        public double BeforeTraining { get; set; }
        public double AfterTraining { get; set; }
    }

    public class EmployeeGap
    {
        public string Employee { get; set; }
        public string Department { get; set; }
        public string RequiredSkills { get; set; }
        public string MissingSkills { get; set; }
        public double GapPercentage { get; set; }
        public string TrainingStatus { get; set; }
    }

    public class SkillsGapOverview
    {
        public List<string> Departments { get; set; } = new List<string>();
        public List<double> RequiredLevels { get; set; } = new List<double>();
        public List<double> ActualLevels { get; set; } = new List<double>();
    }
}
