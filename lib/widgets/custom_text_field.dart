import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String placeholder;

  const CustomTextField(
      {super.key, this.controller, required this.placeholder});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: placeholder,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
