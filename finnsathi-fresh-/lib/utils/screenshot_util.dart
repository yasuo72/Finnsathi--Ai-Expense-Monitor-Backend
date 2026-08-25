import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A utility class to take screenshots of widgets and share them
class ScreenshotUtil {
  /// Takes a screenshot of the given [globalKey] and returns the image as bytes
  static Future<Uint8List?> captureFromWidget(GlobalKey globalKey) async {
    try {
      // Ensure the current frame is finished so the widget is fully painted
      await WidgetsBinding.instance.endOfFrame;

      final context = globalKey.currentContext;
      if (context == null) {
        debugPrint('Error taking screenshot: context is null for provided key');
        return null;
      }

      final renderObject = context.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        debugPrint(
          'Error taking screenshot: renderObject is not a RenderRepaintBoundary',
        );
        return null;
      }

      final boundary = renderObject;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error taking screenshot: $e');
      return null;
    }
  }

  /// Takes a screenshot and shares it
  static Future<void> captureAndShare(GlobalKey globalKey) async {
    try {
      final Uint8List? imageBytes = await captureFromWidget(globalKey);
      if (imageBytes == null) return;

      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      await Share.shareFiles([imagePath], text: 'My Financial Progress');
    } catch (e) {
      debugPrint('Error sharing screenshot: $e');
    }
  }
}
