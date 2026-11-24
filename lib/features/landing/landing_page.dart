import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

/// Preserved original landing page / starter counter page.
///
/// Kept completely intact to honor project preservation requirements.
class OriginalLandingPage extends StatefulWidget {
  const OriginalLandingPage({super.key, required this.title});

  final String title;

  @override
  State<OriginalLandingPage> createState() => _OriginalLandingPageState();
}

class _OriginalLandingPageState extends State<OriginalLandingPage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.dashboard, color: Colors.black87),
            label: const Text('Open Gym Portal', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            onPressed: () => context.go('/dashboard'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    '🏋️ Gym Management Member App Initialized!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Click below to access the Gym Member Portal dashboard:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF84CC16),
                      foregroundColor: const Color(0xFF111418),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Go to Gym Member Dashboard'),
                    onPressed: () => context.go('/dashboard'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
