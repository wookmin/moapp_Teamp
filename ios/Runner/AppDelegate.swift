import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterPluginRegistrant {
  private var receiptOcrChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    pluginRegistrant = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func register(with registry: FlutterPluginRegistry) {
    GeneratedPluginRegistrant.register(with: registry)

    guard let registrar = registry.registrar(forPlugin: "ReceiptOcrPlugin") else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "teamproject/receipt_ocr",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler(handleReceiptOcr)
    receiptOcrChannel = channel
  }

  private func handleReceiptOcr(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard call.method == "recognizeReceipt" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard
      let arguments = call.arguments as? [String: Any],
      let path = arguments["path"] as? String,
      let image = UIImage(contentsOfFile: path)?.cgImage
    else {
      result(
        FlutterError(
          code: "invalid_image",
          message: "영수증 이미지를 불러올 수 없습니다.",
          details: nil
        )
      )
      return
    }

    let request = VNRecognizeTextRequest { request, error in
      if let error {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "recognition_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
        return
      }

      let text = (request.results as? [VNRecognizedTextObservation])?
        .compactMap { $0.topCandidates(1).first?.string }
        .joined(separator: "\n") ?? ""
      DispatchQueue.main.async {
        result(text)
      }
    }
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["ko-KR", "en-US"]
    request.usesLanguageCorrection = true

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try VNImageRequestHandler(cgImage: image).perform([request])
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "recognition_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }
    }
  }
}
