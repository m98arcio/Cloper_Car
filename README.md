# Concessionario Supercar

App Flutter che mostra un catalogo di supercar con schede dettaglio, pagina **In Arrivo** (con effetti tilt), galleria immagini, mappa dei concessionari e profilo utente con valuta preferita.  
Tecnologie principali: **Flutter**, **Google Maps**, **Geolocator**, **Video Player**, **Shared Preferences**.

## Requisiti

- **Flutter SDK** ≥ 3.5.0 (vedi `environment.sdk` nel `pubspec.yaml`)
- **Android Studio** (per gli emulatori Android)
- Plugin Flutter/Dart per l’IDE (consigliato)

Verifica l’ambiente:
```bash
flutter doctor
```

## Preparazione emulator Android

1. Apri **Android Studio** → `More Actions` → **AVD Manager**.
2. Crea un nuovo device scegliendo **Medium Phone**.
3. Seleziona l’immagine di sistema **API 35** (Android 15) o compatibile e completa la creazione.
4. Avvia l’emulatore dall’AVD Manager.

*(In alternativa, puoi collegare un dispositivo fisico con il debug USB attivo.)*

## Build & Run

Nella root del progetto:

```bash
flutter clean
flutter pub get
flutter run -d emulator   # oppure: flutter run
```

- Se hai più device/emulatori, elencali con `flutter devices` e scegli l’ID da passare a `-d`.
- Per iOS (opzionale, solo su macOS con Xcode):
  ```bash
  open -a Simulator
  flutter run -d ios
  ```

## Permessi & Note utili

- **Geolocalizzazione**: l’app chiede i permessi in runtime. Se li neghi, alcune funzioni (es. dealer più vicino) mostreranno comportamenti limitati.
- **Google Maps**: se vuoi la mappa completamente operativa, aggiungi la tua **API Key**:
  - Android: in `android/app/src/main/AndroidManifest.xml` dentro `<application>` aggiungi:
    ```xml
    <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_API_KEY"/>
    ```
  - iOS: in `ios/Runner/AppDelegate.swift` o `AppDelegate.m` secondo la guida di `google_maps_flutter`.

## Struttura principale

```
lib/
  models/            # Modelli (Car, DealerPoint, ...)
  screens/           # Schermate (Home, Incoming, Dettaglio, Profilo, ...)
  widgets/           # Widget riutilizzabili (BrandLogo, BottomBar, ...)
  services/          # Servizi (LocalCatalog, CurrencyService, RatesApi, ...)
assets/
  macchine/          # Immagini auto (sottocartelle per brand/modello)
  loghi/             # Loghi brand
  video/             # Video brand
  cars.json          # Catalogo auto
  dealers.json       # Concessionari
pubspec.yaml         # Dipendenze e dichiarazione asset
```

## Troubleshooting

- **Build fallisce dopo aggiornamenti**  
  Esegui:
  ```bash
  flutter clean && flutter pub get
  ```
- **Nessun device trovato**  
  Avvia un emulatore da Android Studio o collega un device fisico, poi:
  ```bash
  flutter devices
  ```
- **Mappa nera/vuota**  
  Verifica di aver inserito correttamente la **Google Maps API Key**.
- **Permessi posizione negati**  
  Concedi i permessi dalle impostazioni del dispositivo o reinstalla l’app.
