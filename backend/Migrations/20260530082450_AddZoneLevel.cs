using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TransitFlow.API.Migrations
{
    /// <inheritdoc />
    public partial class AddZoneLevel : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "Level",
                table: "Zones",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.Sql("UPDATE Zones SET Level = 1 WHERE Name = 'Zona 1'");
            migrationBuilder.Sql("UPDATE Zones SET Level = 2 WHERE Name = 'Zona 2'");
            migrationBuilder.Sql("UPDATE Zones SET Level = 3 WHERE Name = 'Zona 3'");
            migrationBuilder.Sql(@"
                UPDATE Zones
                SET Level = TRY_CAST(
                    LTRIM(RTRIM(REPLACE(REPLACE(Name, 'Zona', ''), 'zona', ''))) AS int)
                WHERE Level <= 0 OR Level = 1
                  AND Name LIKE 'Zona %'
                  AND TRY_CAST(LTRIM(RTRIM(REPLACE(REPLACE(Name, 'Zona', ''), 'zona', ''))) AS int) IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Level",
                table: "Zones");
        }
    }
}
