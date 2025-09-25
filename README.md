# Concessionario Supercar

App Flutter che mostra un catalogo di supercar con schede dettaglio, pagina **In Arrivo** (con effetti tilt), galleria immagini, mappa dei concessionari e profilo utente con valuta preferita.
Tecnologie principali: **Flutter**, **Google Maps**, **Geolocator**, **Video Player**, **Shared Preferences**.

---

# **API & Sensori**

Nell'app CloperCar abbiamo deciso di utilizzare: 3 API e 2 Sensori

## **Sensori**

* **Accelerometro**: inclina le card della pagina 'in arrivo' in base al movimento del telefono
* **Geolocalizzazione**: serve a ottenere la posizione GPS dell'utente da utilizzare per le mappe

## **API**

* **Google Maps API**: permette di usare le mappe di Google
* **Rates API**: API esterna pubblica tramite HTTP, recupera i tassi di cambio per modificare i prezzi in altre valute
* **News API**: API esterne pubbliche basate su feed RSS/Atom di siti automobilistici, permettono di recuperare notizie di automobili aggiornate dai maggiori giornali nazionali

---

## Requisiti

* **versione Flutter** 3.35.3
* **Android Studio** (per gli emulatori Android), consigliato **Medium Phone API 35**
* Plugin **Flutter/Dart** per l’IDE (consigliato)

Verifica l’ambiente:

```bash
flutter doctor
```

---

## Preparazione emulator Android

1. Apri **Android Studio** → `More Actions` → **Virtual Device Manager**
2. Crea un nuovo device scegliendo **Medium Phone**
3. Seleziona l’immagine di sistema **API 35** (Android 15) o compatibile e completa la creazione
4. Avvia l’emulatore dall’AVD Manager

*(In alternativa, puoi collegare un dispositivo fisico con il debug USB attivo.)*

---

## Build & Run

Nella root del progetto:

```bash
flutter clean
flutter pub get
flutter run -d emulator   
# oppure: flutter run
```

* Se hai più device/emulatori, elencali con `flutter devices` e scegli l’ID da passare a `-d`.

---

## Permessi & Note utili

* **Geolocalizzazione**: l’app chiede i permessi in runtime. Se li neghi, alcune funzioni (es. dealer più vicino) mostreranno comportamenti limitati.
* **Google Maps**: per avere la mappa completamente operativa, aggiungi la tua **API Key**:

  * Android: in `android/app/src/main/res/values/google_maps_api.xml`

---

## Firma APK (Keystore)

Per generare un APK condivisibile e funzionante è necessario firmarlo con una **key**. Qui di seguito i passaggi:

### 1. Verificare Java e trovare `keytool`

Assicurati di avere il **JDK** installato:

```bash
java -version
```

Dovresti vedere qualcosa tipo:

```
java version "17.0.x"
```

Se non è installato, scaricalo da [sito ufficiale Oracle](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html).

`keytool` si trova all’interno del JDK:

* Windows: `C:\Program Files\Java\jdk-17\bin\keytool.exe`

Verifica se è nel PATH:

```bash
where keytool      # Windows
```

Se non è trovato, usa il percorso completo come mostrato sopra.

---

### 2. Creare il Keystore

Apri il terminale e digita:

```bash
keytool -genkey -v -keystore ~/my-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias
```

* `~/my-release-key.jks`: percorso dove salvare il keystore (puoi cambiare la cartella)
* `my-key-alias`: nome dell’alias della chiave
* Ti verranno chieste password, nome, organizzazione, ecc.
* **Nota:** ricordati bene le password, serviranno per firmare l’APK.

---

### 3. Creare il file `key.properties`

Nella cartella `android/` del progetto Flutter, crea un file `key.properties`:

```properties
storePassword=<la password inserita durante la creazione del keystore>
keyPassword=<la password dell'alias>
keyAlias=my-key-alias
storeFile=/absolute/percorso/del/keystore/my-release-key.jks
```

> Usa percorso **assoluto** per `storeFile` oppure relativo rispetto alla cartella `android/`.

---

### 4. Generare APK firmato

Da terminale, nella root del progetto Flutter:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

L’APK firmato si troverà in:

```
build/app/outputs/flutter-apk/app-release.apk
```

---
