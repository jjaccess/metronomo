import 'package:flutter/material.dart';

class VisualIndicator extends StatelessWidget {
  final int totalBeats;
  final ValueNotifier<int> currentBeatNotifier;
  final bool isPlaying;

  const VisualIndicator({
    super.key,
    required this.totalBeats,
    required this.currentBeatNotifier,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder: Solo este pequeño bloque se redibuja en cada golpe
    return ValueListenableBuilder<int>(
      valueListenable: currentBeatNotifier,
      builder: (context, beat, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalBeats, (index) {
            // Lógica para saber qué barra resaltar (el beat anterior al actual del contador)
            int activeIndex = (beat - 1) % totalBeats;
            if (activeIndex < 0) activeIndex = totalBeats - 1;

            bool isActive = isPlaying && index == activeIndex;
            bool isAccent = index == 0;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 10),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 20,
              height: isAccent ? 70 : 45,
              decoration: BoxDecoration(
                color: isActive
                    ? (isAccent ? Colors.orange : Colors.greenAccent)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}
