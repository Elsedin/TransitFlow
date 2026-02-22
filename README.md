# TransitFlow

Aplikacija TransitFlow je projekat rađen kao seminarski rad za predmet Razvoj softvera II. Ova aplikacija omogućava upravljanje sistemom javnog prevoza i pruža funkcionalnosti za administratore (desktop aplikacija) i korisnike (mobilna aplikacija).

## Tehnologije

- Backend: C#, .NET 8.0
- Desktop aplikacija: Flutter
- Mobilna aplikacija: Flutter
- Baza podataka: SQL Server
- Message Queue: RabbitMQ

## Struktura Projekta

```
TransitFlow/
├── backend/              # Backend API (zajednički za admin i mobile)
├── worker/               # Worker servis za asinhrone zadatke
├── admin-frontend/       # Flutter desktop aplikacija
└── user-mobile/         # Flutter mobilna aplikacija
```

## Upute za instalaciju

1. Kloniranje GitHub repozitorija

    ```
    git clone <repository-url>
    cd TransitFlow
    ```

2. Pokretanje baze podataka i RabbitMQ (opciono)

    ```
    docker-compose up -d
    ```

    Ovo će pokrenuti SQL Server i RabbitMQ u Docker kontejnerima.

3. Pokretanje backend API-ja

    ```
    cd backend
    dotnet restore
    dotnet ef database update
    dotnet run
    ```

    API će biti dostupan na `http://localhost:5178`

4. Pokretanje desktop aplikacije

    ```
    cd admin-frontend
    flutter pub get
    flutter run -d windows
    ```

5. Pokretanje mobilne aplikacije

    ```
    cd user-mobile
    flutter pub get
    flutter run
    ```

6. Pokretanje Worker servisa (opciono)

    ```
    cd worker
    dotnet restore
    dotnet run
    ```

## Kredencijali za prijavu

### Desktop aplikacija

- Administrator

    ```
    Korisničko ime: desktop
    Lozinka: test
    ```

    ```
    Korisničko ime: admin
    Lozinka: admin123
    ```

### Mobilna aplikacija

- Korisnik

    ```
    Korisničko ime: mobile
    Lozinka: test
    ```

**Napomena**: Mobilna aplikacija će biti implementirana u narednim fazama projekta.

## Funkcionalnosti

### Desktop aplikacija (Admin)

- Dashboard sa metrikama i grafikama
- Upravljanje korisnicima (CRUD operacije)
- Pregled transakcija i uplata
- Upravljanje pretplatama
- Upravljanje notifikacijama
- Generisanje izvještaja (Excel, CSV, PDF)
- Upravljanje referentnim podacima (gradovi, zone, tipovi karata, tipovi prevoza)
- Upravljanje transportnim linijama, rutama, vozilima i rasporedima
- Upravljanje cijenama karata
- Pregled karata

### Mobilna aplikacija (User)

- Pregled linija i ruta
- Kupovina karata
- Pregled historije karata
- Profil korisnika
- Notifikacije

## NAPOMENA

Ako ne koristite Docker, aplikacija će raditi normalno, ali RabbitMQ funkcionalnosti neće biti dostupne. Notifikacije će se kreirati u bazi podataka, ali poruke neće biti poslane na RabbitMQ queue.

Za testiranje mikroservisne arhitekture (RabbitMQ i Worker servis), potrebno je pokrenuti Docker kontejnere.
