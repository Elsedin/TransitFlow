using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TransitFlow.API.Migrations
{
    /// <inheritdoc />
    public partial class AddSubscriptionPackages : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "SubscriptionPackages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Key = table.Column<string>(type: "nvarchar(80)", maxLength: 80, nullable: false),
                    DisplayName = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: false),
                    DurationDays = table.Column<int>(type: "int", nullable: false),
                    Price = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    MaxZoneId = table.Column<int>(type: "int", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SubscriptionPackages", x => x.Id);
                });

            migrationBuilder.InsertData(
                table: "SubscriptionPackages",
                columns: new[] { "Id", "Key", "DisplayName", "DurationDays", "Price", "MaxZoneId", "IsActive", "CreatedAt", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, "monthly_zone1", "Mjesečna (Zona 1)", 30, 45.00m, 1, true, DateTime.UtcNow, null },
                    { 2, "monthly_zone2", "Mjesečna (Zona 1-2)", 30, 55.00m, 2, true, DateTime.UtcNow, null },
                    { 3, "monthly_zone3", "Mjesečna (Zona 1-3)", 30, 65.00m, 3, true, DateTime.UtcNow, null },
                    { 4, "annual_zone1", "Godišnja (Zona 1)", 365, 450.00m, 1, true, DateTime.UtcNow, null },
                    { 5, "annual_zone2", "Godišnja (Zona 1-2)", 365, 550.00m, 2, true, DateTime.UtcNow, null },
                    { 6, "annual_zone3", "Godišnja (Zona 1-3)", 365, 650.00m, 3, true, DateTime.UtcNow, null },
                    { 7, "student_monthly_zone1", "Studentska mjesečna (Zona 1)", 30, 30.00m, 1, true, DateTime.UtcNow, null },
                    { 8, "student_monthly_zone2", "Studentska mjesečna (Zona 1-2)", 30, 40.00m, 2, true, DateTime.UtcNow, null },
                    { 9, "student_monthly_zone3", "Studentska mjesečna (Zona 1-3)", 30, 50.00m, 3, true, DateTime.UtcNow, null }
                });

            migrationBuilder.AddColumn<int>(
                name: "SubscriptionPackageId",
                table: "Subscriptions",
                type: "int",
                nullable: true);

            migrationBuilder.Sql(@"
UPDATE [Subscriptions]
SET [SubscriptionPackageId] =
    CASE
        WHEN LOWER([PackageName]) = N'mjesečna pretplata' THEN 3
        WHEN LOWER([PackageName]) = N'godišnja pretplata' THEN 6
        WHEN LOWER([PackageName]) = N'studentska mjesečna' THEN 7
        ELSE 3
    END
WHERE [SubscriptionPackageId] IS NULL;
");

            migrationBuilder.AlterColumn<int>(
                name: "SubscriptionPackageId",
                table: "Subscriptions",
                type: "int",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Subscriptions_SubscriptionPackageId",
                table: "Subscriptions",
                column: "SubscriptionPackageId");

            migrationBuilder.CreateIndex(
                name: "IX_SubscriptionPackages_Key",
                table: "SubscriptionPackages",
                column: "Key",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Subscriptions_SubscriptionPackages_SubscriptionPackageId",
                table: "Subscriptions",
                column: "SubscriptionPackageId",
                principalTable: "SubscriptionPackages",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Subscriptions_SubscriptionPackages_SubscriptionPackageId",
                table: "Subscriptions");

            migrationBuilder.DropTable(
                name: "SubscriptionPackages");

            migrationBuilder.DropIndex(
                name: "IX_Subscriptions_SubscriptionPackageId",
                table: "Subscriptions");

            migrationBuilder.DropColumn(
                name: "SubscriptionPackageId",
                table: "Subscriptions");
        }
    }
}
