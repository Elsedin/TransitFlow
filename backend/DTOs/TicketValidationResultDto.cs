namespace TransitFlow.API.DTOs;

public class TicketValidationResultDto
{
    public bool IsValid { get; set; }
    public string Status { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public TicketDto? Ticket { get; set; }
}

