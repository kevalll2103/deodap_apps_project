plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Make sure this matches your Manifest & MainActivity package
    namespace = "com.example.dd_wms_field"

    // Let Flutter control the SDK versions (comes from Flutter toolchain)
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.dd_wms_field"

        // From Flutter toolchain (keeps your project in sync with Flutter config)
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ Force support for BOTH 64-bit and 32-bit phones
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }

        // (Optional) keep only required locales to save space
        // resourceConfigurations += setOf("en", "hi")
    }

    // Use Java 17 (recommended for AGP 8+ and recent plugins)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
        // freeCompilerArgs += listOf("-Xjvm-default=all") // (optional)
    }

    // If you ever hit duplicate META-INF entries from some plugins, keep this:
    packaging {
        resources {
            excludes += setOf(
                "META-INF/AL2.0",
                "META-INF/LGPL2.1",
                "META-INF/licenses/ASM"
            )
        }
        jniLibs {
            // Modern packaging (saves space on newer Android)
            useLegacyPackaging = false
        }
    }

    // Keep release simple for now; wire up your real signing when ready
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            // Size optimization (uncomment when ready):
            // isMinifyEnabled = true
            // isShrinkResources = true
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }

    // (Optional) Disable lint aborts during CI/dev if you prefer
    // lint {
    //     abortOnError = false
    // }
}

flutter {
    source = "../.."
}

// If you start seeing method count issues with many plugins,
// enable multidex by uncommenting below and adding Multidex dependency.
// android {
//     defaultConfig {
//         multiDexEnabled = true
//     }
// }
// dependencies {
//     implementation("androidx.multidex:multidex:2.0.1")
// }
