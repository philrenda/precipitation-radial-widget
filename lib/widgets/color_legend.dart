import 'package:flutter/material.dart';

import '../logic/precipitation_colors.dart';

class ColorLegend extends StatelessWidget {
  const ColorLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: PrecipitationColors.legendEntries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 12,
                decoration: BoxDecoration(
                  color: entry.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
