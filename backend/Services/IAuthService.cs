using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(LoginRequest request);
    Task<LoginResponse?> UserLoginAsync(LoginRequest request);
    Task<RegisterResponse?> RegisterAsync(RegisterRequest request);
    Task ChangeUserPasswordAsync(int userId, ChangePasswordDto dto);
    Task RequestPasswordResetAsync(ForgotPasswordDto dto);
    Task ResetPasswordAsync(ResetPasswordDto dto);
    string GenerateJwtToken(string username, int? userId = null, string? role = null);
}
