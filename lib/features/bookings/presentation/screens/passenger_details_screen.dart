import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qanat/app/router/app_router.dart';
import 'package:qanat/core/design_system/design_system.dart';
import 'package:qanat/features/bookings/domain/booking_models.dart';

class PassengerDetailsScreen extends StatefulWidget {
  const PassengerDetailsScreen({required this.draft, super.key});
  final BookingDraft draft;

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _document = TextEditingController();
  final _citizenship = TextEditingController(text: 'Қазақстан');
  DateTime? _birthDate;
  bool _birthDateMissing = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _document.dispose();
    _citizenship.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Жолаушы деректері')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.section,
        ),
        children: [
          Text('Кім ұшады?', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Деректерді құжаттағыдай енгізіңіз. Құжат нөмірі броньда сақталмайды.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _firstName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Аты'),
            validator: _validateName,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _lastName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Тегі'),
            validator: _validateName,
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: _pickBirthDate,
            borderRadius: AppRadii.medium,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Туған күні',
                errorText: _birthDateMissing ? 'Туған күнді таңдаңыз' : null,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                _birthDate == null ? 'Күнді таңдаңыз' : _date(_birthDate!),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _document,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Құжат нөмірі'),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Құжат нөмірін енгізіңіз';
              if (!RegExp(r'^[A-Za-z0-9]{5,20}$').hasMatch(text)) {
                return '5–20 әріп немесе сан енгізіңіз';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _citizenship,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Азаматтығы'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Азаматтығын енгізіңіз'
                : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _continue,
            child: const Text('Броньды тексеру'),
          ),
        ],
      ),
    ),
  );

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Бұл өрісті толтырыңыз';
    if (name.length < 2) return 'Кемінде 2 таңба енгізіңіз';
    return null;
  }

  Future<void> _pickBirthDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(today.year - 25),
      firstDate: DateTime(1900),
      lastDate: today,
    );
    if (selected != null) {
      setState(() {
        _birthDate = selected;
        _birthDateMissing = false;
      });
    }
  }

  void _continue() {
    final valid = _formKey.currentState!.validate();
    setState(() => _birthDateMissing = _birthDate == null);
    if (!valid || _birthDate == null) return;
    context.push(
      AppRoutes.checkout,
      extra: widget.draft.withPassenger(
        PassengerDetails(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          birthDate: _birthDate!,
          documentNumber: _document.text.trim().toUpperCase(),
          citizenship: _citizenship.text.trim(),
        ),
      ),
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
