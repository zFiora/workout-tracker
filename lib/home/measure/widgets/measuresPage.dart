// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/home/measure/measures_viewmodel.dart';
import 'package:workout_tracker/home/measure/repositeries/macros_profile_repository.dart';
import 'package:workout_tracker/home/measure/repositeries/measures_profile_repository.dart';
import 'package:workout_tracker/home/measure/repositeries/measures_repository.dart';
import 'package:workout_tracker/home/measure/widgets/weight_line_chart.dart';

class MeasuresPage extends StatelessWidget {
  const MeasuresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MeasuresViewModel(
        MeasuresRepository(),
        MeasuresProfileRepository(),
        MacrosProfileRepository(),
      )..load(),
      child: const _MeasuresView(),
    );
  }
}

class _MeasuresView extends StatefulWidget {
  const _MeasuresView();

  @override
  State<_MeasuresView> createState() => _MeasuresViewState();
}

class _MeasuresViewState extends State<_MeasuresView> {
  final _weightController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MeasuresViewModel>();
    final df = DateFormat('EEE, dd MMM yyyy');

    return MyCustomeScaffoldView(
      title: 'Measures',
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _summaryCard(context, vm),
                  const SizedBox(height: 12),

                  _chartCard(vm),
                  const SizedBox(height: 12),

                  _addEntryCard(context, df, vm),
                  const SizedBox(height: 12),

                  _macrosCard(context, vm),
                  const SizedBox(height: 12),

                  _historyCard(df, vm),
                ],
              ),
            ),
    );
  }

  // ===== Summary (weight + deltas + height + BMI) =====
  Widget _summaryCard(BuildContext context, MeasuresViewModel vm) {
    final latest = vm.latestWeight;
    final d7 = vm.deltaDays(7);
    final d30 = vm.deltaDays(30);

    final h = vm.heightCm;
    final bmi = vm.bmi;

    String fmtDelta(double? d) {
      if (d == null) return '—';
      final sign = d >= 0 ? '+' : '';
      return '$sign${d.toStringAsFixed(1)} kg';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current weight',
                          style: TextStyle(fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(
                        latest == null ? '—' : '${latest.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('7d: ${fmtDelta(d7)}'),
                    const SizedBox(height: 6),
                    Text('30d: ${fmtDelta(d30)}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Height: ${h == null ? "Not set" : "${h.toStringAsFixed(0)} cm"}',
                  ),
                ),
                TextButton(
                  onPressed: () => _showHeightDialog(context, vm),
                  child: Text(h == null ? 'Set' : 'Edit'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'BMI: ${bmi == null ? "— (need height + weight)" : bmi.toStringAsFixed(1)}',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHeightDialog(
    BuildContext context,
    MeasuresViewModel vm,
  ) async {
    final controller = TextEditingController(
      text: vm.heightCm?.toStringAsFixed(0) ?? '',
    );

    final res = await showDialog<double?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set height (cm)'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'e.g. 175',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, -1),
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                final raw = controller.text.trim().replaceAll(',', '.');
                final h = double.tryParse(raw);
                Navigator.pop(ctx, h);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (res == null) return;

    if (res == -1) {
      await vm.setHeightCm(null);
      return;
    }

    if (res <= 0 || res > 260) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid height (cm)')),
      );
      return;
    }

    await vm.setHeightCm(res);
  }

  // ===== Chart =====
  Widget _chartCard(MeasuresViewModel vm) {
    final entries = vm.entries;
    final (minY, maxY) = vm.weightRange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          height: 220,
          child: WeightLineChart(entries: entries, minY: minY, maxY: maxY),
        ),
      ),
    );
  }

  // ===== Add Entry =====
  Widget _addEntryCard(BuildContext context, DateFormat df, MeasuresViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add today’s weight',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text(df.format(_selectedDate))),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      initialDate: _selectedDate,
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: const Text('Pick date'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final raw = _weightController.text.trim().replaceAll(',', '.');
                final w = double.tryParse(raw);
                if (w == null || w <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid weight')),
                  );
                  return;
                }

                await vm.addOrReplaceEntry(
                  weightKg: w,
                  dateLocal: DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                  ),
                );

                _weightController.clear();
                setState(() => _selectedDate = DateTime.now());
              },
              child: const Text('Save'),
            ),
            const SizedBox(height: 6),
            const Text(
              'Note: one entry per day. Saving again replaces the same day.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Macros =====
  Widget _macrosCard(BuildContext context, MeasuresViewModel vm) {
    final pack = vm.macrosPack;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Macros',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: () => _showMacrosSettings(context, vm),
                  child: const Text('Edit'),
                )
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Maintenance / Cutting / Bulking based on TDEE.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (pack == null)
              const Text('Set height and add a weight entry to calculate macros.')
            else ...[
              _macroRow('Maintenance', pack.maintenance),
              const Divider(),
              _macroRow('Cutting', pack.cutting),
              const Divider(),
              _macroRow('Bulking', pack.bulking),
            ],
          ],
        ),
      ),
    );
  }

  Widget _macroRow(String title, MacroResult r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text('${r.calories} kcal')),
              Text('P ${r.proteinG}g'),
              const SizedBox(width: 10),
              Text('C ${r.carbsG}g'),
              const SizedBox(width: 10),
              Text('F ${r.fatG}g'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showMacrosSettings(
    BuildContext context,
    MeasuresViewModel vm,
  ) async {
    final activities = <(String label, double factor)>[
      ('Sedentary (1.2)', 1.2),
      ('Light (1.375)', 1.375),
      ('Moderate (1.55)', 1.55),
      ('Very active (1.725)', 1.725),
      ('Athlete (1.9)', 1.9),
    ];

    int age = vm.macroProfile.age;
    bool isMale = vm.macroProfile.isMale;
    double activity = vm.macroProfile.activityFactor;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Macros settings'),
          content: StatefulBuilder(
            builder: (ctx, setLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<bool>(
                          value: isMale,
                          decoration: const InputDecoration(
                            labelText: 'Sex',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: true, child: Text('Male')),
                            DropdownMenuItem(value: false, child: Text('Female')),
                          ],
                          onChanged: (v) => setLocal(() => isMale = v ?? true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          initialValue: age.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            final parsed = int.tryParse(v.trim());
                            if (parsed != null) setLocal(() => age = parsed);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<double>(
                    value: activity,
                    decoration: const InputDecoration(
                      labelText: 'Activity',
                      border: OutlineInputBorder(),
                    ),
                    items: activities
                        .map((a) => DropdownMenuItem(
                              value: a.$2,
                              child: Text(a.$1),
                            ))
                        .toList(),
                    onChanged: (v) => setLocal(() => activity = v ?? 1.375),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Defaults:\nCut = -500 kcal\nBulk = +250 kcal\nProtein: cut 2.2g/kg, maintain 1.8g/kg, bulk 1.6g/kg\nFat: 0.8g/kg',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await vm.setIsMale(isMale);
                await vm.setAge(age);
                await vm.setActivityFactor(activity);
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ===== History =====
  Widget _historyCard(DateFormat df, MeasuresViewModel vm) {
    final entries = vm.entries.reversed.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('History', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (entries.isEmpty)
              const Text('No entries yet. Add your weight above.')
            else
              ...entries.map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${e.weightKg.toStringAsFixed(1)} kg'),
                  subtitle: Text(df.format(e.date.toLocal())),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => vm.deleteEntry(e.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
