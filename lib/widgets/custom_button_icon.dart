import 'package:flutter/material.dart';
enum IconPosition { left, right }


class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double? height;
  final bool isLoading;
  final Widget? iconOrImage;
  final IconPosition iconPosition;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.color,
    this.textColor,
    this.width,
    this.height = 50.0, // Default height
    this.isLoading = false,
    this.iconOrImage,
    this.iconPosition = IconPosition.left,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity, // Default to full width if not specified
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed, // Disable button when loading
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({}),
          foregroundColor: textColor ?? Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({}),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0), // Consistent with theme
          ),
          textStyle: Theme.of(context).elevatedButtonTheme.style?.textStyle?.resolve({}),
        ).copyWith(
          // Ensure elevation and other properties from theme are kept if not overridden
          elevation: WidgetStateProperty.all(Theme.of(context).elevatedButtonTheme.style?.elevation?.resolve({})),
        ),
        child: isLoading
            ? SizedBox(
                width: 24, // Size of CircularProgressIndicator
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({}) ?? Colors.white
                  ),
                  strokeWidth: 2.0,
                ),
              )
            : iconOrImage != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: iconPosition == IconPosition.left
                        ? [
                            iconOrImage!,
                            const SizedBox(width: 8),
                            Text(
                              text,
                              style: TextStyle(
                                color: textColor ?? Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({}),
                              ),
                            ),
                          ]
                        : [
                            Text(
                              text,
                              style: TextStyle(
                                color: textColor ?? Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            iconOrImage!,
                          ],
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: textColor ?? Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({}),
                    ),
                  ),
      ),
    );
  }
}
