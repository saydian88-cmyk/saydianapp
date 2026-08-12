plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val veepooSdkArtifacts =
    listOf(
        "vpprotocol-2.3.77.15.aar",
        "vpbluetooth-1.20.aar",
        "JL_Watch_V1.13.1_11214-release.aar",
        "jl_rcsp_V0.7.2_527-release.aar",
        "jl_bt_ota_V1.10.0_10931-release.aar",
        "BmpConvert_V1.6.0_10604-release.aar",
        "abpartool-release.aar",
    )
val veepooSdkFiles = veepooSdkArtifacts.map { file("libs/$it") }
val hasAnyVeepooArtifact = veepooSdkFiles.any { it.isFile }
val hasCompleteVeepooSdk = veepooSdkFiles.all { it.isFile }

if (hasAnyVeepooArtifact && !hasCompleteVeepooSdk) {
    val missing = veepooSdkFiles.filterNot { it.isFile }.joinToString { it.name }
    throw GradleException("Veepoo SDK 文件不完整，缺少：$missing")
}

android {
    namespace = "cc.saidian.saydian_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "cc.saidian.app"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        buildConfigField("boolean", "VEEPOO_SDK_PRESENT", hasCompleteVeepooSdk.toString())
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        release {
            // Internal builds intentionally use the debug key until the Android
            // store signing material is configured outside the repository.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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

dependencies {
    if (hasCompleteVeepooSdk) {
        implementation(files(veepooSdkFiles))
        implementation("com.google.code.gson:gson:2.13.2")
        implementation("no.nordicsemi.android:mcumgr-core:2.7.4")
        implementation("no.nordicsemi.android:mcumgr-ble:2.7.4")
        implementation("no.nordicsemi.android.support.v18:scanner:1.4.2")
        implementation("androidx.localbroadcastmanager:localbroadcastmanager:1.1.0")
    }
}
