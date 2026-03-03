using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public class RecommendationService : IRecommendationService
{
    private readonly ApplicationDbContext _context;

    public RecommendationService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<RecommendedLineDto>> GetRecommendedLinesAsync(int userId, int count = 3)
    {
        var activeLines = await _context.TransportLines
            .Include(tl => tl.TransportType)
            .Include(tl => tl.Routes)
            .Where(tl => tl.IsActive)
            .ToListAsync();

        if (!activeLines.Any())
        {
            return new List<RecommendedLineDto>();
        }

        var threeMonthsAgo = DateTime.UtcNow.AddMonths(-3);

        var userTickets = await _context.Tickets
            .Include(t => t.Route)
                .ThenInclude(r => r!.TransportLine)
            .Where(t => t.UserId == userId && t.PurchasedAt >= threeMonthsAgo)
            .ToListAsync();

        var userFavorites = await _context.FavoriteLines
            .Where(f => f.UserId == userId)
            .Select(f => f.TransportLineId)
            .ToListAsync();

        var userNegativeFeedbackList = await _context.RecommendationFeedbacks
            .Where(rf => rf.UserId == userId && !rf.IsUseful)
            .Select(rf => rf.TransportLineId)
            .ToListAsync();
        var userNegativeFeedback = userNegativeFeedbackList.ToHashSet();

        var userPositiveFeedbackList = await _context.RecommendationFeedbacks
            .Where(rf => rf.UserId == userId && rf.IsUseful)
            .Select(rf => rf.TransportLineId)
            .ToListAsync();
        var userPositiveFeedback = userPositiveFeedbackList.ToHashSet();

        var userLines = new HashSet<int>();
        var userPurchasedLines = new Dictionary<int, int>();
        foreach (var ticket in userTickets)
        {
            if (ticket.Route != null)
            {
                var lineId = ticket.Route.TransportLineId;
                userLines.Add(lineId);
                if (!userPurchasedLines.ContainsKey(lineId))
                {
                    userPurchasedLines[lineId] = 0;
                }
                userPurchasedLines[lineId]++;
            }
        }
        foreach (var favoriteId in userFavorites)
        {
            userLines.Add(favoriteId);
        }

        if (!userLines.Any() && !userPositiveFeedback.Any())
        {
            var fallbackLines = activeLines
                .Where(tl => !userNegativeFeedback.Contains(tl.Id))
                .Take(count)
                .Select(tl => new RecommendedLineDto
                {
                    Id = tl.Id,
                    LineNumber = tl.LineNumber,
                    Name = tl.Name,
                    Origin = tl.Routes.FirstOrDefault()?.Origin ?? string.Empty,
                    Destination = tl.Routes.FirstOrDefault()?.Destination ?? string.Empty,
                    TransportTypeName = tl.TransportType?.Name ?? string.Empty,
                    IsActive = tl.IsActive,
                    Score = 0.0,
                    ScoreExplanation = "Početna preporuka - još nema dovoljno podataka"
                })
                .ToList();
            return fallbackLines;
        }

        var allTickets = await _context.Tickets
            .Include(t => t.Route)
                .ThenInclude(r => r!.TransportLine)
            .Where(t => t.PurchasedAt >= threeMonthsAgo && t.Route != null)
            .ToListAsync();

        var allFavorites = await _context.FavoriteLines
            .ToListAsync();

        var allPositiveFeedback = await _context.RecommendationFeedbacks
            .Where(rf => rf.IsUseful)
            .ToListAsync();

        var userLineRatings = new Dictionary<int, Dictionary<int, double>>();

        foreach (var ticket in allTickets)
        {
            if (ticket.Route == null) continue;

            var uid = ticket.UserId;
            var lid = ticket.Route.TransportLineId;

            if (!userLineRatings.ContainsKey(uid))
            {
                userLineRatings[uid] = new Dictionary<int, double>();
            }

            if (!userLineRatings[uid].ContainsKey(lid))
            {
                userLineRatings[uid][lid] = 0;
            }

            userLineRatings[uid][lid] += 1.0;
        }

        foreach (var favorite in allFavorites)
        {
            if (!userLineRatings.ContainsKey(favorite.UserId))
            {
                userLineRatings[favorite.UserId] = new Dictionary<int, double>();
            }

            if (!userLineRatings[favorite.UserId].ContainsKey(favorite.TransportLineId))
            {
                userLineRatings[favorite.UserId][favorite.TransportLineId] = 0;
            }

            userLineRatings[favorite.UserId][favorite.TransportLineId] += 3.0;
        }

        foreach (var feedback in allPositiveFeedback)
        {
            if (!userLineRatings.ContainsKey(feedback.UserId))
            {
                userLineRatings[feedback.UserId] = new Dictionary<int, double>();
            }

            if (!userLineRatings[feedback.UserId].ContainsKey(feedback.TransportLineId))
            {
                userLineRatings[feedback.UserId][feedback.TransportLineId] = 0;
            }

            userLineRatings[feedback.UserId][feedback.TransportLineId] += 2.0;
        }

        var userUserLines = userLineRatings.ToDictionary(
            kvp => kvp.Key,
            kvp => kvp.Value.Keys.ToHashSet()
        );

        var userUserRatings = userLineRatings;

        var userUserLinesSet = userLines;

        var similarities = new Dictionary<int, double>();

        foreach (var otherUser in userUserLines.Keys)
        {
            if (otherUser == userId) continue;

            var otherUserLines = userUserLines[otherUser];
            var intersection = userUserLinesSet.Intersect(otherUserLines).Count();
            var union = userUserLinesSet.Union(otherUserLines).Count();

            if (union == 0) continue;

            var jaccard = (double)intersection / union;
            if (jaccard > 0)
            {
                similarities[otherUser] = jaccard;
            }
        }

        var lineScores = new Dictionary<int, double>();

        var minScoreThreshold = similarities.Any() ? 0.3 : 0.0;

        foreach (var line in activeLines)
        {
            if (userNegativeFeedback.Contains(line.Id)) continue;

            var score = 0.0;

            if (userPurchasedLines.ContainsKey(line.Id))
            {
                score += userPurchasedLines[line.Id] * 1.0;
            }

            if (userFavorites.Contains(line.Id))
            {
                score += 5.0;
            }

            if (userPositiveFeedback.Contains(line.Id))
            {
                score += 10.0;
            }

            foreach (var similarUser in similarities.Keys)
            {
                if (!userUserRatings.ContainsKey(similarUser)) continue;
                if (!userUserRatings[similarUser].ContainsKey(line.Id)) continue;

                var similarity = similarities[similarUser];
                var rating = userUserRatings[similarUser][line.Id];
                score += similarity * rating;
            }

            if (score > 0)
            {
                lineScores[line.Id] = score;
            }
        }

        var recommendedWithScores = lineScores
            .OrderByDescending(kvp => kvp.Value)
            .Take(count)
            .ToList();

        var recommendedLineIds = recommendedWithScores.Select(kvp => kvp.Key).ToList();
        var scoreMap = recommendedWithScores.ToDictionary(kvp => kvp.Key, kvp => kvp.Value);

        if (recommendedLineIds.Count < count && similarities.Any())
        {
            var popularLines = await _context.Tickets
                .Include(t => t.Route)
                    .ThenInclude(r => r!.TransportLine)
                .Where(t => t.PurchasedAt >= threeMonthsAgo && t.Route != null)
                .GroupBy(t => t.Route!.TransportLineId)
                .Select(g => new { LineId = g.Key, Count = g.Count() })
                .OrderByDescending(x => x.Count)
                .Take(count - recommendedLineIds.Count)
                .Select(x => x.LineId)
                .ToListAsync();

            foreach (var popularLineId in popularLines)
            {
                if (!recommendedLineIds.Contains(popularLineId) && 
                    !userNegativeFeedback.Contains(popularLineId))
                {
                    recommendedLineIds.Add(popularLineId);
                    scoreMap[popularLineId] = 0.1;
                }
            }
        }

        if (recommendedLineIds.Count < count)
        {
            var additionalLines = activeLines
                .Where(tl => !userNegativeFeedback.Contains(tl.Id) && 
                            !recommendedLineIds.Contains(tl.Id))
                .Take(count - recommendedLineIds.Count)
                .Select(tl => tl.Id)
                .ToList();

            foreach (var additionalLineId in additionalLines)
            {
                recommendedLineIds.Add(additionalLineId);
                scoreMap[additionalLineId] = 0.0;
            }
        }

        var recommendedLines = activeLines
            .Where(tl => recommendedLineIds.Contains(tl.Id))
            .OrderByDescending(tl => scoreMap.ContainsKey(tl.Id) ? scoreMap[tl.Id] : 0.0)
            .Select(tl => 
            {
                var score = scoreMap.ContainsKey(tl.Id) ? scoreMap[tl.Id] : 0.0;
                var purchasedCount = userPurchasedLines.ContainsKey(tl.Id) ? userPurchasedLines[tl.Id] : 0;
                var explanation = GetScoreExplanation(tl.Id, score, userPositiveFeedback.Contains(tl.Id), userFavorites.Contains(tl.Id), purchasedCount, similarities.Count);
                
                var hasPositive = userPositiveFeedback.Contains(tl.Id);
                var hasNegative = userNegativeFeedback.Contains(tl.Id);
                
                return new RecommendedLineDto
                {
                    Id = tl.Id,
                    LineNumber = tl.LineNumber,
                    Name = tl.Name,
                    Origin = tl.Routes.FirstOrDefault()?.Origin ?? string.Empty,
                    Destination = tl.Routes.FirstOrDefault()?.Destination ?? string.Empty,
                    TransportTypeName = tl.TransportType?.Name ?? string.Empty,
                    IsActive = tl.IsActive,
                    Score = Math.Round(score, 2),
                    ScoreExplanation = explanation,
                    HasPositiveFeedback = hasPositive ? true : null,
                    HasNegativeFeedback = hasNegative ? true : null
                };
            })
            .ToList();

        return recommendedLines;
    }

    public async Task AddFeedbackAsync(int userId, int transportLineId, bool isUseful)
    {
        var existingFeedback = await _context.RecommendationFeedbacks
            .FirstOrDefaultAsync(rf => rf.UserId == userId && rf.TransportLineId == transportLineId);

        if (existingFeedback != null)
        {
            if (existingFeedback.IsUseful == isUseful)
            {
                _context.RecommendationFeedbacks.Remove(existingFeedback);
            }
            else
            {
                existingFeedback.IsUseful = isUseful;
                existingFeedback.UpdatedAt = DateTime.UtcNow;
            }
        }
        else
        {
            var feedback = new Models.RecommendationFeedback
            {
                UserId = userId,
                TransportLineId = transportLineId,
                IsUseful = isUseful,
                CreatedAt = DateTime.UtcNow
            };

            _context.RecommendationFeedbacks.Add(feedback);
        }

        await _context.SaveChangesAsync();
    }

    public async Task<bool?> GetFeedbackStatusAsync(int userId, int transportLineId)
    {
        var feedback = await _context.RecommendationFeedbacks
            .FirstOrDefaultAsync(rf => rf.UserId == userId && rf.TransportLineId == transportLineId);

        return feedback?.IsUseful;
    }

    private string GetScoreExplanation(int lineId, double score, bool hasPositiveFeedback, bool isFavorite, int purchasedCount, int similarUsersCount)
    {
        if (hasPositiveFeedback)
        {
            return $"Označili ste kao korisno (+10.0 bonus)";
        }
        
        if (isFavorite && purchasedCount > 0)
        {
            return $"U vašim omiljenim linijama i kupljeno {purchasedCount}x (+{5.0 + purchasedCount * 1.0} bonus)";
        }
        
        if (isFavorite)
        {
            return $"U vašim omiljenim linijama (+5.0 bonus)";
        }
        
        if (purchasedCount > 0)
        {
            return $"Kupljeno {purchasedCount}x (+{purchasedCount * 1.0} bonus)";
        }
        
        if (score >= 10.0)
        {
            return $"Izvrsna preporuka - visoka sličnost sa drugim korisnicima";
        }
        
        if (score >= 5.0)
        {
            return $"Jaka preporuka - {similarUsersCount} sličnih korisnika koristi ovu liniju";
        }
        
        if (score >= 2.0)
        {
            return $"Dobra preporuka - slični korisnici su kupili karte za ovu liniju";
        }
        
        if (score >= 1.0)
        {
            return $"Srednja preporuka - bazirana na sličnostima";
        }
        
        if (score >= 0.3)
        {
            return $"Početna preporuka - još nema dovoljno podataka";
        }
        
        if (score > 0.0)
        {
            return $"Popularna linija - često korišćena";
        }
        
        return "Dodatna preporuka - aktivna linija";
    }
}
