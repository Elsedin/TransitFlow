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

        if (!context.Stations.Any())
        {
            var city = await context.Cities.FirstAsync();
            var zone1 = await context.Zones.FirstAsync(z => z.Name == "Zona 1");
            var zone2 = await context.Zones.FirstAsync(z => z.Name == "Zona 2");
            var zone3 = await context.Zones.FirstAsync(z => z.Name == "Zona 3");

            var stations = new[]
            {
                new Station { Name = "Baščaršija", Address = "Baščaršija, Sarajevo", Latitude = 43.860075073069034m, Longitude = 18.431344420671195m, CityId = city.Id, ZoneId = zone1.Id, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Station { Name = "Skenderija", Address = "Skenderija, Sarajevo", Latitude = 43.856433221373464m, Longitude = 18.413750840407392m, CityId = city.Id, ZoneId = zone1.Id, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Station { Name = "Otoka", Address = "Otoka, Sarajevo", Latitude = 43.84924945595444m, Longitude = 18.36742307757195m, CityId = city.Id, ZoneId = zone2.Id, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Station { Name = "Ilidža", Address = "Ilidža, Sarajevo", Latitude = 43.836110566046635m, Longitude = 18.300459863067246m, CityId = city.Id, ZoneId = zone3.Id, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Station { Name = "Dobrinja", Address = "Dobrinja, Sarajevo", Latitude = 43.82806631216855m, Longitude = 18.350504738228672m, CityId = city.Id, ZoneId = zone3.Id, IsActive = true, CreatedAt = DateTime.UtcNow }
            };

            context.Stations.AddRange(stations);
            await context.SaveChangesAsync();
        }

        if (!context.TransportLines.Any())
        {
            var busType = await context.TransportTypes.FirstAsync(t => t.Name == "Autobus");
            
            var transportLine = new TransportLine
            {
                LineNumber = "1",
                Name = "Baščaršija - Ilidža",
                TransportTypeId = busType.Id,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            context.TransportLines.Add(transportLine);
            await context.SaveChangesAsync();
        }

        if (!context.Routes.Any())
        {
            var transportLine = await context.TransportLines.FirstAsync();
            
            var routes = new[]
            {
                new Models.Route
                {
                    TransportLineId = transportLine.Id,
                    Origin = "Baščaršija",
                    Destination = "Ilidža",
                    Distance = 12.5m,
                    EstimatedDurationMinutes = 40,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Models.Route
                {
                    TransportLineId = transportLine.Id,
                    Origin = "Ilidža",
                    Destination = "Baščaršija",
                    Distance = 12.5m,
                    EstimatedDurationMinutes = 40,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                }
            };

            context.Routes.AddRange(routes);
            await context.SaveChangesAsync();
        }

        if (!context.RouteStations.Any())
        {
            var route1 = await context.Routes.FirstAsync(r => r.Origin == "Baščaršija");
            var route2 = await context.Routes.FirstAsync(r => r.Origin == "Ilidža");
            
            var bascarsija = await context.Stations.FirstAsync(s => s.Name == "Baščaršija");
            var skenderija = await context.Stations.FirstAsync(s => s.Name == "Skenderija");
            var otoka = await context.Stations.FirstAsync(s => s.Name == "Otoka");
            var ilidza = await context.Stations.FirstAsync(s => s.Name == "Ilidža");

            var routeStations = new[]
            {
                new RouteStation { RouteId = route1.Id, StationId = bascarsija.Id, Order = 1, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route1.Id, StationId = skenderija.Id, Order = 2, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route1.Id, StationId = otoka.Id, Order = 3, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route1.Id, StationId = ilidza.Id, Order = 4, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route2.Id, StationId = ilidza.Id, Order = 1, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route2.Id, StationId = otoka.Id, Order = 2, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route2.Id, StationId = skenderija.Id, Order = 3, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route2.Id, StationId = bascarsija.Id, Order = 4, CreatedAt = DateTime.UtcNow }
            };

            context.RouteStations.AddRange(routeStations);
            await context.SaveChangesAsync();
        }
    }
}
