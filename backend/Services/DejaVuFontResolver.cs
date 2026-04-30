using PdfSharp.Fonts;

namespace TransitFlow.API.Services;

public class DejaVuFontResolver : IFontResolver
{
    private const string SansRegular = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf";
    private const string SansBold = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf";
    private const string SansItalic = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Oblique.ttf";
    private const string SansBoldItalic = "/usr/share/fonts/truetype/dejavu/DejaVuSans-BoldOblique.ttf";

    private const string MonoRegular = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf";
    private const string MonoBold = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf";
    private const string MonoItalic = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Oblique.ttf";
    private const string MonoBoldItalic = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-BoldOblique.ttf";

    public byte[] GetFont(string faceName)
    {
        var path = faceName switch
        {
            "DejaVuSans#Regular" => SansRegular,
            "DejaVuSans#Bold" => SansBold,
            "DejaVuSans#Italic" => SansItalic,
            "DejaVuSans#BoldItalic" => SansBoldItalic,
            "DejaVuSansMono#Regular" => MonoRegular,
            "DejaVuSansMono#Bold" => MonoBold,
            "DejaVuSansMono#Italic" => MonoItalic,
            "DejaVuSansMono#BoldItalic" => MonoBoldItalic,
            _ => SansRegular
        };

        return File.ReadAllBytes(path);
    }

    public FontResolverInfo ResolveTypeface(string familyName, bool isBold, bool isItalic)
    {
        var fam = (familyName ?? string.Empty).Trim();
        var lower = fam.ToLowerInvariant();

        var wantsMono =
            lower.Contains("courier") ||
            lower.Contains("consolas") ||
            lower.Contains("monospace") ||
            lower.Contains("mono");

        var baseName = wantsMono ? "DejaVuSansMono" : "DejaVuSans";

        var style = (isBold, isItalic) switch
        {
            (true, true) => "BoldItalic",
            (true, false) => "Bold",
            (false, true) => "Italic",
            _ => "Regular"
        };

        return new FontResolverInfo($"{baseName}#{style}");
    }
}

