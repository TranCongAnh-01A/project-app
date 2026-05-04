import 'package:flutter/material.dart';

class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clean Architecture',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nguồn: Blog IT | Ngày lưu: 10/04/2026',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Divider(height: 32),
          const Text(
            'Clean Architecture là một mô hình kiến trúc phần mềm được giới thiệu bởi Robert C. Martin (Uncle Bob)... \n\n'
            'Mục tiêu cốt lõi của nó là sự phân tách các mối quan tâm (Separation of Concerns). '
            'Nó đạt được điều này bằng cách chia phần mềm thành các lớp hình tròn. \n\n'
            '1. Entities: Chứa các quy tắc nghiệp vụ cốt lõi.\n'
            '2. Use Cases: Chứa các quy tắc nghiệp vụ đặc thù của ứng dụng.\n'
            '3. Interface Adapters: Chuyển đổi dữ liệu từ Use Cases sang định dạng phù hợp cho DB/Web.\n'
            '4. Frameworks & Drivers: Chứa các công cụ như Database, Web Framework.\n\n'
            'Nguyên tắc vàng: Phụ thuộc luôn hướng vào bên trong (Dependency Rule).',
            style: TextStyle(fontSize: 16, height: 1.6),
          ),
        ],
      ),
    );
  }
}
