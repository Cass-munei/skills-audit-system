using PdfSharp.Fonts;
using System.IO;

public class CustomFontResolver : IFontResolver
{
    public string DefaultFontName => "Arial";

    public byte[] GetFont(string faceName)
    {
        // Try to load Arial from system fonts
        if (faceName.Equals("Arial", StringComparison.OrdinalIgnoreCase))
        {
            var fontPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Fonts), "arial.ttf");
            if (File.Exists(fontPath))
            {
                return File.ReadAllBytes(fontPath);
            }
        }

        // For other fonts or if Arial not found, return null (let PdfSharp handle it)
        return null;
    }

    public FontResolverInfo ResolveTypeface(string familyName, bool isBold, bool isItalic)
    {
        // Return the family name as is
        return new FontResolverInfo(familyName);
    }
}
