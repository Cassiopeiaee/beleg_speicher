// android/build.gradle.kts

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Android Gradle Plugin
        classpath("com.android.tools.build:gradle:8.1.2")
        // Google Services Plugin für firebase-services
        classpath("com.google.gms:google-services:4.4.3")
    }
}

// Hier werden deine Flutter- und App-Plugins im app-Modul geladen, kein plugins-Block nötig.

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// (Optional) Lege dein gemeinsames Build-Verzeichnis außerhalb des android-Ordners ab:
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Passe auch für Subprojekte den Build-Pfad an
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
