import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final FocusNode? focusNode;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      focusNode: focusNode,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      // The InputDecoration will now largely be styled by the global InputDecorationTheme
      decoration: InputDecoration(
        hintText: hintText,
        // The prefixIcon color will be determined by the IconTheme or InputDecorator's iconColor.
        // Our theme sets iconColor in IconThemeData and labelStyle/hintStyle in InputDecorationTheme.
        prefixIcon: prefixIcon != null 
            ? Icon(prefixIcon, color: Theme.of(context).inputDecorationTheme.prefixIconColor ?? Theme.of(context).iconTheme.color) 
            : null,
        // border, filled, fillColor, contentPadding, etc., will come from the theme.
      ),
    );
  }
}
