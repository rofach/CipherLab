using CipherLab.Api.Models;
using CipherLab.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace CipherLab.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CipherController : ControllerBase
{
    private readonly ICipherService _cipherService;

    public CipherController(ICipherService cipherService)
    {
        _cipherService = cipherService;
    }

    [HttpPost("process")]
    [ProducesResponseType(typeof(CipherResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public ActionResult<CipherResponseDto> Process([FromBody] CipherRequestDto request)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        try
        {
            var response = _cipherService.Process(request);
            return Ok(response);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new ProblemDetails
            {
                Title = ex.Message,
                Status = StatusCodes.Status400BadRequest
            });
        }
    }
}
