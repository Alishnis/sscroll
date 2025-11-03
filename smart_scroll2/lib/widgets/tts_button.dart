import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';

/// Кнопка с поддержкой TTS озвучки
class TTSButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final bool enableTTS;
  final String? ttsText; // Альтернативный текст для озвучки

  const TTSButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.borderRadius,
    this.enableTTS = true,
    this.ttsText,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TTSProvider>(
      builder: (context, ttsProvider, child) {
        return ElevatedButton(
          onPressed: () {
            // Озвучиваем кнопку если TTS включен
            if (enableTTS && ttsProvider.isEnabled && ttsProvider.buttonSoundsEnabled) {
              ttsProvider.speakButton(ttsText ?? text);
            }
            // Выполняем действие кнопки
            onPressed?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon),
                const SizedBox(width: 8),
              ],
              Text(text),
            ],
          ),
        );
      },
    );
  }
}

/// Иконка с поддержкой TTS озвучки
class TTSIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? color;
  final double? size;
  final bool enableTTS;
  final String? ttsText; // Альтернативный текст для озвучки

  const TTSIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    required this.tooltip,
    this.color,
    this.size,
    this.enableTTS = true,
    this.ttsText,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TTSProvider>(
      builder: (context, ttsProvider, child) {
        return IconButton(
          onPressed: () {
            // Озвучиваем кнопку если TTS включен
            if (enableTTS && ttsProvider.isEnabled && ttsProvider.buttonSoundsEnabled) {
              ttsProvider.speakButton(ttsText ?? tooltip);
            }
            // Выполняем действие кнопки
            onPressed?.call();
          },
          icon: Icon(icon, color: color, size: size),
          tooltip: tooltip,
        );
      },
    );
  }
}

/// Плавающая кнопка с поддержкой TTS озвучки
class TTSFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final bool enableTTS;
  final String? ttsText; // Альтернативный текст для озвучки

  const TTSFloatingActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    required this.tooltip,
    this.enableTTS = true,
    this.ttsText,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TTSProvider>(
      builder: (context, ttsProvider, child) {
        return FloatingActionButton(
          onPressed: () {
            // Озвучиваем кнопку если TTS включен
            if (enableTTS && ttsProvider.isEnabled && ttsProvider.buttonSoundsEnabled) {
              ttsProvider.speakButton(ttsText ?? tooltip);
            }
            // Выполняем действие кнопки
            onPressed?.call();
          },
          tooltip: tooltip,
          child: Icon(icon),
        );
      },
    );
  }
}

/// Переключатель с поддержкой TTS озвучки
class TTSSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String title;
  final String? subtitle;
  final IconData? secondary;
  final bool enableTTS;

  const TTSSwitch({
    super.key,
    required this.value,
    this.onChanged,
    required this.title,
    this.subtitle,
    this.secondary,
    this.enableTTS = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TTSProvider>(
      builder: (context, ttsProvider, child) {
        return SwitchListTile(
          value: value,
          onChanged: (newValue) {
            // Озвучиваем действие если TTS включен
            if (enableTTS && ttsProvider.isEnabled && ttsProvider.buttonSoundsEnabled) {
              ttsProvider.speakButton('${title} ${newValue ? 'включено' : 'выключено'}');
            }
            // Выполняем изменение
            onChanged?.call(newValue);
          },
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          secondary: secondary != null ? Icon(secondary) : null,
        );
      },
    );
  }
}

/// Список элементов с поддержкой TTS озвучки
class TTSListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leading;
  final IconData? trailing;
  final VoidCallback? onTap;
  final bool enableTTS;
  final String? ttsText; // Альтернативный текст для озвучки

  const TTSListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enableTTS = true,
    this.ttsText,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TTSProvider>(
      builder: (context, ttsProvider, child) {
        return ListTile(
          leading: leading != null ? Icon(leading) : null,
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: trailing != null ? Icon(trailing) : null,
          onTap: () {
            // Озвучиваем элемент если TTS включен
            if (enableTTS && ttsProvider.isEnabled && ttsProvider.buttonSoundsEnabled) {
              ttsProvider.speakButton(ttsText ?? title);
            }
            // Выполняем действие
            onTap?.call();
          },
        );
      },
    );
  }
}
