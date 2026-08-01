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
// is NEVER committed to Git.  The build fails with a clear message if absent.
// ---------------------------------------------------------------------------
val releaseKeystorePropsFile = file(
    System.getProperty("user.home") + "/.android/release-keystore.properties"
)

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
        create("release") {
            if (!releaseKeystorePropsFile.exists()) {
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
            // Production signing via external properties file (never debug.keystore).
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
