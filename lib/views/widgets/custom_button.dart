// lib/views/widgets/custom_button.dart
import 'package:flutter/material.dart';
import 'package:community_time_bank/utils/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onPressed; // Changed to nullable

  const CustomButton({
    super.key,
    required this.text,
    required this.color,
    this.onPressed, // No longer required
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed, // This now accepts null
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: AppConstants.buttonTextStyle,
      ),
    );
  }
}