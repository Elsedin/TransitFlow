using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TransitFlow.API.Migrations
{
    /// <inheritdoc />
    public partial class AddScheduleArrivalDayOffset : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "ArrivalDayOffset",
                table: "Schedules",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ArrivalDayOffset",
                table: "Schedules");
        }
    }
}
