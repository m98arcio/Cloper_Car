plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.personale"

    // Imposta esplicitamente il livello SDK richiesto dai plugin recenti (es. geolocator_android)
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Con Flutter 3.22+ è consigliato Java 17
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.personale"

        // Puoi lasciare minSdk dal template Flutter (va bene), oppure fissarlo esplicito a 21+
        minSdk = flutter.minSdkVersion
        targetSdk = 35

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Usa una signingConfig adeguata in produzione; per ora debug va bene
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}