plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Must come after other plugins
}

android {
    namespace = "com.example.code_learning_app"
    compileSdk = 36 // Replace with latest compile SDK version

    ndkVersion = "27.0.12077973" // Replace with your installed NDK version

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.code_learning_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false  // <- you already have this
            isShrinkResources = false // <-- add this line
            signingConfig = signingConfigs.getByName("debug")
        }
    }

}

flutter {
    source = "../.."
}
