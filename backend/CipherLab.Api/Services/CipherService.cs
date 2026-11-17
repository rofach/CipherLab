using System.Security.Cryptography;
using System.Text;
using CipherLab.Api.Models;

namespace CipherLab.Api.Services;

public class CipherService : ICipherService
{
    private const string UnifiedAlphabet =
        "АБВГҐДЕЄЖЗИІЇЙКЛМНОПРСТУФХЦЧШЩЬЮЯ" +
        "абвгґдеєжзиіїйклмнопрстуфхцчшщьюя" +
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
        "abcdefghijklmnopqrstuvwxyz" +
        "0123456789" +
        " .,!?-:;'\"()@#№$%&*+=/_";

    public CipherResponseDto Process(CipherRequestDto request)
    {
        if (string.IsNullOrEmpty(request.Text))
        {
            throw new ArgumentException("Текст не може бути порожнім.", nameof(request));
        }

        if (request.Rails < 2)
        {
            throw new ArgumentOutOfRangeException(nameof(request), "Кількість рейок N повинна бути >= 2.");
        }

        if (request.Operation == CipherOperation.Encrypt)
        {
            var (intermediateT1, caesarSteps) = ExecuteCaesar(request.Text, request.Shift, isEncrypt: true);
            string resultText = RailFenceEncrypt(intermediateT1, request.Rails);

            return new CipherResponseDto
            {
                ResultText = resultText,
                IntermediateText = intermediateT1,
                Operation = CipherOperation.Encrypt.ToString(),
                Shift = request.Shift,
                Rails = request.Rails,
                CaesarSteps = caesarSteps
            };
        }
        else
        {
            string intermediateT1 = RailFenceDecrypt(request.Text, request.Rails);
            var (resultText, caesarSteps) = ExecuteCaesar(intermediateT1, request.Shift, isEncrypt: false);

            return new CipherResponseDto
            {
                ResultText = resultText,
                IntermediateText = intermediateT1,
                Operation = CipherOperation.Decrypt.ToString(),
                Shift = request.Shift,
                Rails = request.Rails,
                CaesarSteps = caesarSteps
            };
        }
    }

    public string CaesarEncrypt(string text, int shift) =>
        ExecuteCaesar(text, shift, isEncrypt: true).OutputText;

    public string CaesarDecrypt(string text, int shift) =>
        ExecuteCaesar(text, shift, isEncrypt: false).OutputText;

    public string RailFenceEncrypt(string text, int rails)
    {
        if (rails < 2)
        {
            throw new ArgumentOutOfRangeException(nameof(rails), "Кількість рейок N повинна бути >= 2.");
        }

        var railBuilders = Enumerable.Range(0, rails).Select(_ => new StringBuilder()).ToArray();
        foreach (var (col, row) in GetZigzagTrajectory(text.Length, rails))
        {
            railBuilders[row].Append(text[col]);
        }

        return string.Concat(railBuilders.Select(b => b.ToString()));
    }

    public string RailFenceDecrypt(string text, int rails)
    {
        if (rails < 2)
        {
            throw new ArgumentOutOfRangeException(nameof(rails), "Кількість рейок N повинна бути >= 2.");
        }

        int length = text.Length;
        char[,] matrix = new char[rails, length];
        var trajectory = GetZigzagTrajectory(length, rails).ToList();

        foreach (var (col, row) in trajectory)
        {
            matrix[row, col] = '*';
        }

        int cipherIndex = 0;
        for (int r = 0; r < rails; r++)
        {
            for (int c = 0; c < length; c++)
            {
                if (matrix[r, c] == '*' && cipherIndex < length)
                {
                    matrix[r, c] = text[cipherIndex++];
                }
            }
        }

        var result = new StringBuilder(length);
        foreach (var (col, row) in trajectory)
        {
            result.Append(matrix[row, col]);
        }

        return result.ToString();
    }

    private static (string OutputText, List<CaesarStepDto> Steps) ExecuteCaesar(string text, int shift, bool isEncrypt)
    {
        int m = UnifiedAlphabet.Length;
        var steps = new List<CaesarStepDto>(text.Length + 1);
        var result = new StringBuilder(text.Length + 1);

        int iv;
        string payload;

        if (isEncrypt)
        {
            iv = RandomNumberGenerator.GetInt32(m);
            int prefixIdx = (((iv + shift) % m) + m) % m;
            char prefixChar = UnifiedAlphabet[prefixIdx];

            result.Append(prefixChar);
            steps.Add(new CaesarStepDto
            {
                Index = -1,
                InputChar = "—",
                OutputChar = prefixChar.ToString(),
                Formula = $"iv={iv}; ({iv} + {shift}) mod {m} = {prefixIdx}"
            });

            payload = text;
        }
        else
        {
            if (text.Length < 2)
            {
                throw new ArgumentException("Для дешифрування шифротекст повинен містити щонайменше 2 символи (префікс IV та дані).", nameof(text));
            }

            char prefixChar = text[0];
            int prefixIdx = UnifiedAlphabet.IndexOf(prefixChar);
            if (prefixIdx < 0)
            {
                throw new ArgumentException("Некоректний префіксний символ IV у шифротексті.", nameof(text));
            }

            iv = (((prefixIdx - shift) % m) + m) % m;
            steps.Add(new CaesarStepDto
            {
                Index = -1,
                InputChar = prefixChar.ToString(),
                OutputChar = "—",
                Formula = $"({prefixIdx} - {shift}) mod {m} => iv={iv}"
            });

            payload = text[1..];
        }

        for (int pos = 0; pos < payload.Length; pos++)
        {
            char ch = payload[pos];
            int curIdx = UnifiedAlphabet.IndexOf(ch);

            if (curIdx < 0)
            {
                result.Append(ch);
                steps.Add(new CaesarStepDto
                {
                    Index = pos,
                    InputChar = ch.ToString(),
                    OutputChar = ch.ToString(),
                    Formula = "Без змін"
                });
                continue;
            }

            int kPos = (((shift + iv + pos) % m) + m) % m;
            int newIdx = isEncrypt
                ? (curIdx + kPos) % m
                : (curIdx - kPos + m) % m;

            char newCh = UnifiedAlphabet[newIdx];
            result.Append(newCh);

            string formula = isEncrypt
                ? $"k_{pos}={kPos}; ({curIdx} + {kPos}) mod {m} = {newIdx}"
                : $"k_{pos}={kPos}; ({curIdx} - {kPos} + {m}) mod {m} = {newIdx}";

            steps.Add(new CaesarStepDto
            {
                Index = pos,
                InputChar = ch.ToString(),
                OutputChar = newCh.ToString(),
                Formula = formula
            });
        }

        return (result.ToString(), steps);
    }

    private static IEnumerable<(int Col, int Row)> GetZigzagTrajectory(int length, int rails)
    {
        int row = 0;
        bool dirDown = false;

        for (int col = 0; col < length; col++)
        {
            if (row == 0 || row == rails - 1)
            {
                dirDown = !dirDown;
            }

            yield return (col, row);
            row += dirDown ? 1 : -1;
        }
    }
}
