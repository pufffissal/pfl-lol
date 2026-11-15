import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// A square game icon loaded from the CDN and cached on disk.
class GameIcon extends StatelessWidget {
  const GameIcon(this.url, {super.key, this.size = 48, this.radius = 8, this.circle = false});

  final String? url;
  final double size;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: Colors.white10,
      child: Icon(Icons.image_outlined, size: size * 0.4, color: Colors.white24),
    );
    final image = url == null
        ? placeholder
        : CachedNetworkImage(
            imageUrl: url!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => placeholder,
          );
    return circle
        ? ClipOval(child: image)
        : ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }
}

/// Empty slot used in item/rune pickers.
class EmptySlot extends StatelessWidget {
  const EmptySlot({super.key, this.size = 48, this.icon = Icons.add, this.circle = false});

  final double size;
  final IconData icon;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(8),
      border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
    ),
    child: Icon(icon, color: AppTheme.gold.withValues(alpha: 0.6), size: size * 0.45),
  );
}

/// Shows loading / error / data states of an [AsyncValue], with retry.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.data, this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) => data(value),
      AsyncError(:final error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.white38),
              const SizedBox(height: 12),
              const Text('Could not load game data.', textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                'Check your internet connection. ($error)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// Section header with a gold title.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(color: AppTheme.gold, letterSpacing: 1.2),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Gold coin amount.
class GoldText extends StatelessWidget {
  const GoldText(this.amount, {super.key, this.style});

  final int amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.monetization_on, size: 14, color: AppTheme.gold),
      const SizedBox(width: 3),
      Text('$amount', style: style ?? Theme.of(context).textTheme.bodySmall),
    ],
  );
}

/// Search field used at the top of list screens.
class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: hint),
  );
}
