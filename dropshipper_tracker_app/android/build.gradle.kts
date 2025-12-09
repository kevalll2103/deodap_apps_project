// Top-level build file where you can add configuration options common to all sub-projects/modules.
buildscript {
    val kotlinVersion = "1.9.22"
    
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.2.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
        // Removed google-services and firebase-crashlytics plugins
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Set build directory for all projects
rootProject.layout.buildDirectory.set(File("../build"))

// Configure build directory for subprojects
subprojects {
    val projectBuildDir = rootProject.layout.buildDirectory.get().asFile.resolve(project.name)
    layout.buildDirectory.set(projectBuildDir)
    
    // Ensure app project is evaluated first
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
