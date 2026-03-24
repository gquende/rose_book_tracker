import 'package:flutter/material.dart';
import '../config/routes.dart';

class BookStatisticsChart extends StatelessWidget {
  final Map<String, int> stats;
  const BookStatisticsChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final int total = stats['total'] ?? 0;
    final Color rosaBebe = const Color(0xFFFFB7C5);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resumo da Estante',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: rosaBebe.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '$total Livros',
                  style: TextStyle(color: rosaBebe, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBar(context, 'Lidos', stats['completed'] ?? 0, total, Colors.green, 'completed'),
          _buildBar(context, 'A ler', stats['currentlyReading'] ?? 0, total, Colors.blue, 'currently-reading'),
          _buildBar(context, 'Quero ler', stats['wantToRead'] ?? 0, total, Colors.orange, 'want-to-read'),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context, String label, int count, int total, Color color, String statusCode) {
    double progress = (total > 0) ? count / total : 0.0;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.bookList, arguments: statusCode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withOpacity(0.1),
                color: color,
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
