plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.frontend_agricare"
    compileSdk = 36 // Or flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.example.frontend_agricare"
        minSdk = flutter.minSdkVersion  // Or flutter.minSdkVersion
        targetSdk = 36 // Or flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))

    // Firebase products
    implementation("com.google.firebase:firebase-analytics")
}
