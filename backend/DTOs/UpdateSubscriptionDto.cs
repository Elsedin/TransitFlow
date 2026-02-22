using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class UpdateSubscriptionDto
{
    [Required]
    [MaxLength(100)]
    public string PackageName { get; set; } = string.Empty;
    
    [Required]
    [Range(0.01, double.MaxValue, ErrorMessage = "Price must be greater than 0")]
    public decimal Price { get; set; }
    
    [Required]
    public DateTime StartDate { get; set; }
    
    [Required]
    public DateTime EndDate { get; set; }
    
    [Required]
    [MaxLength(50)]
    public string Status { get; set; } = string.Empty;
    
    public int? TransactionId { get; set; }
}
