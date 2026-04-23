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

3. Pokretanje servisa (Docker)

    ```
    docker compose up --build
    ```

API će biti dostupan na `http://localhost:5000` (Swagger: `http://localhost:5000/swagger`).

4. Pokretanje desktop aplikacije (Admin)

    ```
    cd admin-frontend
    flutter pub get
    flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5000/api
    ```

5. Pokretanje mobilne aplikacije (User)

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

    ```
    Korisničko ime: desktop
    Lozinka: test
    ```

### Mobilna aplikacija

- Korisnik

    ```
    Korisničko ime: mobile
    Lozinka: test
    ```

## KARTICA ZA PLAĆANJE

### Stripe Test Kartica

```
Broj kartice: 4242 4242 4242 4242
Datum isteka: bilo koji budući datum (npr. 12/25)
CVC: bilo koji 3-cifreni broj (npr. 123)
ZIP kod: bilo koji 5-cifreni broj (npr. 12345)
```

### PayPal Test Račun

PayPal credentials se konfigurišu kroz `.env` (PAYPAL__CLIENTID / PAYPAL__CLIENTSECRET).

Za testiranje PayPal plaćanja, koristite PayPal Sandbox test račun. Možete kreirati novi na [PayPal Developer Dashboard](https://developer.paypal.com/) pod "Sandbox" -> "Accounts". Koristite email i lozinku tog test računa za prijavu na PayPal stranici.

## NAPOMENA

`DbSeeder` će se automatski pokrenuti prilikom prvog pokretanja backend API-ja i popuniti bazu test podacima.
