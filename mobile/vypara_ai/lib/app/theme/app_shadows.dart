import 'package:flutter/material.dart';

class AppShadows {
  static const List<BoxShadow> subtle = <BoxShadow>[
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];

  static const List<BoxShadow> elevated = <BoxShadow>[
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];
}
