import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/progress_photo.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';

/// Before-and-After Progress Photos comparison card backed by local storage
/// and private Supabase Storage (`progress-images` bucket when authenticated).
class BeforeAfterPhotosCard extends ConsumerWidget {
  final double? latestWeightKg;
  final bool isMetric;

  const BeforeAfterPhotosCard({
    super.key,
    this.latestWeightKg,
    required this.isMetric,
  });

  Future<void> _pickAndSavePhoto(
    BuildContext context,
    WidgetRef ref,
    String slot,
  ) async {
    final picker = ref.read(progressPhotoPickerProvider);
    final picked = await picker();
    if (!context.mounted) return;

    if (picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No image selected. Please choose a PNG, JPG, or WEBP photo.',
          ),
        ),
      );
      return;
    }

    final initialWeight = latestWeightKg != null
        ? (isMetric ? latestWeightKg! : latestWeightKg! * 2.20462)
            .toStringAsFixed(1)
        : '';
    final weightCtrl = TextEditingController(text: initialWeight);
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          slot == 'before' ? 'Save Before Photo' : 'Save After Photo',
          style: AppTextStyles.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File: ${picked.fileName}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: weightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText:
                      'Current Weight (${isMetric ? 'kg' : 'lb'}, optional)',
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (lighting, pose, milestone)',
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save Photo'),
          ),
        ],
      ),
    );

    final weightRaw = double.tryParse(weightCtrl.text.trim());
    final notesText = notesCtrl.text.trim();
    weightCtrl.dispose();
    notesCtrl.dispose();

    if (confirmed != true) return;

    final weightKg = weightRaw == null
        ? null
        : (isMetric ? weightRaw : weightRaw / 2.20462);

    await ref.read(progressPhotosProvider.notifier).saveSlotPhoto(
          slot: slot,
          file: picked,
          weightKg: weightKg,
          notes: notesText.isEmpty ? null : notesText,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(progressPhotosProvider);
    final photos = photosAsync.value ?? const <ProgressPhoto>[];

    ProgressPhoto? beforePhoto;
    ProgressPhoto? afterPhoto;
    for (final p in photos) {
      if (p.slot == 'before' && beforePhoto == null) beforePhoto = p;
      if (p.slot == 'after' && afterPhoto == null) afterPhoto = p;
    }

    String? comparisonSummary;
    if (beforePhoto != null && afterPhoto != null) {
      final daysDiff =
          afterPhoto.takenAt.difference(beforePhoto.takenAt).inDays.abs();
      final parts = <String>['$daysDiff days apart'];
      if (beforePhoto.weightKg != null && afterPhoto.weightKg != null) {
        final diffKg = afterPhoto.weightKg! - beforePhoto.weightKg!;
        final diffDisp = isMetric ? diffKg : diffKg * 2.20462;
        final unit = isMetric ? 'kg' : 'lb';
        final sign = diffDisp > 0 ? '+' : '';
        parts.add('$sign${diffDisp.toStringAsFixed(1)} $unit change');
      }
      comparisonSummary = parts.join(' • ');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.compare_rounded,
                color: AppColors.darkCharcoal,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Before & After Progress Photos',
                  style: AppTextStyles.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Upload private transformation photos to visually track your physique side-by-side.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (comparisonSummary != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.limeAccent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                'Comparison: $comparisonSummary',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.limeAccentDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final beforeSlot = _PhotoSlotCard(
                title: 'Before Photo',
                emptyLabel: 'No Before Photo Yet',
                uploadLabel: 'Upload Before Photo',
                photo: beforePhoto,
                isMetric: isMetric,
                onUpload: () => _pickAndSavePhoto(context, ref, 'before'),
                onRemove: () async {
                  final ok = await ConfirmationDialog.show(
                    context,
                    title: 'Remove Before Photo?',
                    message: 'Remove your saved Before progress photo?',
                    confirmLabel: 'Remove',
                    isDestructive: true,
                  );
                  if (ok == true) {
                    await ref
                        .read(progressPhotosProvider.notifier)
                        .removeSlotPhoto('before');
                  }
                },
              );

              final afterSlot = _PhotoSlotCard(
                title: 'After Photo',
                emptyLabel: 'No After Photo Yet',
                uploadLabel: 'Upload After Photo',
                photo: afterPhoto,
                isMetric: isMetric,
                onUpload: () => _pickAndSavePhoto(context, ref, 'after'),
                onRemove: () async {
                  final ok = await ConfirmationDialog.show(
                    context,
                    title: 'Remove After Photo?',
                    message: 'Remove your saved After progress photo?',
                    confirmLabel: 'Remove',
                    isDestructive: true,
                  );
                  if (ok == true) {
                    await ref
                        .read(progressPhotosProvider.notifier)
                        .removeSlotPhoto('after');
                  }
                },
              );

              if (constraints.maxWidth >= 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: beforeSlot),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: afterSlot),
                  ],
                );
              }
              return Column(
                children: [
                  beforeSlot,
                  const SizedBox(height: AppSpacing.md),
                  afterSlot,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PhotoSlotCard extends StatelessWidget {
  final String title;
  final String emptyLabel;
  final String uploadLabel;
  final ProgressPhoto? photo;
  final bool isMetric;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  const _PhotoSlotCard({
    required this.title,
    required this.emptyLabel,
    required this.uploadLabel,
    required this.photo,
    required this.isMetric,
    required this.onUpload,
    required this.onRemove,
  });

  Widget _buildPreviewImage(ProgressPhoto p) {
    if (p.imageBase64 != null && p.imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(p.imageBase64!);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 220,
          errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
        );
      } catch (_) {
        return _imagePlaceholder();
      }
    }
    if (p.signedUrl != null && p.signedUrl!.isNotEmpty) {
      return Image.network(
        p.signedUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 220,
        errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 220,
      width: double.infinity,
      color: AppColors.borderSubtle.withValues(alpha: 0.4),
      child: const Center(
        child: Icon(
          Icons.photo_outlined,
          size: 40,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSubtleBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (photo != null)
                Text(
                  AppFormatters.formatShortDate(photo!.takenAt),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (photo == null) ...[
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_outlined,
                    size: 32,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    emptyLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkCharcoal,
                  foregroundColor: Colors.white,
                ),
                onPressed: onUpload,
                icon: const Icon(Icons.upload_rounded, size: 16),
                label: Text(uploadLabel),
              ),
            ),
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: _buildPreviewImage(photo!),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (photo!.weightKg != null)
              Text(
                'Weight: ${(isMetric ? photo!.weightKg! : photo!.weightKg! * 2.20462).toStringAsFixed(1)} ${isMetric ? 'kg' : 'lb'}',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.limeAccentDark,
                ),
              ),
            if (photo!.notes != null && photo!.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  photo!.notes!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                OutlinedButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: const Text('Replace'),
                ),
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 15,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'Remove',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
