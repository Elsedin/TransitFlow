using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TransitFlow.API.Migrations
{
    /// <inheritdoc />
    public partial class DeactivateMonthlyAnnualTicketTypes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
UPDATE [TicketTypes]
SET [IsActive] = 0,
    [UpdatedAt] = SYSUTCDATETIME()
WHERE [Name] IN (N'Mjesečna', N'Godišnja');
");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
UPDATE [TicketTypes]
SET [IsActive] = 1,
    [UpdatedAt] = SYSUTCDATETIME()
WHERE [Name] IN (N'Mjesečna', N'Godišnja');
");
        }
    }
}
