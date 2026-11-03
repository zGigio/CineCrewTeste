// Pacote (endereço único) do app no Android. Deve bater com o
// "namespace" definido em android/app/build.gradle.kts.
package com.seuprojeto.audiovisual_app

// FlutterActivity: Activity pronta do Flutter que inicia o motor Dart
// e desenha a interface do app.
import io.flutter.embedding.android.FlutterActivity

// Tela nativa principal. Não precisa de código: todo o app é feito em Dart.
class MainActivity : FlutterActivity()
