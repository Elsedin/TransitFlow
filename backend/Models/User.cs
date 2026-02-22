using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.Models;

public class User
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string Username { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(255)]
    public string Email { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(255)]
    public string PasswordHash { get; set; } = string.Empty;
    
    [MaxLength(100)]
    public string? FirstName { get; set; }
    
    [MaxLength(100)]
    public string? LastName { get; set; }
    
    [MaxLength(20)]
    public string? PhoneNumber { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? LastLoginAt { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    public virtual ICollection<Ticket> Tickets { get; set; } = new List<Ticket>();
    
    public virtual ICollection<Subscription> Subscriptions { get; set; } = new List<Subscription>();
    
    public virtual ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
}
