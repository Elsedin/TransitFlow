using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TransitFlow.API.Migrations
{
    /// <inheritdoc />
    public partial class AddTicketPublicId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "PublicId",
                table: "Tickets",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.Sql("UPDATE Tickets SET PublicId = NEWID() WHERE PublicId IS NULL");

            migrationBuilder.AlterColumn<Guid>(
                name: "PublicId",
                table: "Tickets",
                type: "uniqueidentifier",
                nullable: false,
                defaultValueSql: "NEWID()",
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier",
                oldNullable: true);

            migrationBuilder.Sql("UPDATE TicketTypes SET ValidityDays = 1 WHERE Id IN (1, 2)");

            migrationBuilder.CreateIndex(
                name: "IX_Tickets_PublicId",
                table: "Tickets",
                column: "PublicId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Tickets_PublicId",
                table: "Tickets");

            migrationBuilder.DropColumn(
                name: "PublicId",
                table: "Tickets");

            migrationBuilder.Sql("UPDATE TicketTypes SET ValidityDays = 0 WHERE Id = 1");
        }
    }
}
