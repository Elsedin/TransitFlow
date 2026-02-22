import 'package:flutter/material.dart';

class MetricCardEnhanced extends StatelessWidget {
  final String title;
  final String value;
  final String? changeText;
  final bool? isPositiveChange;
  final String? subtitle;

  const MetricCardEnhanced({
    super.key,
    required this.title,
    required this.value,
    this.changeText,
    this.isPositiveChange,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
            ),
            if (changeText != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isPositiveChange == true ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: isPositiveChange == true ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    changeText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isPositiveChange == true ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
