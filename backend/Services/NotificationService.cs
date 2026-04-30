using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using TransitFlow.API.Models;
using TransitFlow.API.Services;

namespace TransitFlow.API.Services;

public class NotificationService : INotificationService
{
    private readonly ApplicationDbContext _context;
    private readonly IRabbitMQService _rabbitMQService;

    public NotificationService(ApplicationDbContext context, IRabbitMQService rabbitMQService)
    {
        _context = context;
        _rabbitMQService = rabbitMQService;
    }

    public async Task<List<NotificationDto>> GetAllAsync(
        int? userId = null,
        string? type = null,
        bool? isRead = null,
        bool? isActive = null,
        DateTime? dateFrom = null,
        DateTime? dateTo = null,
        string? search = null)
    {
        var query = BuildFilteredQuery(userId, type, isRead, isActive, dateFrom, dateTo, search);
        var notifications = await query
            .OrderByDescending(n => n.CreatedAt)
            .ToListAsync();

        return notifications.Select(MapToDto).ToList();
    }

    public async Task<PagedResultDto<NotificationDto>> GetPagedAsync(
        int page,
        int pageSize,
        int? userId = null,
        string? type = null,
        bool? isRead = null,
        bool? isActive = null,
        DateTime? dateFrom = null,
        DateTime? dateTo = null,
        string? search = null)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 10;
        if (pageSize > 100) pageSize = 100;

