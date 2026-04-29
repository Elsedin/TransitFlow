using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using TransitFlow.API.Models;
using TransitFlow.API.Services;

namespace TransitFlow.API.Data;

public static class DbSeeder
{
    public static async Task SeedAsync(ApplicationDbContext context, ILogger logger)
    {
        var existingAdmin = await context.Administrators
            .FirstOrDefaultAsync(a => a.Username == "admin");
        
        if (existingAdmin == null)
        {
            var passwordHash = AuthService.HashPassword("admin123");
            logger.LogInformation("Creating default admin user");
            
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
            logger.LogInformation("Default admin user created");
        }
        else
        {
            logger.LogInformation("Default admin user already exists");
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
            logger.LogInformation("Desktop admin user created");
        }

        var existingMobile = await context.Users
            .FirstOrDefaultAsync(u => u.Username == "mobile");
        
        if (existingMobile == null)
        {
            var mobilePasswordHash = AuthService.HashPassword("test");
            
            var mobile = new User
            {
                Username = "mobile",
                Email = "mobile@transitflow.com",
                PasswordHash = mobilePasswordHash,
                FirstName = "Mobile",
                LastName = "User",
                PhoneNumber = "+38761123456",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            context.Users.Add(mobile);
            await context.SaveChangesAsync();
            logger.LogInformation("Mobile demo user created");
        }

        if (context.Users.Count() < 3)
        {
            var testUser1PasswordHash = AuthService.HashPassword("test");
            var testUser2PasswordHash = AuthService.HashPassword("test");
            
            var testUsers = new[]
            {
                new User
                {
                    Username = "testuser1",
                    Email = "testuser1@transitflow.com",
                    PasswordHash = testUser1PasswordHash,
                    FirstName = "Test",
                    LastName = "User 1",
                    PhoneNumber = "+38761234567",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-30)
                },
                new User
                {
                    Username = "testuser2",
                    Email = "testuser2@transitflow.com",
                    PasswordHash = testUser2PasswordHash,
                    FirstName = "Test",
                    LastName = "User 2",
                    PhoneNumber = "+38761234568",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-20)
                }
            };

            context.Users.AddRange(testUsers);
            await context.SaveChangesAsync();
            logger.LogInformation("Test users created");
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
                new TicketType { Name = "Jednokratna", Description = "Karta za jedan put", ValidityDays = 1, IsActive = true, CreatedAt = DateTime.UtcNow },
                new TicketType { Name = "Dnevna", Description = "Karta za jedan dan", ValidityDays = 1, IsActive = true, CreatedAt = DateTime.UtcNow },
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
                new Station { Name = "Dobrinja", Address = "Dobrinja, Sarajevo", Latitude = 43.82806631216855m, Longitude = 18.350504738228672m, CityId = city.Id, ZoneId = zone3.Id, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Station { Name = "Mostarsko raskršče", Address = "Mostarsko raskršče, Sarajevo", Latitude = 43.84838432276594m, Longitude = 18.2422263332669m, CityId = city.Id, ZoneId = zone3.Id, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Station { Name = "Hadžići", Address = "Hadžići, Sarajevo", Latitude = 43.82227618968214m, Longitude = 18.203387972958154m, CityId = city.Id, ZoneId = zone3.Id, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Station { Name = "Pazarić", Address = "Pazarić, Sarajevo", Latitude = 43.787442499952164m, Longitude = 18.149734817415403m, CityId = city.Id, ZoneId = zone3.Id, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Station { Name = "Tarčin", Address = "Tarčin, Sarajevo", Latitude = 43.79516340990493m, Longitude = 18.095345775889804m, CityId = city.Id, ZoneId = zone3.Id, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Station { Name = "Vukovići", Address = "Vukovići, Sarajevo", Latitude = 43.75394733701734m, Longitude = 18.050252169212314m, CityId = city.Id, ZoneId = zone3.Id, IsActive = true, CreatedAt = DateTime.UtcNow }
            };

            context.Stations.AddRange(stations);
            await context.SaveChangesAsync();
        }

        if (!context.TransportLines.Any())
        {
            var busType = await context.TransportTypes.FirstAsync(t => t.Name == "Autobus");
            var tramType = await context.TransportTypes.FirstAsync(t => t.Name == "Tramvaj");
            
            var transportLines = new[]
            {
                new TransportLine
                {
                    LineNumber = "1",
                    Name = "Baščaršija - Ilidža",
                    TransportTypeId = tramType.Id,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new TransportLine
                {
                    LineNumber = "33",
                    Name = "Ilidža - Vukovići",
                    TransportTypeId = busType.Id,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                }
            };

            context.TransportLines.AddRange(transportLines);
            await context.SaveChangesAsync();
        }

        if (!context.Routes.Any())
        {
            var transportLine1 = await context.TransportLines.FirstAsync(tl => tl.LineNumber == "1");
            var transportLine33 = await context.TransportLines.FirstAsync(tl => tl.LineNumber == "33");
            
            var routes = new[]
            {
                new Models.Route
                {
                    TransportLineId = transportLine1.Id,
                    Origin = "Baščaršija",
                    Destination = "Ilidža",
                    Distance = 12.5m,
                    EstimatedDurationMinutes = 40,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Models.Route
                {
                    TransportLineId = transportLine1.Id,
                    Origin = "Ilidža",
                    Destination = "Baščaršija",
                    Distance = 12.5m,
                    EstimatedDurationMinutes = 40,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Models.Route
                {
                    TransportLineId = transportLine33.Id,
                    Origin = "Ilidža",
                    Destination = "Vukovići",
                    Distance = 25.0m,
                    EstimatedDurationMinutes = 60,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Models.Route
                {
                    TransportLineId = transportLine33.Id,
                    Origin = "Vukovići",
                    Destination = "Ilidža",
                    Distance = 25.0m,
                    EstimatedDurationMinutes = 60,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                }
            };

            context.Routes.AddRange(routes);
            await context.SaveChangesAsync();
        }

        if (!context.RouteStations.Any())
        {
            var route1 = await context.Routes.FirstAsync(r => r.Origin == "Baščaršija" && r.Destination == "Ilidža");
            var route2 = await context.Routes.FirstAsync(r => r.Origin == "Ilidža" && r.Destination == "Baščaršija");
            var route3 = await context.Routes.FirstAsync(r => r.Origin == "Ilidža" && r.Destination == "Vukovići");
            var route4 = await context.Routes.FirstAsync(r => r.Origin == "Vukovići" && r.Destination == "Ilidža");
            
            var bascarsija = await context.Stations.FirstAsync(s => s.Name == "Baščaršija");
            var skenderija = await context.Stations.FirstAsync(s => s.Name == "Skenderija");
            var otoka = await context.Stations.FirstAsync(s => s.Name == "Otoka");
            var ilidza = await context.Stations.FirstAsync(s => s.Name == "Ilidža");
            var mostarsko = await context.Stations.FirstAsync(s => s.Name == "Mostarsko raskršče");
            var hadzici = await context.Stations.FirstAsync(s => s.Name == "Hadžići");
            var pazaric = await context.Stations.FirstAsync(s => s.Name == "Pazarić");
            var tarcin = await context.Stations.FirstAsync(s => s.Name == "Tarčin");
            var vukovici = await context.Stations.FirstAsync(s => s.Name == "Vukovići");

            var routeStations = new[]
            {
                new RouteStation { RouteId = route1.Id, StationId = bascarsija.Id, Order = 1, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route1.Id, StationId = skenderija.Id, Order = 2, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route1.Id, StationId = otoka.Id, Order = 3, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route1.Id, StationId = ilidza.Id, Order = 4, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route2.Id, StationId = ilidza.Id, Order = 1, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route2.Id, StationId = otoka.Id, Order = 2, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route2.Id, StationId = skenderija.Id, Order = 3, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route2.Id, StationId = bascarsija.Id, Order = 4, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route3.Id, StationId = ilidza.Id, Order = 1, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route3.Id, StationId = mostarsko.Id, Order = 2, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route3.Id, StationId = hadzici.Id, Order = 3, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route3.Id, StationId = pazaric.Id, Order = 4, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route3.Id, StationId = tarcin.Id, Order = 5, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route3.Id, StationId = vukovici.Id, Order = 6, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route4.Id, StationId = vukovici.Id, Order = 1, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route4.Id, StationId = tarcin.Id, Order = 2, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route4.Id, StationId = pazaric.Id, Order = 3, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route4.Id, StationId = hadzici.Id, Order = 4, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route4.Id, StationId = mostarsko.Id, Order = 5, CreatedAt = DateTime.UtcNow },
                new RouteStation { RouteId = route4.Id, StationId = ilidza.Id, Order = 6, CreatedAt = DateTime.UtcNow }
            };

            context.RouteStations.AddRange(routeStations);
            await context.SaveChangesAsync();
        }

        if (!context.Vehicles.Any())
        {
            var busType = await context.TransportTypes.FirstAsync(t => t.Name == "Autobus");
            
            var vehicles = new[]
            {
                new Vehicle
                {
                    LicensePlate = "SA-123-AB",
                    Make = "Mercedes",
                    Model = "Citaro",
                    Year = 2020,
                    Capacity = 80,
                    TransportTypeId = busType.Id,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Vehicle
                {
                    LicensePlate = "SA-456-CD",
                    Make = "Mercedes",
                    Model = "Citaro",
                    Year = 2021,
                    Capacity = 80,
                    TransportTypeId = busType.Id,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Vehicle
                {
                    LicensePlate = "SA-789-EF",
                    Make = "Iveco",
                    Model = "Urbanway",
                    Year = 2019,
                    Capacity = 70,
                    TransportTypeId = busType.Id,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                }
            };

            context.Vehicles.AddRange(vehicles);
            await context.SaveChangesAsync();
        }

        if (!context.TicketPrices.Any())
        {
            var jednokratna = await context.TicketTypes.FirstAsync(t => t.Name == "Jednokratna");
            var dnevna = await context.TicketTypes.FirstAsync(t => t.Name == "Dnevna");
            
            var zone1 = await context.Zones.FirstAsync(z => z.Name == "Zona 1");
            var zone2 = await context.Zones.FirstAsync(z => z.Name == "Zona 2");
            var zone3 = await context.Zones.FirstAsync(z => z.Name == "Zona 3");

            var now = DateTime.UtcNow;
            var ticketPrices = new[]
            {
                new TicketPrice { TicketTypeId = jednokratna.Id, ZoneId = zone1.Id, Price = 1.50m, ValidFrom = now, ValidTo = null, IsActive = true, CreatedAt = now },
                new TicketPrice { TicketTypeId = jednokratna.Id, ZoneId = zone2.Id, Price = 2.00m, ValidFrom = now, ValidTo = null, IsActive = true, CreatedAt = now },
                new TicketPrice { TicketTypeId = jednokratna.Id, ZoneId = zone3.Id, Price = 2.50m, ValidFrom = now, ValidTo = null, IsActive = true, CreatedAt = now },
                new TicketPrice { TicketTypeId = dnevna.Id, ZoneId = zone1.Id, Price = 3.00m, ValidFrom = now, ValidTo = null, IsActive = true, CreatedAt = now },
                new TicketPrice { TicketTypeId = dnevna.Id, ZoneId = zone2.Id, Price = 4.00m, ValidFrom = now, ValidTo = null, IsActive = true, CreatedAt = now },
                new TicketPrice { TicketTypeId = dnevna.Id, ZoneId = zone3.Id, Price = 5.00m, ValidFrom = now, ValidTo = null, IsActive = true, CreatedAt = now }
            };

            context.TicketPrices.AddRange(ticketPrices);
            await context.SaveChangesAsync();
        }

        if (!context.Schedules.Any())
        {
            var route1 = await context.Routes.FirstAsync(r => r.Origin == "Baščaršija" && r.Destination == "Ilidža");
            var route2 = await context.Routes.FirstAsync(r => r.Origin == "Ilidža" && r.Destination == "Baščaršija");
            var route3 = await context.Routes.FirstAsync(r => r.Origin == "Ilidža" && r.Destination == "Vukovići");
            var route4 = await context.Routes.FirstAsync(r => r.Origin == "Vukovići" && r.Destination == "Ilidža");
            var vehicle1 = await context.Vehicles.FirstAsync(v => v.LicensePlate == "SA-123-AB");
            var vehicle2 = await context.Vehicles.FirstAsync(v => v.LicensePlate == "SA-456-CD");
            var vehicle3 = await context.Vehicles.FirstAsync(v => v.LicensePlate == "SA-789-EF");

            var schedules = new[]
            {
                new Schedule { RouteId = route1.Id, VehicleId = vehicle1.Id, DepartureTime = new TimeOnly(6, 0), ArrivalTime = new TimeOnly(6, 40), DayOfWeek = DayOfWeek.Monday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route1.Id, VehicleId = vehicle1.Id, DepartureTime = new TimeOnly(7, 0), ArrivalTime = new TimeOnly(7, 40), DayOfWeek = DayOfWeek.Monday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route1.Id, VehicleId = vehicle2.Id, DepartureTime = new TimeOnly(8, 0), ArrivalTime = new TimeOnly(8, 40), DayOfWeek = DayOfWeek.Monday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route1.Id, VehicleId = vehicle1.Id, DepartureTime = new TimeOnly(9, 0), ArrivalTime = new TimeOnly(9, 40), DayOfWeek = DayOfWeek.Monday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route2.Id, VehicleId = vehicle2.Id, DepartureTime = new TimeOnly(6, 30), ArrivalTime = new TimeOnly(7, 10), DayOfWeek = DayOfWeek.Monday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route2.Id, VehicleId = vehicle1.Id, DepartureTime = new TimeOnly(7, 30), ArrivalTime = new TimeOnly(8, 10), DayOfWeek = DayOfWeek.Monday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route2.Id, VehicleId = vehicle2.Id, DepartureTime = new TimeOnly(8, 30), ArrivalTime = new TimeOnly(9, 10), DayOfWeek = DayOfWeek.Monday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route1.Id, VehicleId = vehicle1.Id, DepartureTime = new TimeOnly(6, 0), ArrivalTime = new TimeOnly(6, 40), DayOfWeek = DayOfWeek.Tuesday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route1.Id, VehicleId = vehicle1.Id, DepartureTime = new TimeOnly(7, 0), ArrivalTime = new TimeOnly(7, 40), DayOfWeek = DayOfWeek.Tuesday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route1.Id, VehicleId = vehicle2.Id, DepartureTime = new TimeOnly(8, 0), ArrivalTime = new TimeOnly(8, 40), DayOfWeek = DayOfWeek.Tuesday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route2.Id, VehicleId = vehicle2.Id, DepartureTime = new TimeOnly(6, 30), ArrivalTime = new TimeOnly(7, 10), DayOfWeek = DayOfWeek.Tuesday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route2.Id, VehicleId = vehicle1.Id, DepartureTime = new TimeOnly(7, 30), ArrivalTime = new TimeOnly(8, 10), DayOfWeek = DayOfWeek.Tuesday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route3.Id, VehicleId = vehicle3.Id, DepartureTime = new TimeOnly(5, 30), ArrivalTime = new TimeOnly(6, 30), DayOfWeek = DayOfWeek.Monday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route3.Id, VehicleId = vehicle3.Id, DepartureTime = new TimeOnly(7, 0), ArrivalTime = new TimeOnly(8, 0), DayOfWeek = DayOfWeek.Monday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route3.Id, VehicleId = vehicle3.Id, DepartureTime = new TimeOnly(8, 30), ArrivalTime = new TimeOnly(9, 30), DayOfWeek = DayOfWeek.Monday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route4.Id, VehicleId = vehicle3.Id, DepartureTime = new TimeOnly(6, 0), ArrivalTime = new TimeOnly(7, 0), DayOfWeek = DayOfWeek.Monday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route4.Id, VehicleId = vehicle3.Id, DepartureTime = new TimeOnly(7, 30), ArrivalTime = new TimeOnly(8, 30), DayOfWeek = DayOfWeek.Monday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route4.Id, VehicleId = vehicle3.Id, DepartureTime = new TimeOnly(9, 0), ArrivalTime = new TimeOnly(10, 0), DayOfWeek = DayOfWeek.Monday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route3.Id, VehicleId = vehicle3.Id, DepartureTime = new TimeOnly(5, 30), ArrivalTime = new TimeOnly(6, 30), DayOfWeek = DayOfWeek.Tuesday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route3.Id, VehicleId = vehicle3.Id, DepartureTime = new TimeOnly(7, 0), ArrivalTime = new TimeOnly(8, 0), DayOfWeek = DayOfWeek.Tuesday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route4.Id, VehicleId = vehicle3.Id, DepartureTime = new TimeOnly(6, 0), ArrivalTime = new TimeOnly(7, 0), DayOfWeek = DayOfWeek.Tuesday, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Schedule { RouteId = route4.Id, VehicleId = vehicle3.Id, DepartureTime = new TimeOnly(7, 30), ArrivalTime = new TimeOnly(8, 30), DayOfWeek = DayOfWeek.Tuesday, IsActive = true, CreatedAt = DateTime.UtcNow }
            };

            context.Schedules.AddRange(schedules);
            await context.SaveChangesAsync();
        }

        if (!context.Tickets.Any())
        {
            var mobileUser = await context.Users.FirstAsync(u => u.Username == "mobile");
            var testUser1 = await context.Users.FirstOrDefaultAsync(u => u.Username == "testuser1");
            var testUser2 = await context.Users.FirstOrDefaultAsync(u => u.Username == "testuser2");
            
            var jednokratna = await context.TicketTypes.FirstAsync(t => t.Name == "Jednokratna");
            var dnevna = await context.TicketTypes.FirstAsync(t => t.Name == "Dnevna");
            
            var zone1 = await context.Zones.FirstAsync(z => z.Name == "Zona 1");
            var zone2 = await context.Zones.FirstAsync(z => z.Name == "Zona 2");
            var zone3 = await context.Zones.FirstAsync(z => z.Name == "Zona 3");
            
            var route1 = await context.Routes.FirstAsync(r => r.Origin == "Baščaršija" && r.Destination == "Ilidža");
            var route3 = await context.Routes.FirstAsync(r => r.Origin == "Ilidža" && r.Destination == "Vukovići");
            
            var now = DateTime.UtcNow;
            var tickets = new List<Ticket>();
            
            var random = new Random();
            string GenerateTicketNumber()
            {
                var year = DateTime.UtcNow.Year;
                var number = random.Next(100000, 999999);
                return $"TKT-{year}-{number:D6}";
            }
            
            if (testUser1 != null)
            {
                var user1Tickets = new[]
                {
                    new Ticket
                    {
                        PublicId = Guid.NewGuid(),
                        TicketNumber = GenerateTicketNumber(),
                        UserId = testUser1.Id,
                        TicketTypeId = jednokratna.Id,
                        RouteId = route1.Id,
                        ZoneId = zone1.Id,
                        Price = 1.50m,
                        ValidFrom = now.AddDays(-10).Date,
                        ValidTo = now.AddDays(-10).Date.AddDays(1),
                        PurchasedAt = now.AddDays(-10),
                        IsUsed = true,
                        UsedAt = now.AddDays(-10).AddHours(8)
                    },
                    new Ticket
                    {
                        PublicId = Guid.NewGuid(),
                        TicketNumber = GenerateTicketNumber(),
                        UserId = testUser1.Id,
                        TicketTypeId = jednokratna.Id,
                        RouteId = route1.Id,
                        ZoneId = zone2.Id,
                        Price = 2.00m,
                        ValidFrom = now.AddDays(-5).Date,
                        ValidTo = now.AddDays(-5).Date.AddDays(1),
                        PurchasedAt = now.AddDays(-5),
                        IsUsed = false
                    },
                    new Ticket
                    {
                        PublicId = Guid.NewGuid(),
                        TicketNumber = GenerateTicketNumber(),
                        UserId = testUser1.Id,
                        TicketTypeId = dnevna.Id,
                        RouteId = route1.Id,
                        ZoneId = zone1.Id,
                        Price = 3.00m,
                        ValidFrom = now.AddDays(-2).Date,
                        ValidTo = now.AddDays(-1).Date,
                        PurchasedAt = now.AddDays(-2),
                        IsUsed = false
                    },
                    new Ticket
                    {
                        PublicId = Guid.NewGuid(),
                        TicketNumber = GenerateTicketNumber(),
                        UserId = testUser1.Id,
                        TicketTypeId = jednokratna.Id,
                        RouteId = route3.Id,
                        ZoneId = zone3.Id,
                        Price = 2.50m,
                        ValidFrom = now.Date,
                        ValidTo = now.Date.AddDays(1),
                        PurchasedAt = now.AddHours(-2),
                        IsUsed = false
                    },
                    new Ticket
                    {
                        PublicId = Guid.NewGuid(),
                        TicketNumber = GenerateTicketNumber(),
                        UserId = testUser1.Id,
                        TicketTypeId = jednokratna.Id,
                        RouteId = route1.Id,
                        ZoneId = zone1.Id,
                        Price = 1.50m,
                        ValidFrom = now.AddDays(-20).Date,
                        ValidTo = now.AddDays(-20).Date.AddDays(1),
                        PurchasedAt = now.AddDays(-20),
                        IsUsed = true,
                        UsedAt = now.AddDays(-20).AddHours(7)
                    }
                };
                tickets.AddRange(user1Tickets);
            }
            
            if (testUser2 != null)
            {
                var user2Tickets = new[]
                {
                    new Ticket
                    {
                        PublicId = Guid.NewGuid(),
                        TicketNumber = GenerateTicketNumber(),
                        UserId = testUser2.Id,
                        TicketTypeId = jednokratna.Id,
                        RouteId = route3.Id,
                        ZoneId = zone3.Id,
                        Price = 2.50m,
                        ValidFrom = now.AddDays(-8).Date,
                        ValidTo = now.AddDays(-8).Date.AddDays(1),
                        PurchasedAt = now.AddDays(-8),
                        IsUsed = true,
                        UsedAt = now.AddDays(-8).AddHours(9)
                    },
                    new Ticket
                    {
                        PublicId = Guid.NewGuid(),
                        TicketNumber = GenerateTicketNumber(),
                        UserId = testUser2.Id,
                        TicketTypeId = dnevna.Id,
                        RouteId = route3.Id,
                        ZoneId = zone3.Id,
                        Price = 5.00m,
                        ValidFrom = now.AddDays(-3).Date,
                        ValidTo = now.AddDays(-2).Date,
                        PurchasedAt = now.AddDays(-3),
                        IsUsed = false
                    },
                    new Ticket
                    {
                        PublicId = Guid.NewGuid(),
                        TicketNumber = GenerateTicketNumber(),
                        UserId = testUser2.Id,
                        TicketTypeId = jednokratna.Id,
                        RouteId = route1.Id,
                        ZoneId = zone2.Id,
                        Price = 2.00m,
                        ValidFrom = now.AddDays(-1).Date,
                        ValidTo = now.Date,
                        PurchasedAt = now.AddDays(-1),
                        IsUsed = false
                    },
                    new Ticket
                    {
                        PublicId = Guid.NewGuid(),
                        TicketNumber = GenerateTicketNumber(),
                        UserId = testUser2.Id,
                        TicketTypeId = jednokratna.Id,
                        RouteId = route1.Id,
                        ZoneId = zone1.Id,
                        Price = 1.50m,
                        ValidFrom = now.Date,
                        ValidTo = now.Date.AddDays(1),
                        PurchasedAt = now.AddHours(-1),
                        IsUsed = false
                    },
                    new Ticket
                    {
                        PublicId = Guid.NewGuid(),
                        TicketNumber = GenerateTicketNumber(),
                        UserId = testUser2.Id,
                        TicketTypeId = jednokratna.Id,
                        RouteId = route3.Id,
                        ZoneId = zone3.Id,
                        Price = 2.50m,
                        ValidFrom = now.AddDays(-25).Date,
                        ValidTo = now.AddDays(-25).Date.AddDays(1),
                        PurchasedAt = now.AddDays(-25),
                        IsUsed = true,
                        UsedAt = now.AddDays(-25).AddHours(10)
                    }
                };
                tickets.AddRange(user2Tickets);
            }
            
            var mobileTickets = new[]
            {
                new Ticket
                {
                    PublicId = Guid.NewGuid(),
                    TicketNumber = GenerateTicketNumber(),
                    UserId = mobileUser.Id,
                    TicketTypeId = jednokratna.Id,
                    RouteId = route1.Id,
                    ZoneId = zone1.Id,
                    Price = 1.50m,
                    ValidFrom = now.AddDays(-7).Date,
                    ValidTo = now.AddDays(-7).Date.AddDays(1),
                    PurchasedAt = now.AddDays(-7),
                    IsUsed = true,
                    UsedAt = now.AddDays(-7).AddHours(8)
                },
                new Ticket
                {
                    PublicId = Guid.NewGuid(),
                    TicketNumber = GenerateTicketNumber(),
                    UserId = mobileUser.Id,
                    TicketTypeId = dnevna.Id,
                    RouteId = route1.Id,
                    ZoneId = zone1.Id,
                    Price = 3.00m,
                    ValidFrom = now.AddDays(-4).Date,
                    ValidTo = now.AddDays(-3).Date,
                    PurchasedAt = now.AddDays(-4),
                    IsUsed = false
                },
                new Ticket
                {
                    PublicId = Guid.NewGuid(),
                    TicketNumber = GenerateTicketNumber(),
                    UserId = mobileUser.Id,
                    TicketTypeId = jednokratna.Id,
                    RouteId = route3.Id,
                    ZoneId = zone3.Id,
                    Price = 2.50m,
                    ValidFrom = now.AddDays(-1).Date,
                    ValidTo = now.Date,
                    PurchasedAt = now.AddDays(-1),
                    IsUsed = false
                },
                new Ticket
                {
                    PublicId = Guid.NewGuid(),
                    TicketNumber = GenerateTicketNumber(),
                    UserId = mobileUser.Id,
                    TicketTypeId = jednokratna.Id,
                    RouteId = route1.Id,
                    ZoneId = zone2.Id,
                    Price = 2.00m,
                    ValidFrom = now.Date,
                    ValidTo = now.Date.AddDays(1),
                    PurchasedAt = now.AddHours(-3),
                    IsUsed = false
                },
                new Ticket
                {
                    PublicId = Guid.NewGuid(),
                    TicketNumber = GenerateTicketNumber(),
                    UserId = mobileUser.Id,
                    TicketTypeId = jednokratna.Id,
                    RouteId = route3.Id,
                    ZoneId = zone3.Id,
                    Price = 2.50m,
                    ValidFrom = now.AddDays(-15).Date,
                    ValidTo = now.AddDays(-15).Date.AddDays(1),
                    PurchasedAt = now.AddDays(-15),
                    IsUsed = true,
                    UsedAt = now.AddDays(-15).AddHours(6)
                }
            };
            tickets.AddRange(mobileTickets);

            foreach (var ticket in tickets)
            {
                if (ticket.TransactionId == null)
                {
                    var txn = new Models.Transaction
                    {
                        TransactionNumber = $"SEED-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString()[..8].ToUpperInvariant()}",
                        UserId = ticket.UserId,
                        Amount = ticket.Price,
                        PaymentMethod = "Seed",
                        Status = "completed",
                        CreatedAt = ticket.PurchasedAt,
                        CompletedAt = ticket.PurchasedAt,
                        Notes = "Seeded transaction for testing"
                    };
                    context.Transactions.Add(txn);
                    await context.SaveChangesAsync();
                    ticket.TransactionId = txn.Id;
                }
            }

            context.Tickets.AddRange(tickets);
            await context.SaveChangesAsync();
            logger.LogInformation("Test tickets created ({Count})", tickets.Count);
        }

        if (!context.Notifications.Any())
        {
            var activeUsers = await context.Users
                .Where(u => u.IsActive)
                .ToListAsync();

            var welcomeNotifications = activeUsers.Select(user => new Notification
            {
                UserId = user.Id,
                Title = "Dobrodošli u TransitFlow",
                Message = "Dobrodošli u TransitFlow aplikaciju! Ovdje možete kupovati karte, pregledati vozne redove i pratiti svoje putovanja. Uživajte u vožnji!",
                Type = "system",
                IsRead = false,
                CreatedAt = DateTime.UtcNow.AddDays(-5),
                IsActive = true
            }).ToList();

            context.Notifications.AddRange(welcomeNotifications);
            await context.SaveChangesAsync();
            logger.LogInformation("Welcome notifications created ({Count})", welcomeNotifications.Count);
        }

        if (!context.SubscriptionPackages.Any())
        {
            var now = DateTime.UtcNow;
            var packages = new[]
            {
                new SubscriptionPackage { Key = "monthly_zone1", DisplayName = "Mjesečna (Zona 1)", DurationDays = 30, Price = 45.00m, MaxZoneId = 1, IsActive = true, CreatedAt = now },
                new SubscriptionPackage { Key = "monthly_zone2", DisplayName = "Mjesečna (Zona 1-2)", DurationDays = 30, Price = 55.00m, MaxZoneId = 2, IsActive = true, CreatedAt = now },
                new SubscriptionPackage { Key = "monthly_zone3", DisplayName = "Mjesečna (Zona 1-3)", DurationDays = 30, Price = 65.00m, MaxZoneId = 3, IsActive = true, CreatedAt = now },
                new SubscriptionPackage { Key = "annual_zone1", DisplayName = "Godišnja (Zona 1)", DurationDays = 365, Price = 450.00m, MaxZoneId = 1, IsActive = true, CreatedAt = now },
                new SubscriptionPackage { Key = "annual_zone2", DisplayName = "Godišnja (Zona 1-2)", DurationDays = 365, Price = 550.00m, MaxZoneId = 2, IsActive = true, CreatedAt = now },
                new SubscriptionPackage { Key = "annual_zone3", DisplayName = "Godišnja (Zona 1-3)", DurationDays = 365, Price = 650.00m, MaxZoneId = 3, IsActive = true, CreatedAt = now },
                new SubscriptionPackage { Key = "student_monthly_zone1", DisplayName = "Studentska mjesečna (Zona 1)", DurationDays = 30, Price = 30.00m, MaxZoneId = 1, IsActive = true, CreatedAt = now },
                new SubscriptionPackage { Key = "student_monthly_zone2", DisplayName = "Studentska mjesečna (Zona 1-2)", DurationDays = 30, Price = 40.00m, MaxZoneId = 2, IsActive = true, CreatedAt = now },
                new SubscriptionPackage { Key = "student_monthly_zone3", DisplayName = "Studentska mjesečna (Zona 1-3)", DurationDays = 30, Price = 50.00m, MaxZoneId = 3, IsActive = true, CreatedAt = now }
            };

            context.SubscriptionPackages.AddRange(packages);
            await context.SaveChangesAsync();
        }
    }
}
