namespace TransitFlow.API.DTOs;

public class CreatePaymentRequest
{
    public decimal Amount { get; set; }
    public string? Currency { get; set; } = "bam";
}
