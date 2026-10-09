# TransitFlow - Public Transportation Application

TransitFlow is a project developed as a coursework assignment for the Software Development II course. The application provides a public transportation management system with features for administrators (desktop application) and users (mobile application).

## Technologies

* Backend: C#, .NET 8.0
* Desktop Application (Administrators): Flutter
* Mobile Application (Users): Flutter
* Database: SQL Server
* Message Queue: RabbitMQ

## Installation Instructions

### 1. Clone the GitHub Repository

```bash
git clone <repository-url>
cd TransitFlow
```

### 2. Configuration

* **SMTP (Mailtrap/Sandbox):** The free plan has a rate limit on the number of emails sent per second. If broadcast notifications are processed slowly, this is expected behavior. The interval can be configured using `SMTP__MININTERVALMS` (e.g., `400–1000`).

### 3. Start the Services (Docker)

```bash
docker compose up --build
```

The `docker-compose.yml` file waits for SQL Server and RabbitMQ to pass their health checks before starting the API and workers.

In the `.env` file, use `SQLSERVER_SA_PASSWORD` (which maps to `MSSQL_SA_PASSWORD` inside the SQL container). Values containing `#` in the `.env` file should be enclosed in double quotes to prevent Docker Compose from truncating the string.

The API will be available at `http://localhost:5000` (Swagger: `http://localhost:5000/swagger`).

### 4. Run the Desktop Application (Admin)

```bash
cd admin-frontend
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5000/api
```

### 5. Run the Mobile Application (User)

```bash
cd user-mobile
flutter pub get

# Android Emulator (AVD):
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...

# Physical Android Device (LAN):
flutter run --dart-define=API_BASE_URL=http://<IP-PC>:5000/api --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...
```

## Login Credentials

### Desktop Application (Admin)

Seeded user:

* **Username:** `desktop`
* **Password:** `test`

### Mobile Application (User)

Seeded user:

* **Username:** `mobile`
* **Password:** `test`

## Recommender System Documentation

The recommender system documentation is located at:

* `docs/recommender/recommender_dokumentacija.pdf`

### GitHub Release (Build Artifacts)

Build files are uploaded as a ZIP asset to a GitHub Release.

The ZIP contains:

* `user-mobile/build/app/outputs/flutter-apk/app-release.apk`
* `admin-frontend/build/windows/x64/runner/Release/`

### Build Android (APK)

The APK will be located at:

* `user-mobile/build/app/outputs/flutter-apk/app-release.apk`

### Build Windows (EXE)

The build directory will be located at:

* `admin-frontend/build/windows/x64/runner/Release/`

## PAYMENT CARD

### Stripe Test Card

```text
Card Number: 4242 4242 4242 4242
Expiration Date: Any future date (e.g., 12/30)
CVC: Any 3-digit number (e.g., 123)
ZIP Code: Any 5-digit number (e.g., 12345)
```

### PayPal Test Account

To test PayPal payments, use the following PayPal Sandbox buyer account during PayPal Checkout:

* **Email:** `transitflow@sandbox.com`
* **Password:** `TransitFlow.123`

## NOTE

`DbSeeder` runs automatically when the backend API starts for the first time and populates the database with test data.
