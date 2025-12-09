import java.io.File
import java.io.FileReader
import java.util.Properties

pluginManagement {
    // Default Flutter SDK path
    val flutterSdkPath = File(System.getProperty("user.home"), "flutter").absolutePath

    // Load Flutter SDK path from local.properties if it exists
    val localProperties = File(settingsDir, "local.properties")
    val flutterSdk = if (localProperties.exists()) {
        val inputStream = localProperties.inputStream()
        val properties = java.util.Properties()
        inputStream.use {
            properties.load(it)
        }
        properties.getProperty("flutter.sdk") ?: flutterSdkPath
    } else {
        flutterSdkPath
    }

    includeBuild("$flutterSdk/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.6.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")

// Include Flutter plugins as subprojects
val flutterProjectRoot = rootProject.projectDir.parentFile
val pluginsFile = File(flutterProjectRoot, ".flutter-plugins")

if (pluginsFile.exists()) {
    pluginsFile.reader().use { reader ->
        reader.forEachLine { line ->
            if (line.isNotBlank() && !line.startsWith('#')) {
                val (name, path) = line.trim().split('=')
                include(":$name")
                project(":$name").projectDir = File(path.trim())
            }
        }
    }
}

// Include the Flutter module if it exists
val flutterProject = File(flutterProjectRoot, ".android/Flutter")
if (flutterProject.exists()) {
    include(":flutter")
    project(":flutter").projectDir = flutterProject
}
