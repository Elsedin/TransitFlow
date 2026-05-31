using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TransitFlow.API.Migrations
{
    /// <inheritdoc />
    public partial class AddTicketTypeCode : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Code",
                table: "TicketTypes",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.Sql("""
                UPDATE TicketTypes SET Code = 'single' WHERE Name = 'Jednokratna' AND (Code IS NULL OR Code = '');
                UPDATE TicketTypes SET Code = 'daily' WHERE Name = 'Dnevna' AND (Code IS NULL OR Code = '');
                UPDATE TicketTypes SET Code = 'monthly' WHERE Name LIKE '%Mjese%' AND (Code IS NULL OR Code = '');
                UPDATE TicketTypes SET Code = CONCAT('type-', Id) WHERE Code IS NULL OR Code = '';
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Code",
                table: "TicketTypes");
        }
    }
}
