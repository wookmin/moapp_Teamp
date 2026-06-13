package com.example.teamproject

import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "teamproject/receipt_ocr",
        ).setMethodCallHandler { call, result ->
            if (call.method != "recognizeReceipt") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val path = call.argument<String>("path")
            if (path.isNullOrBlank()) {
                result.error("invalid_path", "영수증 이미지 경로가 없습니다.", null)
                return@setMethodCallHandler
            }

            val image = try {
                InputImage.fromFilePath(this, Uri.fromFile(File(path)))
            } catch (error: Exception) {
                result.error("invalid_image", error.message, null)
                return@setMethodCallHandler
            }

            val recognizer = TextRecognition.getClient(
                KoreanTextRecognizerOptions.Builder().build(),
            )
            recognizer.process(image)
                .addOnSuccessListener { text ->
                    result.success(text.text)
                }
                .addOnFailureListener { error ->
                    result.error("recognition_failed", error.message, null)
                }
                .addOnCompleteListener {
                    recognizer.close()
                }
        }
    }
}
