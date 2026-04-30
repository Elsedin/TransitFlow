import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  final int page; // 1-based
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Prikazano ${_shownCount(totalCount, displayPage, pageSize)} od $totalCount • Stranica $displayPage od $displayTotalPages',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Row(
            children: [
              if (onPageSizeChanged != null) ...[
                const Text('Po stranici:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: pageSize,
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
                const SizedBox(width: 16),
              ],
              TextButton.icon(
                onPressed: canPrev ? onPrev : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Prethodna'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: canNext ? onNext : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Sljedeća'),
              ),
            ],
          ),
        ],
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

