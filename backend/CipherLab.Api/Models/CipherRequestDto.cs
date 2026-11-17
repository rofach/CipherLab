using System.ComponentModel.DataAnnotations;

namespace CipherLab.Api.Models;

public class CipherRequestDto
{
    [Required(AllowEmptyStrings = true, ErrorMessage = "Текст є обов'язковим.")]
    [MinLength(1, ErrorMessage = "Текст не може бути порожнім.")]
    public string Text { get; set; } = string.Empty;

    [Required(ErrorMessage = "Необхідно вказати операцію (Encrypt або Decrypt).")]
    public CipherOperation Operation { get; set; }

    [Required(ErrorMessage = "Зсув Цезаря k є обов'язковим.")]
    public int Shift { get; set; }

    [Range(2, 100, ErrorMessage = "Кількість рейок N повинна бути від 2 до 100.")]
    public int Rails { get; set; }
}
