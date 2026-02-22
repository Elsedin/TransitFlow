using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(LoginRequest request);
    Task<LoginResponse?> UserLoginAsync(LoginRequest request);
    Task<RegisterResponse?> RegisterAsync(RegisterRequest request);
    string GenerateJwtToken(string username);
}
