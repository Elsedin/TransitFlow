using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface IRecommendationService
{
    Task<List<RecommendedLineDto>> GetRecommendedLinesAsync(int userId, int count = 3);
    Task AddFeedbackAsync(int userId, int transportLineId, bool isUseful);
    Task<bool?> GetFeedbackStatusAsync(int userId, int transportLineId);
}
