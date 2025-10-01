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
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_11.toString() }

    defaultConfig {
        applicationId = "com.jocaagura.pixel"
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion


        val vc = project.findProperty("VERSION_CODE")?.toString()?.toInt() ?: 1
        val vn = project.findProperty("VERSION_NAME")?.toString() ?: flutter.versionName
        versionCode = vc
        versionName = vn
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            // puedes añadir applicationIdSuffix, por ejemplo: ".debug"
        }
    }

     flavorDimensions += "env"
     productFlavors {
         create("dev") {
             dimension = "env"
             applicationId = "com.jocaagura.pixel.dev"
             versionNameSuffix = "-dev"
         }
         create("qa") {
             dimension = "env"
             applicationId = "com.jocaagura.pixel.qa"
             versionNameSuffix = "-qa"
         }
         create("prod") {
             dimension = "env"
             applicationId = "com.jocaagura.pixel"
         }
     }
}

flutter { source = "../.." }
