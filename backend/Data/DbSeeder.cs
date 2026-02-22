using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Models;
using TransitFlow.API.Services;

namespace TransitFlow.API.Data;

public static class DbSeeder
{
    public static async Task SeedAsync(ApplicationDbContext context)
    {
        var existingAdmin = await context.Administrators
            .FirstOrDefaultAsync(a => a.Username == "admin");
        
        if (existingAdmin == null)
        {
            var passwordHash = AuthService.HashPassword("admin123");
            Console.WriteLine($"[DbSeeder] Creating admin user with password hash: {passwordHash}");
            
            var admin = new Administrator
            {
                Username = "admin",
                Email = "admin@transitflow.com",
                PasswordHash = passwordHash,
                FirstName = "Admin",
                LastName = "User",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            context.Administrators.Add(admin);
            await context.SaveChangesAsync();
            Console.WriteLine("[DbSeeder] Admin user created successfully!");
        }
        else
        {
            Console.WriteLine($"[DbSeeder] Admin user already exists. Password hash: {existingAdmin.PasswordHash}");
        }

        var existingDesktop = await context.Administrators
            .FirstOrDefaultAsync(a => a.Username == "desktop");
        
        if (existingDesktop == null)
        {
            var desktopPasswordHash = AuthService.HashPassword("test");
            
            var desktop = new Administrator
            {
                Username = "desktop",
                Email = "desktop@transitflow.com",
                PasswordHash = desktopPasswordHash,
                FirstName = "Desktop",
                LastName = "User",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            context.Administrators.Add(desktop);
            await context.SaveChangesAsync();
            Console.WriteLine("[DbSeeder] Desktop user created successfully!");
        }

        if (!context.Countries.Any())
        {
            var country = new Country
            {
                Name = "Bosna i Hercegovina",
                Code = "BIH",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            context.Countries.Add(country);
            await context.SaveChangesAsync();
        }

        if (!context.Cities.Any())
        {
            var country = await context.Countries.FirstAsync();
            var city = new City
            {
                Name = "Sarajevo",
                PostalCode = "71000",
                CountryId = country.Id,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            context.Cities.Add(city);
            await context.SaveChangesAsync();
        }

        if (!context.TransportTypes.Any())
        {
            var transportTypes = new[]
            {
                new TransportType { Name = "Autobus", Description = "Autobusni prevoz", IsActive = true, CreatedAt = DateTime.UtcNow },
                new TransportType { Name = "Tramvaj", Description = "Tramvajski prevoz", IsActive = true, CreatedAt = DateTime.UtcNow },
                new TransportType { Name = "Trolejbus", Description = "Trolejbuski prevoz", IsActive = true, CreatedAt = DateTime.UtcNow }
            };

            context.TransportTypes.AddRange(transportTypes);
            await context.SaveChangesAsync();
        }

        if (!context.Zones.Any())
        {
            var zones = new[]
            {
                new Zone { Name = "Zona 1", Description = "Centar grada", IsActive = true, CreatedAt = DateTime.UtcNow },
                new Zone { Name = "Zona 2", Description = "Prva zona", IsActive = true, CreatedAt = DateTime.UtcNow },
                new Zone { Name = "Zona 3", Description = "Druga zona", IsActive = true, CreatedAt = DateTime.UtcNow }
            };

            context.Zones.AddRange(zones);
            await context.SaveChangesAsync();
        }

        if (!context.TicketTypes.Any())
        {
            var ticketTypes = new[]
            {
                new TicketType { Name = "Jednokratna", Description = "Karta za jedan put", ValidityDays = 0, IsActive = true, CreatedAt = DateTime.UtcNow },
                new TicketType { Name = "Dnevna", Description = "Karta za jedan dan", ValidityDays = 1, IsActive = true, CreatedAt = DateTime.UtcNow },
                new TicketType { Name = "Mjesečna", Description = "Karta za jedan mjesec", ValidityDays = 30, IsActive = true, CreatedAt = DateTime.UtcNow },
                new TicketType { Name = "Godišnja", Description = "Karta za jednu godinu", ValidityDays = 365, IsActive = true, CreatedAt = DateTime.UtcNow }
            };

            context.TicketTypes.AddRange(ticketTypes);
            await context.SaveChangesAsync();
        }
    }
}
