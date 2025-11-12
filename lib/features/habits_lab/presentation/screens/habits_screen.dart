import 'package:flutter/material.dart';
import '../../../../shared/widgets/ui/background_wrapper.dart';
import '../../../../shared/widgets/ui/acceptance_button.dart';
import 'package:sleepbalance/fitbit_test.dart';

/// Habits Lab screen for sleep habit tracking and experimentation
class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      imagePath: 'assets/images/main_background.png',
      overlayOpacity: 0.3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Habits Lab', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.science,
                      size: 80,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Habits Lab',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Track and experiment with sleep habits',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.white24, height: 1),
            ),
            const SizedBox(height: 12),

            //neuen List (scroll)
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: _SimpleModulesList(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: AcceptanceButton(
                text: 'Save Habits',
                onPressed: () {
                  // Handle save action
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Habits saved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                width: double.infinity,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/fitbit');
              },
              child: const Text('Fitbit verbinden'),
            ),

          ],
        ),
      ),
    );
  }
}

//einfache List mit local state
class _SimpleModulesList extends StatefulWidget {
  const _SimpleModulesList();

  @override
  State<_SimpleModulesList> createState() => _SimpleModulesListState();
}

class _SimpleModulesListState extends State<_SimpleModulesList> {
  // Moduli (titoli in tedesco + emoji, come nello screenshot)
  final List<_Module> _modules = const [
    _Module(id: 'light', title: 'Licht-Therapie', emoji: '🌞'),
    _Module(id: 'sport', title: 'Sport & Bewegung', emoji: '🏃'),
    _Module(id: 'temp', title: 'Temperatur-Exposition', emoji: '🌡️'),
    _Module(id: 'food', title: 'Ernährung', emoji: '🍎'),
    _Module(id: 'meal', title: 'Essenszeiten', emoji: '⏰'),
    _Module(id: 'hyg', title: 'Schlafhygiene', emoji: '🛏️'),
    _Module(id: 'med', title: 'Meditation', emoji: '🧘'),
  ];

  // Welche sind Aktiv (zum Beispiel die erste zwei)
  final Set<String> _active = {'light', 'sport'};

  @override
  Widget build(BuildContext context) {
    final controller = ScrollController();

    return Scrollbar(
        controller: controller,
        thumbVisibility: true, // la barra resta visibile
        radius: const Radius.circular(10),
        thickness: 6,
        child: ListView.separated(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          itemCount: _modules.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final m = _modules[i];
            final isOn = _active.contains(m.id);

            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    // Emoji/icon left
                    Text(m.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),

                    // Title
                    Expanded(
                      child: Text(
                        m.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Checkbox stile einfach
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: isOn,
                        onChanged: (_) {
                          setState(() {
                            if (isOn) {
                              _active.remove(m.id);
                            } else {
                              _active.add(m.id);
                            }
                          });
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        checkColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.7),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // settings
                    _GearButton(onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF2B2F3A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: const Text(
                            'Einstellungen',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: Text(
                            '„${m.title}“ – Einstellungen kommen bald.',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ));
  }
}

/// kleine taste "settings" mit look pill
class _GearButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GearButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: const Icon(Icons.settings, size: 18, color: Colors.white70),
      ),
    );
  }
}

/// minimal Model für die Liste
class _Module {
  final String id;
  final String title;
  final String emoji;
  const _Module({required this.id, required this.title, required this.emoji});
}