        var query = BuildFilteredQuery(userId, type, isRead, isActive, dateFrom, dateTo, search);
        var total = await query.CountAsync();
        var notifications = await query
            .OrderByDescending(n => n.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResultDto<NotificationDto>
        {
            Items = notifications.Select(MapToDto).ToList(),
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<NotificationDto?> GetByIdAsync(int id)
    {
        var notification = await _context.Notifications
            .Include(n => n.User)
            .FirstOrDefaultAsync(n => n.Id == id);

        if (notification == null) return null;

        return new NotificationDto
        {
            Id = notification.Id,
            UserId = notification.UserId,
            UserEmail = notification.User?.Email,
            UserName = notification.User != null ? $"{notification.User.FirstName} {notification.User.LastName}".Trim() : null,
            Title = notification.Title,
            Message = notification.Message,
            Type = notification.Type,
            IsRead = notification.IsRead,
            CreatedAt = notification.CreatedAt,
            ReadAt = notification.ReadAt,
            IsActive = notification.IsActive,
        };
    }

    public async Task<NotificationMetricsDto> GetMetricsAsync()
    {
        var notifications = await _context.Notifications.ToListAsync();

        return new NotificationMetricsDto
        {
            TotalNotifications = notifications.Count,
            UnreadNotifications = notifications.Count(n => !n.IsRead),
            ReadNotifications = notifications.Count(n => n.IsRead),
            ActiveNotifications = notifications.Count(n => n.IsActive),
            NotificationsByType = notifications
                .GroupBy(n => n.Type)
                .ToDictionary(g => g.Key, g => g.Count()),
            BroadcastNotifications = notifications.Count(n => n.UserId == null),
            UserSpecificNotifications = notifications.Count(n => n.UserId != null),
        };
    }

    private IQueryable<Notification> BuildFilteredQuery(
        int? userId,
        string? type,
        bool? isRead,
        bool? isActive,
        DateTime? dateFrom,
        DateTime? dateTo,
        string? search)
    {
        var query = _context.Notifications
            .Include(n => n.User)
            .AsQueryable();

        if (userId.HasValue)
        {
            query = query.Where(n => n.UserId == userId.Value);
        }

        if (!string.IsNullOrWhiteSpace(type))
        {
            query = query.Where(n => n.Type == type);
        }

        if (isRead.HasValue)
        {
            query = query.Where(n => n.IsRead == isRead.Value);
        }

        if (isActive.HasValue)
        {
            query = query.Where(n => n.IsActive == isActive.Value);
        }

        if (dateFrom.HasValue)
        {
            query = query.Where(n => n.CreatedAt >= dateFrom.Value);
        }

        if (dateTo.HasValue)
        {
            query = query.Where(n => n.CreatedAt <= dateTo.Value);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var searchLower = search.ToLower();
            query = query.Where(n =>
                n.Title.ToLower().Contains(searchLower) ||
                n.Message.ToLower().Contains(searchLower) ||
                (n.User != null && n.User.Email.ToLower().Contains(searchLower)));
        }

        return query;
    }

    private static NotificationDto MapToDto(Notification n)
    {
        return new NotificationDto
        {
            Id = n.Id,
            UserId = n.UserId,
            UserEmail = n.User?.Email,
            UserName = n.User != null ? $"{n.User.FirstName} {n.User.LastName}".Trim() : null,
            Title = n.Title,
            Message = n.Message,
            Type = n.Type,
            IsRead = n.IsRead,
            CreatedAt = n.CreatedAt,
            ReadAt = n.ReadAt,
            IsActive = n.IsActive,
        };
    }

    public async Task<NotificationDto> CreateAsync(CreateNotificationDto dto)
    {
        if (dto.SendToAllUsers)
        {
            var activeUsers = await _context.Users
                .Where(u => u.IsActive)
                .ToListAsync();

            var notifications = activeUsers.Select(user => new Notification
            {
                UserId = user.Id,
                Title = dto.Title,
                Message = dto.Message,
                Type = dto.Type,
                IsRead = false,
                CreatedAt = DateTime.UtcNow,
                IsActive = true,
            }).ToList();

            _context.Notifications.AddRange(notifications);
            await _context.SaveChangesAsync();

            foreach (var notification in notifications)
            {
                var email = activeUsers.FirstOrDefault(u => u.Id == notification.UserId)?.Email;
                _rabbitMQService.PublishNotificationCreated(
                    notification.Id,
                    notification.Title,
                    notification.Message,
                    notification.Type,
                    notification.UserId,
                    email);
            }

            var firstNotification = notifications.First();
            return new NotificationDto
            {
                Id = firstNotification.Id,
                UserId = firstNotification.UserId,
                Title = firstNotification.Title,
                Message = firstNotification.Message,
                Type = firstNotification.Type,
                IsRead = firstNotification.IsRead,
                CreatedAt = firstNotification.CreatedAt,
                IsActive = firstNotification.IsActive,
            };
        }
        else
        {
            var notification = new Notification
            {
                UserId = dto.UserId,
                Title = dto.Title,
                Message = dto.Message,
                Type = dto.Type,
                IsRead = false,
                CreatedAt = DateTime.UtcNow,
                IsActive = true,
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            var email = notification.UserId.HasValue
                ? await _context.Users
                    .Where(u => u.Id == notification.UserId.Value)
                    .Select(u => u.Email)
                    .FirstOrDefaultAsync()
                : null;

            _rabbitMQService.PublishNotificationCreated(
                notification.Id,
                notification.Title,
                notification.Message,
                notification.Type,
                notification.UserId,
                email);

            var user = notification.UserId.HasValue
                ? await _context.Users.FindAsync(notification.UserId.Value)
                : null;

            return new NotificationDto
            {
                Id = notification.Id,
                UserId = notification.UserId,
                UserEmail = user?.Email,
                UserName = user != null ? $"{user.FirstName} {user.LastName}".Trim() : null,
                Title = notification.Title,
                Message = notification.Message,
                Type = notification.Type,
                IsRead = notification.IsRead,
                CreatedAt = notification.CreatedAt,
                IsActive = notification.IsActive,
            };
        }
    }

    public async Task<NotificationDto?> UpdateAsync(int id, UpdateNotificationDto dto)
    {
        var notification = await _context.Notifications
            .Include(n => n.User)
            .FirstOrDefaultAsync(n => n.Id == id);

        if (notification == null) return null;

        notification.Title = dto.Title;
        notification.Message = dto.Message;
        notification.Type = dto.Type;
        notification.IsActive = dto.IsActive;

        await _context.SaveChangesAsync();

        return new NotificationDto
        {
            Id = notification.Id,
            UserId = notification.UserId,
            UserEmail = notification.User?.Email,
            UserName = notification.User != null ? $"{notification.User.FirstName} {notification.User.LastName}".Trim() : null,
            Title = notification.Title,
            Message = notification.Message,
            Type = notification.Type,
            IsRead = notification.IsRead,
            CreatedAt = notification.CreatedAt,
            ReadAt = notification.ReadAt,
            IsActive = notification.IsActive,
        };
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var notification = await _context.Notifications.FindAsync(id);
        if (notification == null) return false;

        _context.Notifications.Remove(notification);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> MarkAsReadAsync(int id, int requestingUserId, bool isAdmin)
    {
        var notification = await _context.Notifications.FindAsync(id);
        if (notification == null) return false;

        if (!isAdmin)
        {
            if (!notification.UserId.HasValue || notification.UserId.Value != requestingUserId)
            {
                return false;
            }
        }

        notification.IsRead = true;
        notification.ReadAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return true;
    }
}
