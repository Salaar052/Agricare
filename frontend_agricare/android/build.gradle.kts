// Top-level build file

buildscript {
    repositories {
        google()      // Google's Maven repository
        mavenCentral() // Maven Central
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.1") // your Gradle plugin version
        classpath("com.google.gms:google-services:4.4.0") // Firebase plugin
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Optional: custom build directories
val newBuildDir: Directory =
    rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
