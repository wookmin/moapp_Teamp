import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/community_post.dart';
import '../../repositories/app_repositories.dart';

/// 커뮤니티 글쓰기 페이지.
///
/// 사진은 갤러리에서 선택 → Firebase Storage 업로드 → download URL을
/// CommunityPost.imageUrl에 저장하는 흐름.
/// 발행 성공 시 Navigator.pop(context, true)로 돌아간다.
class PostComposeScreen extends StatefulWidget {
  const PostComposeScreen({super.key});

  @override
  State<PostComposeScreen> createState() => _PostComposeScreenState();
}

class _PostComposeScreenState extends State<PostComposeScreen> {
  static const List<String> _badgeOptions = [
    '신선한 선택',
    '전문가 팁',
    '주의사항',
    '레시피',
  ];

  final _titleController = TextEditingController();
  final _excerptController = TextEditingController();
  final _imagePicker = ImagePicker();

  String _selectedBadge = _badgeOptions.first;
  XFile? _pickedImage;
  bool _isSubmitting = false;
  String _submitStatus = '발행';

  @override
  void dispose() {
    _titleController.dispose();
    _excerptController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _pickedImage = picked);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진을 불러올 수 없어요: $error')),
      );
    }
  }

  void _removeImage() {
    setState(() => _pickedImage = null);
  }

  /// 선택된 사진을 Firebase Storage에 업로드하고 download URL을 반환한다.
  Future<String?> _uploadImage() async {
    if (_pickedImage == null) return null;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = FirebaseStorage.instance.ref(
      'post_images/$uid/$timestamp.jpg',
    );
    await ref.putFile(File(_pickedImage!.path));
    return ref.getDownloadURL();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final excerpt = _excerptController.text.trim();

    if (title.isEmpty || excerpt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 본문을 모두 입력해 주세요.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitStatus = _pickedImage != null ? '업로드 중...' : '발행 중...';
    });

    try {
      final imageUrl = await _uploadImage();

      if (mounted && _pickedImage != null) {
        setState(() => _submitStatus = '발행 중...');
      }

      final user = FirebaseAuth.instance.currentUser;
      final authorName =
          user?.displayName ?? (user?.email ?? '익명').split('@').first;

      final post = CommunityPost(
        id: '',
        title: title,
        author: '@$authorName',
        excerpt: excerpt,
        badge: _selectedBadge,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      await AppRepositories.community.addPost(post);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('발행 실패: $error')),
      );
      setState(() {
        _isSubmitting = false;
        _submitStatus = '발행';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('글 쓰기'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 6),
                      Text(_submitStatus),
                    ],
                  )
                : const Text(
                    '발행',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // 1. 사진 영역
          Text(
            '대표 사진 (선택)',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _ImagePickerArea(
            pickedImage: _pickedImage,
            onTap: _pickFromGallery,
            onRemove: _removeImage,
          ),
          const SizedBox(height: 24),

          // 2. 카테고리(배지) 선택
          Text(
            '카테고리',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _badgeOptions.map((badge) {
              final selected = _selectedBadge == badge;
              return ChoiceChip(
                label: Text(badge),
                selected: selected,
                onSelected: (_) => setState(() => _selectedBadge = badge),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 3. 제목
          Text(
            '제목',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: '예: 고수를 위한 물병 보관법',
            ),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // 4. 본문
          Text(
            '본문',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _excerptController,
            minLines: 5,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: '보관 비결이나 레시피 아이디어를 자유롭게 적어 주세요.',
            ),
          ),
        ],
      ),
    );
  }
}

/// 사진 선택 영역.
/// - 빈 상태: 탭하면 갤러리 열림. "사진 추가" placeholder.
/// - 선택됨: 미리보기 + 우상단 X 버튼으로 제거.
class _ImagePickerArea extends StatelessWidget {
  const _ImagePickerArea({
    required this.pickedImage,
    required this.onTap,
    required this.onRemove,
  });

  final XFile? pickedImage;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = pickedImage != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.file(File(pickedImage!.path), fit: BoxFit.cover)
            else
              InkWell(
                onTap: onTap,
                child: Container(
                  color: colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '탭해서 사진 추가',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '갤러리에서 선택',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (hasImage)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            if (hasImage)
              Positioned(
                bottom: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '변경',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}