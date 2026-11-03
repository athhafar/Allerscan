plugins {
id("com.android.application")
id("kotlin-android")
// The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
id("dev.flutter.flutter-gradle-plugin")
}

android {
namespace = "com.allerscan.food_allergen_detector"
compileSdk = flutter.compileSdkVersion
ndkVersion = flutter.ndkVersion

compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

kotlinOptions {
    jvmTarget = JavaVersion.VERSION_17.toString()
}

defaultConfig {
    applicationId = "com.allerscan.food_allergen_detector"
    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}

buildTypes {
    release {
        // TODO: Ganti dengan signing config rilis kamu sendiri.
        // Sementara pakai debug key supaya `flutter run --release` tetap jalan.
        signingConfig = signingConfigs.getByName("debug")
    }
}
}

flutter {
source = "../.."
}