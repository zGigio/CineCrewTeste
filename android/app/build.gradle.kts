// =============================================================================
// android/app/build.gradle.kts
// -----------------------------------------------------------------------------
// Configuração de COMPILAÇÃO do app Android (Gradle, em Kotlin Script).
// Define identificador do app, versões do Android suportadas e assinatura.
// =============================================================================

plugins {
    // Plugin que transforma o módulo em um aplicativo Android (.apk/.aab).
    id("com.android.application")
    // Plugin do Flutter: deve vir DEPOIS dos plugins Android e Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Pacote base do código nativo (Kotlin/Java) do app.
    namespace = "com.seuprojeto.audiovisual_app"
    // Versão do Android SDK usada para compilar (definida pelo Flutter).
    compileSdk = flutter.compileSdkVersion
    // Versão do NDK (código nativo C/C++) usada por alguns plugins.
    ndkVersion = flutter.ndkVersion

    // Versão do Java usada na compilação.
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Identificador ÚNICO do app na Play Store (não pode mudar depois de
        // publicado). Antes de publicar, trocar "seuprojeto" por um nome real.
        applicationId = "com.seuprojeto.audiovisual_app"
        // Versão mínima do Android que consegue instalar o app.
        minSdk = flutter.minSdkVersion
        // Versão do Android para a qual o app foi otimizado.
        targetSdk = flutter.targetSdkVersion
        // Números de versão lidos do pubspec.yaml (version: 1.0.0+1).
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Por enquanto a versão final é assinada com a chave de DEBUG,
            // para que `flutter run --release` funcione. Para publicar na
            // Play Store é preciso criar uma chave própria (keystore).
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Versão da JVM alvo do compilador Kotlin (igual à do Java acima).
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// Indica onde está o projeto Flutter (duas pastas acima: a raiz do projeto).
flutter {
    source = "../.."
}
