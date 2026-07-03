// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/common/theme/app_theme.dart';
import 'package:workout_tracker/common/widgets/myCustomSnackBar.dart';
import 'package:workout_tracker/common/widgets/myCustomeScaffoldView.dart';
import 'package:workout_tracker/common/widgets/uiKit.dart';
import 'package:workout_tracker/home/measure/measures_viewmodel.dart';
import 'package:workout_tracker/home/measure/models/macroResults.dart';
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeRiseIn(index: 0, child: _summaryCard(context, vm)),
                  const SizedBox(height: 12),

                  FadeRiseIn(index: 1, child: _chartCard(vm)),
                  const SizedBox(height: 12),

                  FadeRiseIn(index: 2, child: _addEntryCard(context, df, vm)),
                  const SizedBox(height: 12),

                  FadeRiseIn(index: 3, child: _macrosCard(context, vm)),
                  const SizedBox(height: 12),

                  FadeRiseIn(index: 4, child: _historyCard(df, vm)),
                ],
              ),
            ),
    );
  }

  // ===== Summary (weight + deltas + height + BMI) =====
  Widget _summaryCard(BuildContext context, MeasuresViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final latest = vm.latestWeight;
    final d7 = vm.deltaDays(7);
    final d30 = vm.deltaDays(30);

    final h = vm.heightCm;
    final bmi = vm.bmi;

    Widget deltaPill(String period, double? d) {
      final IconData icon;
      if (d == null || d == 0) {
        icon = Icons.remove_rounded;
      } else if (d > 0) {
        icon = Icons.trending_up_rounded;
      } else {
        icon = Icons.trending_down_rounded;
      }
      final label = d == null
          ? '$period —'
          : '$period ${d >= 0 ? "+" : ""}${d.toStringAsFixed(1)} kg';
      return StatPill(icon: icon, label: label, color: cs.primary);
    }

    return AppCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Current weight', padding: EdgeInsets.zero),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                latest == null ? '—' : latest.toStringAsFixed(1),
                style: tt.displayMedium?.copyWith(color: cs.onSurface),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                  'kg',
                  style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [deltaPill('7d', d7), deltaPill('30d', d30)],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Height',
                  value: h == null ? '—' : h.toStringAsFixed(0),
                  unit: h == null ? '' : 'cm',
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: Theme.of(context).dividerTheme.color,
              ),
              Expanded(
                child: _MiniStat(
                  label: 'BMI',
                  value: bmi == null ? '—' : bmi.toStringAsFixed(1),
                  unit: '',
                ),
              ),
              TextButton(
                onPressed: () => _showHeightDialog(context, vm),
                child: Text(h == null ? 'Set height' : 'Edit'),
              ),
            ],
          ),
        ],
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
            decoration: const InputDecoration(hintText: 'e.g. 175'),
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
            FilledButton(
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
      if (context.mounted) {
        Mycustomsnackbar.show(
          context,
          message: 'Enter a valid height (cm)',
          type: SnackbarType.warning,
        );
      }
      return;
    }

    await vm.setHeightCm(res);
  }

  // ===== Chart =====
  Widget _chartCard(MeasuresViewModel vm) {
    final entries = vm.entries;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Trend', padding: EdgeInsets.only(bottom: 12)),
          SizedBox(height: 210, child: WeightLineChart(entries: entries)),
        ],
      ),
    );
  }

  // ===== Add Entry =====
  Widget _addEntryCard(
    BuildContext context,
    DateFormat df,
    MeasuresViewModel vm,
  ) {
    final cs = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Log weight', padding: EdgeInsets.only(bottom: 12)),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              prefixIcon: Icon(Icons.monitor_weight_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.event_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  df.format(_selectedDate),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
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
          const SizedBox(height: 12),
          VoltButton(
            label: 'Save entry',
            icon: Icons.check_rounded,
            height: 48,
            onPressed: () async {
              final raw = _weightController.text.trim().replaceAll(',', '.');
              final w = double.tryParse(raw);
              if (w == null || w <= 0) {
                Mycustomsnackbar.show(
                  context,
                  message: 'Enter a valid weight',
                  type: SnackbarType.warning,
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
          ),
          const SizedBox(height: 10),
          Text(
            'One entry per day — saving again replaces the same day.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ===== Macros =====
  Widget _macrosCard(BuildContext context, MeasuresViewModel vm) {
    final pack = vm.macrosPack;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Macros',
            padding: const EdgeInsets.only(bottom: 4),
            trailing: TextButton(
              onPressed: () => _showMacrosSettings(context, vm),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Edit'),
            ),
          ),
          Text(
            'Maintenance / Cutting / Bulking based on TDEE.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (pack == null)
            Text(
              'Set height and add a weight entry to calculate macros.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else ...[
            _macroRow(context, 'Maintenance', pack.maintenance,
                Icons.balance_rounded, Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            _macroRow(context, 'Cutting', pack.cutting,
                Icons.trending_down_rounded, context.tokens.warning),
            const SizedBox(height: 8),
            _macroRow(context, 'Bulking', pack.bulking,
                Icons.trending_up_rounded, context.tokens.success),
          ],
        ],
      ),
    );
  }

  Widget _macroRow(
    BuildContext context,
    String title,
    MacroResult r,
    IconData icon,
    Color color,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tt.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'P ${r.proteinG}g · C ${r.carbsG}g · F ${r.fatG}g',
                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${r.calories}',
                style: tt.titleLarge?.copyWith(
                  fontFamily: AppFonts.display,
                  color: color,
                ),
              ),
              Text(
                'kcal',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
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
                          decoration: const InputDecoration(labelText: 'Sex'),
                          items: const [
                            DropdownMenuItem(value: true, child: Text('Male')),
                            DropdownMenuItem(
                              value: false,
                              child: Text('Female'),
                            ),
                          ],
                          onChanged: (v) => setLocal(() => isMale = v ?? true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          initialValue: age.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Age'),
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
                    decoration: const InputDecoration(labelText: 'Activity'),
                    items: activities
                        .map(
                          (a) =>
                              DropdownMenuItem(value: a.$2, child: Text(a.$1)),
                        )
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
            FilledButton(
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

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'History', padding: EdgeInsets.only(bottom: 8)),
          if (entries.isEmpty)
            Text(
              'No entries yet. Add your weight above.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...entries.map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  Icons.monitor_weight_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  '${e.weightKg.toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontFamily: AppFonts.display,
                        fontSize: 15,
                      ),
                ),
                subtitle: Text(
                  df.format(e.date.toLocal()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => vm.deleteEntry(e.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.labelSmall),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: tt.titleLarge?.copyWith(fontFamily: AppFonts.display),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 3),
              Text(unit, style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ],
        ),
      ],
    );
  }
}
