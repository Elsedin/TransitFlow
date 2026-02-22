using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Models;

namespace TransitFlow.API.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users { get; set; }
    public DbSet<Administrator> Administrators { get; set; }
    public DbSet<TransportLine> TransportLines { get; set; }
    public DbSet<Models.Route> Routes { get; set; }
    public DbSet<Station> Stations { get; set; }
    public DbSet<RouteStation> RouteStations { get; set; }
    public DbSet<Vehicle> Vehicles { get; set; }
    public DbSet<Schedule> Schedules { get; set; }
    public DbSet<Ticket> Tickets { get; set; }
    public DbSet<TicketType> TicketTypes { get; set; }
    public DbSet<Transaction> Transactions { get; set; }
    public DbSet<Subscription> Subscriptions { get; set; }
    public DbSet<Zone> Zones { get; set; }
    public DbSet<TicketPrice> TicketPrices { get; set; }
    public DbSet<Notification> Notifications { get; set; }
    public DbSet<City> Cities { get; set; }
    public DbSet<Country> Countries { get; set; }
    public DbSet<TransportType> TransportTypes { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasIndex(e => e.Username).IsUnique();
            entity.HasIndex(e => e.Email).IsUnique();
        });

        modelBuilder.Entity<Administrator>(entity =>
        {
            entity.HasIndex(e => e.Username).IsUnique();
            entity.HasIndex(e => e.Email).IsUnique();
        });

        modelBuilder.Entity<TransportLine>(entity =>
        {
            entity.HasIndex(e => e.LineNumber).IsUnique();
            entity.HasOne(e => e.TransportType)
                .WithMany(t => t.TransportLines)
                .HasForeignKey(e => e.TransportTypeId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Models.Route>(entity =>
        {
            entity.HasOne(e => e.TransportLine)
                .WithMany(t => t.Routes)
                .HasForeignKey(e => e.TransportLineId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<RouteStation>(entity =>
        {
            entity.HasOne(e => e.Route)
                .WithMany(r => r.RouteStations)
                .HasForeignKey(e => e.RouteId)
                .OnDelete(DeleteBehavior.Cascade);
            
            entity.HasOne(e => e.Station)
                .WithMany(s => s.RouteStations)
                .HasForeignKey(e => e.StationId)
                .OnDelete(DeleteBehavior.Restrict);
            
            entity.HasIndex(e => new { e.RouteId, e.Order }).IsUnique();
        });

        modelBuilder.Entity<Station>(entity =>
        {
            entity.HasOne(e => e.City)
                .WithMany(c => c.Stations)
                .HasForeignKey(e => e.CityId)
                .OnDelete(DeleteBehavior.Restrict);
            
            entity.HasOne(e => e.Zone)
                .WithMany(z => z.Stations)
                .HasForeignKey(e => e.ZoneId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Vehicle>(entity =>
        {
            entity.HasIndex(e => e.LicensePlate).IsUnique();
            entity.HasOne(e => e.TransportType)
                .WithMany(t => t.Vehicles)
                .HasForeignKey(e => e.TransportTypeId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Schedule>(entity =>
        {
            entity.HasOne(e => e.Route)
                .WithMany(r => r.Schedules)
                .HasForeignKey(e => e.RouteId)
                .OnDelete(DeleteBehavior.Restrict);
            
            entity.HasOne(e => e.Vehicle)
                .WithMany(v => v.Schedules)
                .HasForeignKey(e => e.VehicleId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Ticket>(entity =>
        {
            entity.HasIndex(e => e.TicketNumber).IsUnique();
            entity.HasOne(e => e.User)
                .WithMany(u => u.Tickets)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Restrict);
            
            entity.HasOne(e => e.TicketType)
                .WithMany(t => t.Tickets)
                .HasForeignKey(e => e.TicketTypeId)
                .OnDelete(DeleteBehavior.Restrict);
            
            entity.HasOne(e => e.Route)
                .WithMany()
                .HasForeignKey(e => e.RouteId)
                .OnDelete(DeleteBehavior.SetNull);
            
            entity.HasOne(e => e.Zone)
                .WithMany(z => z.Tickets)
                .HasForeignKey(e => e.ZoneId)
                .OnDelete(DeleteBehavior.Restrict);
            
            entity.HasOne(e => e.Transaction)
                .WithMany(t => t.Tickets)
                .HasForeignKey(e => e.TransactionId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<TicketPrice>(entity =>
        {
            entity.HasOne(e => e.TicketType)
                .WithMany(t => t.TicketPrices)
                .HasForeignKey(e => e.TicketTypeId)
                .OnDelete(DeleteBehavior.Restrict);
            
            entity.HasOne(e => e.Zone)
                .WithMany(z => z.TicketPrices)
                .HasForeignKey(e => e.ZoneId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Transaction>(entity =>
        {
            entity.HasIndex(e => e.TransactionNumber).IsUnique();
            entity.HasOne(e => e.User)
                .WithMany(u => u.Transactions)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Subscription>(entity =>
        {
            entity.HasOne(e => e.User)
                .WithMany(u => u.Subscriptions)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Restrict);
            
            entity.HasOne(e => e.Transaction)
                .WithMany()
                .HasForeignKey(e => e.TransactionId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<City>(entity =>
        {
            entity.HasOne(e => e.Country)
                .WithMany(c => c.Cities)
                .HasForeignKey(e => e.CountryId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
