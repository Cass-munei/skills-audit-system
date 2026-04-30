using PdfSharp.Fonts;
using System;
using System.IO;
using System.Reflection;

namespace SkillsAuditSystem.Controllers
{
    public class FontResolver : IFontResolver
    {
        public byte[] GetFont(string faceName)
        {
            switch (faceName)
            {
                case "Arial":
                    return LoadFontData("arial.ttf");
                case "Arial-Bold":
                    return LoadFontData("arialbd.ttf");
                default:
                    return LoadFontData("arial.ttf"); // Fallback
            }
        }

        public FontResolverInfo ResolveTypeface(string familyName, bool isBold, bool isItalic)
        {
            if (familyName.Equals("Arial", StringComparison.CurrentCultureIgnoreCase))
            {
                if (isBold)
                {
                    return new FontResolverInfo("Arial-Bold");
                }
                else
                {
                    return new FontResolverInfo("Arial");
                }
            }

            // Fallback
            return new FontResolverInfo("Arial");
        }

        private byte[] LoadFontData(string resourceName)
        {
            var assembly = Assembly.GetExecutingAssembly();
            var resourcePath = $"SkillsAuditSystem.Controllers.Fonts.{resourceName}";

            using (Stream stream = assembly.GetManifestResourceStream(resourcePath))
            {
                if (stream == null)
                {
                    throw new ArgumentException($"Font resource '{resourceName}' not found.");
                }

                using (var memoryStream = new MemoryStream())
                {
                    stream.CopyTo(memoryStream);
                    return memoryStream.ToArray();
                }
            }
        }
    }
}
