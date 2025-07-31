// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")       // für google-services.json
    id("dev.flutter.flutter-gradle-plugin")    // Flutter-Plugin zuletzt
}

android {
    namespace = "com.example.beleg_speicher"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.example.beleg_speicher"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Java 8-Desugaring aktivieren
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions {
        // jvmTarget sollte ebenfalls 1.8 sein
        jvmTarget = "1.8"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Desugaring-Bibliothek für Java 8-APIs (auf Version 2.1.4 erhöht)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Firebase BoM: sorgt dafür, dass alle Firebase-Bibliotheken kompatible Versionen verwenden
    implementation(platform("com.google.firebase:firebase-bom:32.3.0"))

    // Firebase Cloud Storage (Kotlin-Extensions)
    implementation("com.google.firebase:firebase-storage-ktx")

    // Beispiel weiterer Abhängigkeiten aus deinem Projekt:
    implementation("androidx.core:core-ktx:1.9.0")
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.android.material:material:1.8.0")
    // … restliche deps
}

flutter {
    source = "../.."
}
