using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TransitFlow.API.Migrations
{
    /// <inheritdoc />
    public partial class AddFavoriteLine : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "FavoriteLines",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    TransportLineId = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UserId1 = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FavoriteLines", x => x.Id);
                    table.ForeignKey(
                        name: "FK_FavoriteLines_TransportLines_TransportLineId",
                        column: x => x.TransportLineId,
                        principalTable: "TransportLines",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_FavoriteLines_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_FavoriteLines_Users_UserId1",
                        column: x => x.UserId1,
                        principalTable: "Users",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_FavoriteLines_TransportLineId",
                table: "FavoriteLines",
                column: "TransportLineId");

            migrationBuilder.CreateIndex(
                name: "IX_FavoriteLines_UserId_TransportLineId",
                table: "FavoriteLines",
                columns: new[] { "UserId", "TransportLineId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_FavoriteLines_UserId1",
                table: "FavoriteLines",
                column: "UserId1");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "FavoriteLines");
        }
    }
}
