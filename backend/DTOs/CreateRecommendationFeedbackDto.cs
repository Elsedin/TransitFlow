namespace TransitFlow.API.DTOs;

public class CreateRecommendationFeedbackDto
{
    public int TransportLineId { get; set; }
    public bool IsUseful { get; set; }
}
