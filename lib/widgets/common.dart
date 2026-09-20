import 'package:flutter/material.dart';

/// رنگ‌های ثابت برنامه
class AppColors {
  static const bg = Color(0xFF1C1C20);
  static const surface = Color(0xFF2D2D34);
  static const input = Color(0xFF373741);
  static const primary = Color(0xFF00DCA0);
  static const secondary = Color(0xFF3C82C8);
  static const danger = Color(0xFFB43232);
  static const warning = Color(0xFFC89600);
  static const accentPurple = Color(0xFF960096);
}

/// دکمه اصلی
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    this.color = AppColors.primary,
    required this.onPressed,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: Size(0, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// فیلد متنی استایل‌دار
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int? maxLines;
  final IconData? icon;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: AppColors.input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

/// کارت استایل‌دار
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: margin ?? EdgeInsets.zero,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}

/// دیالوگ تایید
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String message = 'آیا مطمئن هستید؟',
  String confirmText = 'بله',
  String cancelText = 'لغو',
  Color confirmColor = AppColors.danger,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Text(message, style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelText, style: const TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText, style: TextStyle(color: confirmColor)),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// اسنک‌بار
void showSnack(BuildContext context, String message, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// انتخاب تاریخ (میلادی) با دیالوگ
Future<DateTime?> pickDate(BuildContext context, DateTime initial) async {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );
}

/// انتخاب زمان
Future<TimeOfDay?> pickTime(BuildContext context, TimeOfDay initial) async {
  return showTimePicker(
    context: context,
    initialTime: initial,
  );
}