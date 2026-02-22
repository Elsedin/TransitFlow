using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(LoginRequest request);
    string GenerateJwtToken(string username);
}
