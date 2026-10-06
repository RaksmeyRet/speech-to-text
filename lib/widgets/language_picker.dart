import 'package:flutter/material.dart';
import '../models/languages.dart';

void showLanguagePicker(
  BuildContext context,
  String current,
  void Function(String) onSelect,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF101827),
    builder: (_) => ListView(
      children: appLanguages.entries.map((e) {
        return ListTile(
          title: Text(e.value, style: const TextStyle(color: Colors.white)),
          trailing: e.key == current
              ? const Icon(Icons.check, color: Color(0xFFBACCF5))
              : null,
          onTap: () {
            Navigator.pop(context);
            onSelect(e.key);
          },
        );
      }).toList(),
    ),
  );
}