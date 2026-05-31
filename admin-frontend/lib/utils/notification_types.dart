import 'package:flutter/material.dart';

class NotificationTypes {
  static const manualTypes = [
    'info',
    'warning',
    'success',
    'error',
    'system',
  ];

  static const automatedTypes = [
    'ticket_purchase',
    'ticket_validated',
    'subscription_purchase',
    'refund_approved',
    'password_reset_requested',
    'schedule_change',
    'promotion',
  ];

  static const allTypes = [...manualTypes, ...automatedTypes];

  static const _labels = {
    'info': 'Info',
    'warning': 'Upozorenje',
    'success': 'Uspjeh',
    'error': 'Greška',
    'system': 'Sistem',
    'ticket_purchase': 'Kupovina karte',
    'ticket_validated': 'Validacija karte',
    'subscription_purchase': 'Kupovina pretplate',
    'refund_approved': 'Povrat odobren',
    'password_reset_requested': 'Reset lozinke',
    'schedule_change': 'Promjena rasporeda',
    'promotion': 'Promocija',
  };

  static String label(String type) {
    final normalized = type.trim().toLowerCase();
    return _labels[normalized] ?? _formatUnknown(normalized);
  }

  static Color color(String type) {
    switch (type.trim().toLowerCase()) {
      case 'info':
      case 'password_reset_requested':
      case 'schedule_change':
        return Colors.blue;
      case 'warning':
      case 'promotion':
        return Colors.orange;
      case 'success':
      case 'ticket_purchase':
      case 'ticket_validated':
      case 'subscription_purchase':
      case 'refund_approved':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'system':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  static List<String> typesForForm({String? currentType}) {
    final types = List<String>.from(manualTypes);
    final normalized = currentType?.trim().toLowerCase();
    if (normalized != null &&
        normalized.isNotEmpty &&
        !types.contains(normalized)) {
      types.add(normalized);
    }
    return types;
  }

  static String _formatUnknown(String type) {
    if (type.isEmpty) return 'Nepoznato';
    return type
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
