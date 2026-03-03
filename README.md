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

2. Pokretanje baze podataka i RabbitMQ

    ```
    docker compose up -d rabbitmq sqlserver
    ```

3. Pokretanje backend API-ja

    ```
    cd backend
    dotnet restore
    dotnet ef database update
    dotnet run
    ```

4. Pokretanje Worker servisa (za notifikacije)

    ```
    cd worker
    dotnet restore
    dotnet run
    ```

5. Pokretanje desktop aplikacije (Admin)

    ```
    cd admin-frontend
    flutter pub get
    flutter run -d windows
    ```

6. Pokretanje mobilne aplikacije (User)

    ```
    cd user-mobile
    flutter pub get
    flutter run
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

PayPal credentials su već konfigurisani u `backend/appsettings.json` sa Sandbox podacima.

Za testiranje PayPal plaćanja, koristite PayPal Sandbox test račun. Možete kreirati novi na [PayPal Developer Dashboard](https://developer.paypal.com/) pod "Sandbox" -> "Accounts". Koristite email i lozinku tog test računa za prijavu na PayPal stranici.

## NAPOMENA

`DbSeeder` će se automatski pokrenuti prilikom prvog pokretanja backend API-ja i popuniti bazu test podacima.
