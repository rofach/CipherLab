namespace CipherLab.Api.Models;

public class CipherResponseDto
{
    public string ResultText { get; set; } = string.Empty;
    public string IntermediateText { get; set; } = string.Empty;
    public string Operation { get; set; } = string.Empty;
    public int Shift { get; set; }
    public int Rails { get; set; }
    public List<CaesarStepDto> CaesarSteps { get; set; } = [];
}

public class CaesarStepDto
{
    public int Index { get; set; }
    public string InputChar { get; set; } = string.Empty;
    public string OutputChar { get; set; } = string.Empty;
    public string Formula { get; set; } = string.Empty;
}
