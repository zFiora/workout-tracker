import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workout_tracker/home/measure/models/macro_profile.dart';
import 'package:workout_tracker/home/measure/repositeries/macros_profile_repository.dart';
import 'package:workout_tracker/home/measure/repositeries/measures_profile_repository.dart';
import 'package:workout_tracker/home/measure/services/measures_api_service.dart';

/// Sex and date of birth are used for BMR calculations on the Measures tab,
/// but personal profile info is what users expect to find on the Account
/// page, not buried in a "Macros settings" dialog — this is that entry
/// point. Reads/writes the same [MacrosProfileRepository]-backed
/// [MacroProfile] the Measures page uses (single source of truth, just a
/// second doorway into it), and pushes the same way Measures does so both
/// entry points stay in sync.
class PersonalDetailsSheet extends StatefulWidget {
  const PersonalDetailsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PersonalDetailsSheet(),
    );
  }

  @override
  State<PersonalDetailsSheet> createState() => _PersonalDetailsSheetState();
}

class _PersonalDetailsSheetState extends State<PersonalDetailsSheet> {
  final _macrosRepo = MacrosProfileRepository();
  final _profileRepo = MeasuresProfileRepository();
  final _api = MeasuresApiService();

  late MacroProfile _profile = _macrosRepo.getProfile();
  bool _saving = false;

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: _profile.dateOfBirthUtc ?? DateTime(1995, 1, 1),
    );
    if (picked != null) {
      setState(() => _profile = _profile.withDateOfBirth(picked));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _macrosRepo.saveProfile(_profile);
    // Best-effort push, same as the Measures page — offline just leaves it
    // for the next sync, never blocks the local save.
    _api
        .putProfile(macro: _profile, heightCm: _profileRepo.getProfile().heightCm)
        .ignore();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final df = DateFormat('dd MMM yyyy');
    final dob = _profile.dateOfBirthUtc;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Personal Details',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Used for BMR/macro calculations on the Measures tab.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<Sex>(
            value: _profile.sex,
            decoration: const InputDecoration(
              labelText: 'Sex',
              prefixIcon: Icon(Icons.wc_outlined),
            ),
            items: const [
              DropdownMenuItem(
                value: Sex.unspecified,
                child: Text('Prefer not to say'),
              ),
              DropdownMenuItem(value: Sex.male, child: Text('Male')),
              DropdownMenuItem(value: Sex.female, child: Text('Female')),
            ],
            onChanged: (v) => setState(
              () => _profile = _profile.withSex(v ?? Sex.unspecified),
            ),
          ),
          const SizedBox(height: 14),

          InkWell(
            onTap: _pickDob,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date of birth',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
              child: Text(dob == null ? 'Not set' : df.format(dob)),
            ),
          ),
          if (dob == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Using a default age of ${_profile.age} until set.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
