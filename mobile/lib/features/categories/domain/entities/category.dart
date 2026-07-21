import 'package:flutter/material.dart';

/// Maps the backend's plain-string icon key (docs/07_Database.md §5.4,
/// backend/src/database/seeds/system-categories.seed.ts) to a Material
/// icon. The same key set doubles as the icon palette offered when
/// creating a custom category (T2.3), so this map is the single source
/// of truth for both.
const categoryIconChoices = <String, IconData>{
  'shopping_cart': Icons.shopping_cart,
  'directions_car': Icons.directions_car,
  'home': Icons.home,
  'restaurant': Icons.restaurant,
  'local_hospital': Icons.local_hospital,
  'checkroom': Icons.checkroom,
  'celebration': Icons.celebration,
  'wifi': Icons.wifi,
  'school': Icons.school,
  'spa': Icons.spa,
  'card_giftcard': Icons.card_giftcard,
  'credit_card': Icons.credit_card,
  'payments': Icons.payments,
  'attach_money': Icons.attach_money,
  'category': Icons.category,
};

IconData categoryIconData(String key) =>
    categoryIconChoices[key] ?? Icons.category;

class Category {
  const Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    this.parentId,
  });

  final String id;
  final String? userId;
  final String name;
  final String icon;
  final String? parentId;

  bool get isSystem => userId == null;

  IconData get iconData => categoryIconData(icon);

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      name: json['name'] as String,
      icon: json['icon'] as String,
      parentId: json['parentId'] as String?,
    );
  }
}
