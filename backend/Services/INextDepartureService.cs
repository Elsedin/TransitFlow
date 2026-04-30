using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface INextDepartureService
{
    Task<List<NextDepartureDto>> GetNextDeparturesAsync(int routeId, int count, DateTimeOffset nowUtc);
}

