# TransitFlow - Aplikacija za javni prevoz

Aplikacija TransitFlow je projekat rađen kao seminarski rad za predmet Razvoj softvera II. Ova aplikacija omogućava upravljanje sistemom javnog prevoza i pruža funkcionalnosti za administratore (desktop aplikacija) i korisnike (mobilna aplikacija).

## Tehnologije

- Backend: C#, .NET 8.0
- Desktop aplikacija (Administratori): Flutter
- Mobilna aplikacija (Korisnici): Flutter
- Baza podataka: SQL Server
- Message Queue: RabbitMQ

## Upute za instalaciju

1. Kloniranje GitHub repozitorija
  ```
    git clone <repository-url>
    cd TransitFlow
  ```
2. Konfiguracija (2026 upute)

Konfiguracijske vrijednosti i tajne se ne drže u kodu niti u `appsettings.json`, već u `.env` fajlu.

- Kopirajte `.env.example` u `.env` i popunite vrijednosti (Stripe/PayPal/JWT/DB).
- `.env` se ne commit-uje. Za predaju se `.env` zipuje (šifra `fit`) prema uputama.

1. Pokretanje servisa (Docker)
  ```
    docker compose up --build
  ```

`docker-compose.yml` čeka da SQL Server i RabbitMQ prođu healthcheck prije starta API-ja i workera. U `.env` koristite `SQLSERVER_SA_PASSWORD` (mapira se na `MSSQL_SA_PASSWORD` u SQL kontejneru). Vrijednosti s `#` u `.env` stavite u dvostruke navodnike da Docker Compose ne odreže string.

API će biti dostupan na `http://localhost:5000` (Swagger: `http://localhost:5000/swagger`).

1. Pokretanje desktop aplikacije (Admin)
  ```
    cd admin-frontend
    flutter pub get
    flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5000/api
  ```
2. Pokretanje mobilne aplikacije (User)
  ```
    cd user-mobile
    flutter pub get

    # Android emulator (AVD):
    flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...

    # Fizički Android uređaj (LAN):
    flutter run --dart-define=API_BASE_URL=http://<IP-PC>:5000/api --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...
  ```

## Kredencijali za prijavu

### Desktop aplikacija

- Administrator

### Mobilna aplikacija

- Korisnik

## KARTICA ZA PLAĆANJE

### Stripe Test Kartica

```
Broj kartice: 4242 4242 4242 4242
Datum isteka: bilo koji budući datum (npr. 12/25)
CVC: bilo koji 3-cifreni broj (npr. 123)
ZIP kod: bilo koji 5-cifreni broj (npr. 12345)
```

### PayPal Test Račun


Za testiranje PayPal plaćanja, koristite sljedeći PayPal Sandbox (buyer) račun na PayPal checkoutu:

- Email: `transitflow@sandbox.com`
- Password: `TransitFlow.123`


## NAPOMENA

`DbSeeder` će se automatski pokrenuti prilikom prvog pokretanja backend API-ja i popuniti bazu test podacima.