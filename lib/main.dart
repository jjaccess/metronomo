import 'package:flutter/material.dart';
import 'metronome_logic.dart';

void main() => runApp(
  const MaterialApp(debugShowCheckedModeBanner: false, home: MetronomoSimple()),
);

class MetronomoSimple extends StatefulWidget {
  const MetronomoSimple({super.key});

  @override
  State<MetronomoSimple> createState() => _MetronomoSimpleState();
}

class _MetronomoSimpleState extends State<MetronomoSimple> {
  final MetronomeLogic _logic = MetronomeLogic();

  // Función para refrescar la pantalla
  void _actualizarUI() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Negro mate
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // --- SECCIÓN 1: INDICADORES VISUALES (BOLITAS) ---
            Column(
              children: [
                Text(
                  "TIEMPO ${_logic.currentBeat + 1}",
                  style: const TextStyle(
                    color: Colors.white24,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 15,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: List.generate(_logic.beatsPerMeasure, (index) {
                    bool esActivo =
                        _logic.isPlaying && _logic.currentBeat == index;
                    bool esAcento = index == 0;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: esActivo ? 24 : 16,
                      height: esActivo ? 24 : 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: esActivo
                            ? (esAcento ? Colors.redAccent : Colors.cyanAccent)
                            : Colors.white10,
                        boxShadow: esActivo
                            ? [
                                BoxShadow(
                                  color:
                                      (esAcento
                                              ? Colors.redAccent
                                              : Colors.cyanAccent)
                                          .withValues(alpha: 0.6),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                    );
                  }),
                ),
              ],
            ),

            // --- SECCIÓN 2: CONTROL DE BPM (NÚMERO Y BOTONES) ---
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _botonAjusteFino(Icons.remove, -1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        children: [
                          Text(
                            "${_logic.bpm}",
                            style: const TextStyle(
                              fontSize: 100,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "BPM",
                            style: TextStyle(color: Colors.cyan, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    _botonAjusteFino(Icons.add, 1),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Slider(
                    value: _logic.bpm.toDouble(),
                    min: 40,
                    max: 240,
                    activeColor: Colors.cyan,
                    inactiveColor: Colors.white10,
                    onChanged: (v) {
                      setState(
                        () => _logic.updateBpm(v.toInt(), _actualizarUI),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Botón Tap Tempo
                GestureDetector(
                  onTap: () {
                    _logic.tapTempo(_actualizarUI);
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 50,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.yellow,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.touch_app,
                          color: Colors.yellow,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "TAP TEMPO${_logic.getTapCount() > 0 ? ' (${_logic.getTapCount()})' : ''}",
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // --- SECCIÓN 3: COMPÁS Y PLAY ---
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _botonCompas("4/4", 4, 4),
                    _botonCompas("6/8", 6, 8),
                    _botonCompas("12/8", 12, 8),
                  ],
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () => setState(() => _logic.toggle(_actualizarUI)),
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _logic.isPlaying
                            ? Colors.redAccent
                            : Colors.cyan,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      _logic.isPlaying
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      size: 70,
                      color: _logic.isPlaying ? Colors.redAccent : Colors.cyan,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget para botones de +1 y -1
  Widget _botonAjusteFino(IconData icono, int valor) {
    return IconButton(
      icon: Icon(icono, color: Colors.white),
      iconSize: 40,
      onPressed: () {
        int nuevoBpm = _logic.bpm + valor;
        if (nuevoBpm >= 40 && nuevoBpm <= 240) {
          setState(() => _logic.updateBpm(nuevoBpm, _actualizarUI));
        }
      },
    );
  }

  // Widget para los botones de selección de compás
  Widget _botonCompas(String texto, int beats, int value) {
    bool seleccionado =
        _logic.beatsPerMeasure == beats && _logic.noteValue == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ChoiceChip(
        label: Text(texto),
        selected: seleccionado,
        selectedColor: Colors.cyan,
        backgroundColor: Colors.white10,
        labelStyle: TextStyle(
          color: seleccionado ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
        onSelected: (bool selected) {
          setState(() => _logic.updateSignature(beats, value, _actualizarUI));
        },
      ),
    );
  }
}
