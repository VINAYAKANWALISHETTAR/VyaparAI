import 'package:flutter/material.dart';

class AppShadows {
  static const List<BoxShadow> subtle = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A172B4D),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(
      color: Color(0x12172B4D),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  static const List<BoxShadow> elevated = <BoxShadow>[
    BoxShadow(
      color: Color(0x1F172B4D),
      offset: Offset(0, 8),
      blurRadius: 20,
    ),
  ];
}
