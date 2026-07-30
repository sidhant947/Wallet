import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/theme_provider.dart';

class ColorPicker extends StatelessWidget {
  final String selectedColor;
  final ValueChanged<String> onColorSelected;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  static const List<String> _presetColors = [
    '#0F0F0F',
    '#0F172A',
    '#1E293B',
    '#1E1B4B',
    '#2E1065',
    '#0C4A6E',
    '#134E4A',
    '#064E3B',
    '#78350F',
    '#4C0519',
    '#2563EB',
    '#7C3AED',
    '#DB2777',
    '#DC2626',
    '#D97706',
    '#059669',
  ];

  Color _parseHex(String hexString) {
    String clean = hexString.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final val = int.tryParse(clean, radix: 16);
      if (val != null) return Color(0xFF000000 | val);
    }
    return const Color(0xFF0F0F0F);
  }

  String _formatHex(Color color) {
    return '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  void _openCustomColorDialog(BuildContext context, Color currentColor) {
    Color tempColor = currentColor;
    final controller = TextEditingController(text: _formatHex(currentColor));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Custom Color'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: tempColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Center(
                        child: Text(
                          _formatHex(tempColor),
                          style: TextStyle(
                            color: tempColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Hex Color Code',
                        hintText: '#FF5733',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        final parsed = _parseHex(val);
                        setDialogState(() {
                          tempColor = parsed;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Colors.red,
                        Colors.pink,
                        Colors.purple,
                        Colors.deepPurple,
                        Colors.indigo,
                        Colors.blue,
                        Colors.lightBlue,
                        Colors.cyan,
                        Colors.teal,
                        Colors.green,
                        Colors.lightGreen,
                        Colors.amber,
                        Colors.orange,
                        Colors.deepOrange,
                        Colors.brown,
                        Colors.grey,
                      ].map((c) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              tempColor = c;
                              controller.text = _formatHex(c);
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    onColorSelected(_formatHex(tempColor));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;

    final currentColorHex = selectedColor.startsWith('#')
        ? selectedColor.toUpperCase()
        : '#0F0F0F';
    final currentColor = _parseHex(currentColorHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
          child: Text(
            'CARD COLOR',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Custom Color Picker Button
              GestureDetector(
                onTap: () => _openCustomColorDialog(context, currentColor),
                child: Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const SweepGradient(
                      colors: [
                        Colors.red,
                        Colors.yellow,
                        Colors.green,
                        Colors.cyan,
                        Colors.blue,
                        Colors.purple,
                        Colors.red,
                      ],
                    ),
                    border: Border.all(
                      color: isDark ? Colors.white54 : Colors.black54,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.colorize_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              // Preset Color Swatches
              ..._presetColors.map((hex) {
                final color = _parseHex(hex);
                final isSelected = currentColorHex == hex.toUpperCase();

                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: GestureDetector(
                    onTap: () => onColorSelected(hex),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.white.withValues(alpha: 0.2),
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Icon(
                                Icons.check,
                                color: color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                size: 20,
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

