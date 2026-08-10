import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> subtle = [
    BoxShadow(color: Color(0x0A141A14), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> subtleUp = [
    BoxShadow(color: Color(0x0A141A14), blurRadius: 4, offset: Offset(0, -1)),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x12141A14), blurRadius: 12, offset: Offset(0, 3)),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x18141A14), blurRadius: 20, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> float = [
    BoxShadow(color: Color(0x22141A14), blurRadius: 32, offset: Offset(0, 10)),
  ];
}
