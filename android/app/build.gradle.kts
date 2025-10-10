import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.jocaagura.pixel"

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
        applicationId = "com.jocaagura.pixel"
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion

        val vc = project.findProperty("VERSION_CODE")?.toString()?.toInt() ?: flutter.versionCode
        val vn = project.findProperty("VERSION_NAME")?.toString() ?: flutter.versionName
        versionCode = vc
        versionName = vn
    }

    signingConfigs {
        create("release") {
            val kpFile = file("key.properties")
            if (kpFile.exists()) {
                val kp = Properties().apply { load(FileInputStream(kpFile)) }
                storeFile = file(kp.getProperty("storeFile"))
                storePassword = kp.getProperty("storePassword")
                keyAlias = kp.getProperty("keyAlias")
                keyPassword = kp.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        getByName("debug") {
            isDebuggable = true
        }
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            // Si usas reglas personalizadas:
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Pixel (DEV)")
        }
        create("qa") {
            dimension = "env"
            applicationIdSuffix = ".qa"
            versionNameSuffix = "-qa"
            resValue("string", "app_name", "Pixel (QA)")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Pixel")
        }
    }
}

flutter {
    source = "../.."
}
