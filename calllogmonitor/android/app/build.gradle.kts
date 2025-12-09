plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.calllogmonitor"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Specify the required NDK version

    compileOptions {
        // CRITICAL: Enable core library desugaring for flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.calllogmonitor"
        minSdk = flutter.minSdkVersion // Set this explicitly to 23 or higher (good for desugaring)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // REQUIRED: Core library desugaring dependency for flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.google.android.material:material:1.6.0")
    implementation("com.google.code.gson:gson:2.10.1")
    implementation("com.android.support:support-annotations:28.0.0") // For JSON serialization
    // Other dependencies can be added here
}

flutter {
    source = "../.."
}
