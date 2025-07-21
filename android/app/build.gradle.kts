// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    // Falls dein Projekt mit dem neuen Kotlin-DSL eingerichtet ist, sonst:
    // id("kotlin-android")
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

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Firebase BoM: sorgt dafür, dass alle Firebase-Bibliotheken kompatible Versionen verwenden
    implementation(platform("com.google.firebase:firebase-bom:32.3.0"))

    // Firebase Cloud Storage (Kotlin-Extensions)
    implementation("com.google.firebase:firebase-storage-ktx")

    // Hier deine weiteren Abhängigkeiten aus dem ursprünglichen Projekt:
    // z.B. implementation("androidx.core:core-ktx:1.9.0")
    //      implementation("com.google.firebase:firebase-auth-ktx")
    //      usw.
}

flutter {
    source = "../.."
}
