import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<int>? onPageSizeChanged;

  const PaginationBar({
    super.key,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
    this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayTotalPages = totalCount == 0 ? 0 : (totalPages < 1 ? 1 : totalPages);
    final displayPage = totalCount == 0 ? 0 : (page < 1 ? 1 : page);

    final canPrev = onPrev != null && displayPage > 1;
    final canNext = onNext != null && displayTotalPages > 0 && displayPage < displayTotalPages;

    final infoText = Text(
      'Prikazano ${_shownCount(totalCount, displayPage, pageSize)} od $totalCount • Stranica $displayPage od $displayTotalPages',
      style: TextStyle(color: Colors.grey[600]),
    );

    final controls = Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (onPageSizeChanged != null) ...[
          const Text('Po stranici:'),
          DropdownButton<int>(
            value: pageSize,
            isDense: true,
            items: const [
              DropdownMenuItem(value: 5, child: Text('5')),
              DropdownMenuItem(value: 10, child: Text('10')),
              DropdownMenuItem(value: 20, child: Text('20')),
              DropdownMenuItem(value: 50, child: Text('50')),
            ],
            onChanged: (v) {
              if (v != null) onPageSizeChanged!(v);
            },
          ),
        ],
        TextButton.icon(
          onPressed: canPrev ? onPrev : null,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Prethodna'),
        ),
        TextButton.icon(
          onPressed: canNext ? onNext : null,
          icon: const Icon(Icons.chevron_right),
          label: const Text('Sljedeća'),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 520;

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoText,
                const SizedBox(height: 8),
                controls,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: infoText),
              const SizedBox(width: 12),
              controls,
            ],
          );
        },
      ),
    );
  }

  static int _shownCount(int totalCount, int page, int pageSize) {
    if (totalCount <= 0 || page <= 0) return 0;
    final start = (page - 1) * pageSize;
    if (start >= totalCount) return 0;
    final remaining = totalCount - start;
    return remaining >= pageSize ? pageSize : remaining;
  }
}
