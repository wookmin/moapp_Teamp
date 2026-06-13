import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/receipt_ocr_service.dart';
import '../../widgets/common_app_bar.dart';

class ReceiptOcrScreen extends StatefulWidget {
  const ReceiptOcrScreen({super.key});

  @override
  State<ReceiptOcrScreen> createState() => _ReceiptOcrScreenState();
}

class _ReceiptOcrScreenState extends State<ReceiptOcrScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final ReceiptOcrService _ocrService = ReceiptOcrService();

  XFile? _receiptImage;
  bool _isRecognizing = false;

  Future<void> _pickAndRecognize(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2200,
        imageQuality: 92,
      );
      if (image == null || !mounted) return;

      setState(() {
        _receiptImage = image;
        _isRecognizing = true;
      });

      final items = await _ocrService.recognizeImage(image.path);
      if (!mounted) return;

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('상품명을 찾지 못했어요. 영수증을 반듯하고 선명하게 다시 촬영해주세요.'),
          ),
        );
        return;
      }

      await Navigator.of(
        context,
      ).pushNamed('/add-food/confirm', arguments: items);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('영수증 인식에 실패했어요: $error')));
    } finally {
      if (mounted) {
        setState(() => _isRecognizing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            '영수증으로 추가',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '상품명 부분이 잘 보이도록 영수증 전체를 반듯하게 촬영해주세요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _receiptImage == null
                    ? const _ReceiptPlaceholder()
                    : Image.file(
                        File(_receiptImage!.path),
                        fit: BoxFit.contain,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _isRecognizing
                ? null
                : () => _pickAndRecognize(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('영수증 촬영하기'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isRecognizing
                ? null
                : () => _pickAndRecognize(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('사진에서 선택하기'),
          ),
          if (_isRecognizing) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 10),
            const Center(child: Text('상품명을 읽고 있어요...')),
          ],
        ],
      ),
    );
  }
}

class _ReceiptPlaceholder extends StatelessWidget {
  const _ReceiptPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            '영수증 사진을 준비해주세요',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
