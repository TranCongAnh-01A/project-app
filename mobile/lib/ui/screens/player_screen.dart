import 'package:flutter/material.dart';

class FullPlayerScreen extends StatelessWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng Scaffold trong Modal để có đầy đủ tính năng UI
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Column(
          children: [
            // Nút đóng (vuốt xuống hoặc nhấn nút)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Spacer(),

            // Thumbnail tối giản
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Icon(Icons.audiotrack,
                    size: 100, color: Theme.of(context).colorScheme.primary),
              ),
            ),

            const SizedBox(height: 48),

            // Thông tin bài hát (Typography đậm)
            Text(
              'Tương lai của AI',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Podcast Series',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),

            const SizedBox(height: 48),

            // Custom Progress Bar (Tối giản)
            Column(
              children: [
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.4, // Giả lập tiến trình 40%
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('18:04',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('45:10',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // Controls (Nút to)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, size: 48),
                  onPressed: () {},
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(Icons.pause_rounded,
                      size: 48, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, size: 48),
                  onPressed: () {},
                ),
              ],
            ),

            const Spacer(),

            // Action Lưu vĩnh viễn (Triết lý PMKA)
            FilledButton.icon(
              onPressed: () {
                _showSaveDialog(context);
              },
              icon: const Icon(Icons.save_alt),
              label: const Text('Lưu vĩnh viễn vào máy'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lưu nội dung?'),
        content: const Text(
            'Bạn có muốn chuyển file này từ bộ nhớ tạm sang lưu trữ vĩnh viễn để nghe offline không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Xóa Cache'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Lưu luôn'),
          ),
        ],
      ),
    );
  }
}
