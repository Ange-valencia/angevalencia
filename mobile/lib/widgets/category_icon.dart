import 'package:flutter/material.dart';

/// Icône d'une catégorie (alignée sur les valeurs `icon` du backend).
IconData categoryIcon(String? name) => switch (name) {
      'smartphone' => Icons.smartphone,
      'laptop' => Icons.laptop,
      'checkroom' => Icons.checkroom,
      'home' => Icons.home,
      'category' => Icons.category_outlined,
      _ => Icons.widgets,
    };