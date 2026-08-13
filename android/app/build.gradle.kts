import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun signingValue(propertyName: String, environmentName: String): String? =
    keystoreProperties[propertyName] as String? ?: System.getenv(environmentName)

android {
    namespace = "com.electrons.minifootowner"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.electrons.minifootowner"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = signingValue("keyAlias", "MINIFOOT_UPLOAD_KEY_ALIAS")
            keyPassword = signingValue("keyPassword", "MINIFOOT_UPLOAD_KEY_PASSWORD")
            storeFile = signingValue("storeFile", "MINIFOOT_UPLOAD_STORE_FILE")?.let { file(it) }
            storePassword = signingValue("storePassword", "MINIFOOT_UPLOAD_STORE_PASSWORD")
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    packagingOptions {
        jniLibs.keepDebugSymbols.add("**/*.so")
    }
}

flutter {
    source = "../.."
}
