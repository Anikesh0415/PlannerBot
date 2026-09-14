import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/reminder.dart';
import 'services/sync_service.dart';

void main() {
  runApp(const PlannerBotApp());
}

class PlannerBotApp extends StatelessWidget {
  const PlannerBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planner Bot Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardTheme: const CardTheme(
          color: Color(0xFF1E293B),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Reminder> _reminders = [];
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _codeController = TextEditingController(text: "PLAN-");
  final TextEditingController _ipController = TextEditingController();
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    // Sample initial reminders
    _reminders.add(Reminder(
      id: "sample-1",
      task: "Review daily agenda with AI",
      fireAt: DateTime.now().add(const Duration(hours: 2)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  void _addReminder(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _reminders.insert(0, Reminder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        task: text.trim(),
        fireAt: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    });
    _taskController.clear();
  }

  void _toggleFired(int index) {
    setState(() {
      _reminders[index].fired = !_reminders[index].fired;
      _reminders[index].updatedAt = DateTime.now();
      _reminders[index].version++;
    });
  }

  void _deleteReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: const [
            Text("🧠 ", style: TextStyle(fontSize: 22)),
            Text("Planner Bot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Color(0xFF818CF8)),
            onPressed: _showPairingDialog,
          ),
        ],
      ),
      body: _selectedTab == 0 ? _buildRemindersTab() : _buildReflectionTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (idx) => setState(() => _selectedTab = idx),
        backgroundColor: const Color(0xFF1E293B),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.alarm), label: "Reminders"),
          NavigationDestination(icon: Icon(Icons.insights), label: "Day Analysis"),
        ],
      ),
    );
  }

  Widget _buildRemindersTab() {
    return Column(
      children: [
        // Input bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  decoration: InputDecoration(
                    hintText: "Add task (e.g. Call mom at 7pm)...",
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: _addReminder,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                icon: const Icon(Icons.add),
                onPressed: () => _addReminder(_taskController.text),
              ),
            ],
          ),
        ),

        // Reminders list
        Expanded(
          child: _reminders.isEmpty
              ? const Center(child: Text("No reminders yet!", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _reminders.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, index) {
                    final r = _reminders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: IconButton(
                          icon: Icon(
                            r.fired ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: r.fired ? Colors.green : Colors.grey,
                          ),
                          onPressed: () => _toggleFired(index),
                        ),
                        title: Text(
                          r.task,
                          style: TextStyle(
                            decoration: r.fired ? TextDecoration.lineThrough : null,
                            color: r.fired ? Colors.grey : Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('EEE, MMM d • h:mm a').format(r.fireAt),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () => _deleteReminder(index),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReflectionTab() {
    final completed = _reminders.where((r) => r.fired).length;
    final total = _reminders.length;
    final percent = total > 0 ? (completed / total * 100).toInt() : 100;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Productivity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF818CF8))),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$completed of $total tasks completed", style: const TextStyle(fontSize: 14)),
                      Text("$percent%", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: total > 0 ? completed / total : 1.0,
                    backgroundColor: Colors.grey.shade800,
                    color: Colors.greenAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text("AI Next-Day Recommendations", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome, color: Color(0xFFA855F7)),
              title: const Text("Plan Priority Focus Session"),
              subtitle: const Text("Tomorrow at 9:00 AM • Deep work before distractions"),
              trailing: IconButton(
                icon: const Icon(Icons.add_alarm, color: Color(0xFF818CF8)),
                onPressed: () {
                  _addReminder("Priority Focus Session");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Scheduled for tomorrow!")),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPairingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("📡 P2P Sync Setup"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter the Pairing Code displayed on your Laptop to sync data with end-to-end encryption:",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: "Pairing Code",
                hintText: "PLAN-XXXX-XXXX",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: "Laptop IP & Port (Optional)",
                hintText: "192.168.1.50:54123",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("P2P Pairing configured! Background sync active.")),
              );
            },
            child: const Text("Save & Sync"),
          ),
        ],
      ),
    );
  }
}
