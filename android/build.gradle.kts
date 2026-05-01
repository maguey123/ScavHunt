// ─────────────────────────────────────────────
// Top-level build.gradle.kts (android/build.gradle.kts)
// ─────────────────────────────────────────────

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Gradle Android plugin
        classpath("com.android.tools.build:gradle:8.5.2")

        // Firebase (for analytics, auth, firestore, storage, etc.)
        classpath("com.google.gms:google-services:4.4.2")
    }
}

// Repositories for all modules
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Optional: Customize build directory location
val newBuildDir = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
