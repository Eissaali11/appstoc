import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ---------------------------------------------------------------------------
// Release signing — credentials loaded from an external properties file that
// is NEVER committed to Git. This file's presence/absence must only matter
// when a release-producing task is actually part of the requested build
// (assembleRelease, bundleRelease, packageRelease, ...) — Gradle evaluates
// the whole `android {}` block during the Configuration phase for EVERY
// invocation regardless of which task was requested, so a throw placed
// directly inside signingConfigs.create("release") { ... } (as this used to
// be) fires even for `assembleDebug`. The signingConfigs.release block below
// is now only created when the properties file exists; the actual "release
// build requested without secrets" failure is deferred to a
// gradle.taskGraph.whenReady guard further down, which only runs once
// Gradle has resolved which tasks will really execute.
// ---------------------------------------------------------------------------
val releaseKeystorePropsFile = file(
    System.getProperty("user.home") + "/.android/release-keystore.properties"
)
val releaseKeystorePropsExist = releaseKeystorePropsFile.exists()

android {
    namespace = "com.example.nuolipapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        // Only create the release signing config — and only load/require
        // its properties — when the file actually exists. A debug-only
        // request (`assembleDebug`) must never depend on this at all.
        if (releaseKeystorePropsExist) {
            create("release") {
                val props = Properties().also { it.load(releaseKeystorePropsFile.inputStream()) }
                storeFile     = file(props.getProperty("storeFile")
                    ?: throw GradleException("storeFile missing in release-keystore.properties"))
                storePassword = props.getProperty("storePassword")
                    ?: throw GradleException("storePassword missing in release-keystore.properties")
                keyAlias      = props.getProperty("keyAlias")
                    ?: throw GradleException("keyAlias missing in release-keystore.properties")
                keyPassword   = props.getProperty("keyPassword")
                    ?: throw GradleException("keyPassword missing in release-keystore.properties")
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.nuolipapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Production signing via external properties file (never
            // debug.keystore). Only wired up when the file exists — a debug
            // build must never touch this. If a release task actually runs
            // without it, the taskGraph guard below fails loudly instead.
            if (releaseKeystorePropsExist) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

// Fail loudly — but only when a release-producing task (assembleRelease,
// bundleRelease, packageRelease, or any other Flutter/Gradle-invoked
// release variant) is actually part of the requested build. Matched by
// task name pattern rather than one brittle exact name, since Flutter can
// invoke any of several release task names depending on --release vs
// --aab, flavors, etc. Runs once Gradle has resolved the real task graph,
// so a plain `assembleDebug` request never reaches this at all.
gradle.taskGraph.whenReady {
    val wantsRelease = allTasks.any { task ->
        task.name.contains("Release") &&
            (task.name.startsWith("assemble") ||
                task.name.startsWith("bundle") ||
                task.name.startsWith("package"))
    }
    if (wantsRelease && !releaseKeystorePropsExist) {
        throw GradleException(
            "RELEASE BUILD FAILED: keystore properties file not found:\n" +
            "  ${releaseKeystorePropsFile.absolutePath}\n\n" +
            "Create it with:\n" +
            "  storeFile=<absolute path to release.keystore>\n" +
            "  storePassword=<password>\n" +
            "  keyAlias=<alias>\n" +
            "  keyPassword=<password>\n\n" +
            "DO NOT commit this file to Git."
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
