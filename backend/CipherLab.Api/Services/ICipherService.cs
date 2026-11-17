using CipherLab.Api.Models;

namespace CipherLab.Api.Services;

public interface ICipherService
{
    CipherResponseDto Process(CipherRequestDto request);
    string CaesarEncrypt(string text, int shift);
    string CaesarDecrypt(string text, int shift);
    string RailFenceEncrypt(string text, int rails);
    string RailFenceDecrypt(string text, int rails);
}
