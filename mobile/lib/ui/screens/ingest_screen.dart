/// IngestScreen: Pipeline tải → nén → upload, dùng IngestCubit.
///
/// Thay thế ApiService polling bằng Cubit emit state từng bước.
/// UI tự cập nhật theo sealed class IngestState.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../logic/ingest_cubit/ingest_cubit.dart';
import '../../logic/ingest_cubit/ingest_state.dart';
import '../../main.dart';

class IngestScreen extends StatefulWidget {
  const IngestScreen({super.key});

  @override
  State<IngestScreen> createState() => _IngestScreenState();
}

class _IngestScreenState extends State<IngestScreen> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.paleBackground;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : const Color(0xFF2D2D2D);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Nén Audio',
          style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: BlocConsumer<IngestCubit, IngestState>(
        listener: (context, state) {
          // Xử lý side effect: hiển thị snackbar + navigate
          if (state is IngestSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Đã lưu "${state.track.displayName}"'),
                backgroundColor: Colors.green.shade600,
              ),
            );
            Navigator.pop(context, true);
          }
          if (state is IngestMetadataReady) {
            _nameController.text = state.metadata.title;
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Ô dán link ──
                _buildUrlField(cardColor, state),

                // Error message
                if (state is IngestError)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      state.message,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13),
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Preview card ──
                if (state is IngestMetadataReady)
                  _buildPreviewCard(state, isDark, cardColor),

                // ── Pipeline progress ──
                if (_isPipelineRunning(state))
                  _buildPipelineProgress(state, textColor),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUrlField(Color cardColor, IngestState state) {
    final isFetching = state is IngestFetchingMetadata;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.midPurple.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _urlController,
        enabled: !isFetching && !_isPipelineRunning(state),
        decoration: InputDecoration(
          hintText: 'Dán link YouTube...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.link, color: AppColors.midPurple),
          suffixIcon: IconButton(
            icon: isFetching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.midPurple,
                    ),
                  )
                : const Icon(Icons.search, color: AppColors.midPurple),
            onPressed: isFetching
                ? null
                : () => context
                    .read<IngestCubit>()
                    .fetchMetadata(_urlController.text.trim()),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        onSubmitted: (_) => context
            .read<IngestCubit>()
            .fetchMetadata(_urlController.text.trim()),
      ),
    );
  }

  Widget _buildPreviewCard(
      IngestMetadataReady state, bool isDark, Color cardColor) {
    final meta = state.metadata;
    final durationStr =
        '${meta.duration.inMinutes.toString().padLeft(2, '0')}:'
        '${(meta.duration.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.midPurple.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (meta.thumbnailUrl != null)
                    CachedNetworkImage(
                      imageUrl: meta.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        decoration:
                            const BoxDecoration(gradient: AppColors.cardGradient),
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.white54, size: 40),
                      ),
                    )
                  else
                    Container(
                      decoration:
                          const BoxDecoration(gradient: AppColors.cardGradient),
                      child: const Icon(Icons.music_note,
                          color: Colors.white54, size: 40),
                    ),
                  // Duration badge
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(durationStr,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Channel
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(meta.channelName,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 14),

                // Ô sửa tên
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.paleBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên audio',
                      labelStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.edit,
                          size: 20, color: AppColors.midPurple),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nút nén
                FilledButton.icon(
                  onPressed: () {
                    context.read<IngestCubit>().startPipeline(
                          customName: _nameController.text.trim().isNotEmpty
                              ? _nameController.text.trim()
                              : null,
                        );
                  },
                  icon: const Icon(Icons.compress),
                  label: const Text('Tải & Nén Audio',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.midPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineProgress(IngestState state, Color textColor) {
    String stepLabel;
    double? progress;
    IconData stepIcon;

    if (state is IngestDownloading) {
      stepLabel = 'Đang đẩy yêu cầu lên Server...\nQuá trình tải, nén và cắt file có thể mất vài phút đối với video dài. Vui lòng không đóng ứng dụng.';
      progress = state.progress;
      stepIcon = Icons.cloud_sync;
    } else if (state is IngestSaving) {
      stepLabel = 'Đang lưu metadata...';
      stepIcon = Icons.save;
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          // Spinner hoặc determinate progress
          if (progress != null)
            LinearProgressIndicator(
              value: progress,
              color: AppColors.midPurple,
              borderRadius: BorderRadius.circular(4),
            )
          else
            const LinearProgressIndicator(color: AppColors.midPurple),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(stepIcon, color: AppColors.midPurple, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stepLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isPipelineRunning(IngestState state) {
    return state is IngestDownloading ||
        state is IngestSaving;
  }
}
