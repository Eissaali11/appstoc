import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Owns camera controller start/stop/dispose so the widget callback stays thin.
///
/// Notes on multi-barcode:
/// - `mobile_scanner` 3.x exposes `BarcodeCapture.barcodes` as a list; ML Kit
///   *may* return multiple codes per frame, but on many devices it returns one.
/// - We still evaluate every returned code against [ScannerContext] (never
///   first-wins). Prefer [MobileScanner.scanWindow] so GTIN/PN outside the ROI
///   are filtered before Dart sees them.
class CameraLifecycleManager {
  MobileScannerController? _controller;
  bool _disposed = false;

  MobileScannerController get controller {
    _controller ??= MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 250,
      facing: CameraFacing.back,
      torchEnabled: false,
      // Higher res helps small SN barcodes on cartons (Android).
      cameraResolution: const Size(1280, 720),
      formats: const [
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.codabar,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.itf,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.qrCode,
      ],
    );
    return _controller!;
  }

  Future<void> stop() async {
    if (_disposed) return;
    try {
      await _controller?.stop();
    } catch (_) {}
  }

  Future<void> start() async {
    if (_disposed) return;
    try {
      await _controller?.start();
    } catch (_) {}
  }

  Future<void> toggleTorch() async {
    try {
      await _controller?.toggleTorch();
    } catch (_) {}
  }

  Future<void> switchCamera() async {
    try {
      await _controller?.switchCamera();
    } catch (_) {}
  }

  Future<void> dispose() async {
    _disposed = true;
    try {
      _controller?.dispose();
    } catch (_) {}
    _controller = null;
  }
}
