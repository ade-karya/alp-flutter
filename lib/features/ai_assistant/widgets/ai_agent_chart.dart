import 'package:flutter/material.dart';

class AIAgentChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool isWizard;

  const AIAgentChart({super.key, required this.data, required this.isWizard});

  @override
  Widget build(BuildContext context) {
    const maxScore = 100.0;
    final primaryColor = isWizard ? const Color(0xFFFFD700) : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isWizard ? Colors.black.withValues(alpha: 0.3) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWizard ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          if (!isWizard)
            BoxShadow(
              color: Colors.grey.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 20, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                'Performa Nilai Siswa',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isWizard ? Colors.white : Colors.black87,
                  fontFamily: isWizard ? 'Cinzel' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...data.map((item) {
            final name = item['name'] as String;
            final score = (item['score'] as num).toDouble();
            final percentage = score / maxScore;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          color: isWizard ? Colors.white70 : Colors.grey[800],
                        ),
                      ),
                      Text(
                        score.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isWizard ? Colors.white12 : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isWizard
                                  ? [
                                      const Color(0xFF4A148C),
                                      const Color(0xFF7B1FA2),
                                    ]
                                  : [Colors.green[400]!, Colors.green[700]!],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              if (isWizard)
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFD700,
                                  ).withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
