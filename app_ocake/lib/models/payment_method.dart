// lib/models/payment_method.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PaymentMethod {
  final String id; // Document ID (sẽ là 'value' như "cash", "card")
  final String title;
  final String subtitle;
  final String iconName; // Tên của Material Icon
  final bool isActive;
  // final int? sortOrder;

  PaymentMethod({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconName,
    required this.isActive,
    // this.sortOrder,
  });

  IconData get icon {
    switch (iconName) {
      case 'attach_money':
        return Icons.attach_money;
      case 'credit_card':
        return Icons.credit_card;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  factory PaymentMethod.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return PaymentMethod(
      id: doc.id,
      title: data['title'] as String? ?? 'Không có tên',
      subtitle: data['subtitle'] as String? ?? '',
      iconName: data['iconName'] as String? ?? 'payment',
      isActive: data['isActive'] as bool? ?? true,
      // sortOrder: data['sortOrder'] as int?,
    );
  }
}
