import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing material never lives in this repository. On a developer's
// machine it comes from android/key.properties; on CI the same values
// arrive as environment variables from GitHub Secrets. With neither present
// the build falls back to the debug key, so `flutter run --release` still
// works on a fresh clone.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) FileInputStream(file).use { load(it) }
}

fun signingSetting(property: String, environment: String): String? =
    keystoreProperties.getProperty(property) ?: System.getenv(environment)

val keystorePath = signingSetting("storeFile", "ANDROID_KEYSTORE_PATH")

// The alias is not secret, so it is written here rather than being a fourth
// thing to configure. The key and the store share one password, which is how
// the keystore was created; either can still be overridden.
val keystoreAlias = signingSetting("keyAlias", "ANDROID_KEY_ALIAS") ?: "cse-upload"
val keystorePassword = signingSetting("storePassword", "ANDROID_KEYSTORE_PASSWORD")
val keystoreKeyPassword =
    signingSetting("keyPassword", "ANDROID_KEY_PASSWORD") ?: keystorePassword

android {
    namespace = "com.example.cse_b2b"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.cse_b2b"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Android 8.0. Set explicitly because the product targets API 26+.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Only configured when a keystore was supplied; otherwise the
            // release build type below keeps using the debug key.
            if (keystorePath != null) {
                storeFile = file(keystorePath)
                storePassword = keystorePassword
                keyAlias = keystoreAlias
                keyPassword = keystoreKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // A build signed with the real key updates in place on a
            // tester's phone. The debug fallback does not, so it is only for
            // a local `flutter run --release` on a machine with no keystore.
            signingConfig = if (keystorePath != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
