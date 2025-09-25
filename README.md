# Concessionario Supercar

App Flutter che mostra un catalogo di supercar con schede dettaglio, pagina **In Arrivo** (con effetti tilt), galleria immagini, mappa dei concessionari e profilo utente con valuta preferita.  
Tecnologie principali: **Flutter**, **Google Maps**, **Geolocator**, **Video Player**, **Shared Preferences**.

# **API & Sensori**
Nell'app CloperCar abbiamo deciso di utilizzare 
2 API e 2 Sensori
# **Sensori:**
Accellerometro:
inclina le card della pagina 'in arrivo' in base al movimento del telefono
Geolocalizzazione:
serve a ottenere la posizione GPS dell'utente da utilizzare per le mappe
# **API:**
Google Maps API:
ci permette di usare le mappe gi google
Rates API:
API esterna pubblica raggiunta tramite richiesta HTTP, recupera i tassi di cambio per modificare i prezzi in altre valute

## Requisiti

- **versione flutter** 3.35.3 
- **Android Studio** (per gli emulatori Android)
  consigliato l'uso di medium phone api 35
- Plugin Flutter/Dart per l’IDE (consigliato)

Verifica l’ambiente:
```bash
flutter doctor
```

## Preparazione emulator Android

1. Apri **Android Studio** → `More Actions` → **Virtual Device Manager**.
2. Crea un nuovo device scegliendo **Medium Phone**.
3. Seleziona l’immagine di sistema **API 35** (Android 15) o compatibile e completa la creazione.
4. Avvia l’emulatore dall’AVD Manager.

*(In alternativa, puoi collegare un dispositivo fisico con il debug USB attivo.)*

## Build & Run

Nella root del progetto:

```bash
flutter clean
flutter pub get
flutter run -d emulator   
# oppure: flutter run
```

- Se hai più device/emulatori, elencali con `flutter devices` e scegli l’ID da passare a `-d`.

## Permessi & Note utili

- **Geolocalizzazione**: l’app chiede i permessi in runtime. Se li neghi, alcune funzioni (es. dealer più vicino) mostreranno comportamenti limitati.
- **Google Maps**: se vuoi la mappa completamente operativa, aggiungi la tua **API Key**:
  - Android: in `android/app/src/main/res/values/google_maps_api.xml` 
  - l'API key sarà nell'e-mail


