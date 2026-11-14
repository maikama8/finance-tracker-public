import 'package:flutter/material.dart';

import '../core/formatting/money_format.dart';
import 'theme/app_theme.dart';

/// A titled card used by the dashboard sections.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.mutedOf(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(subtitle!, style: TextStyle(color: muted, fontSize: 12)),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// An amount in minor units, formatted for [currency].
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.minor,
    this.currency, {
    this.style,
    this.signed = false,
    super.key,
  });

  final int minor;
  final String currency;
  final TextStyle? style;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final text = signed
        ? formatSignedMinor(minor, currency)
        : formatMinor(minor, currency);
    return Text(text, style: style);
  }
}

/// A label and a value, used in the dashboard summary row.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.mutedOf(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A short explanation for a screen or chart with nothing to show.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.mutedOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 36, color: muted),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Validation message under a form field.
class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(message, style: const TextStyle(color: AppColors.expense));
  }
}
