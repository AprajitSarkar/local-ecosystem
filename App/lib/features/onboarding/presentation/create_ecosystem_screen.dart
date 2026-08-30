// lib/features/onboarding/presentation/create_ecosystem_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../application/settings_service.dart';

class CreateEcosystemScreen extends StatefulWidget {
  const CreateEcosystemScreen({super.key});

  @override
  State<CreateEcosystemScreen> createState() => _CreateEcosystemScreenState();
}

class _CreateEcosystemScreenState extends State<CreateEcosystemScreen> {
  final _ctrl = TextEditingController(text: 'My Devices');
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final name = _ctrl.text.trim();
      final id = SettingsService.instance.ecosystemId;
      await SettingsService.instance.saveAndActivateEcosystem(
        id: id,
        name: name,
      );
      if (mounted) context.go('/home');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/welcome')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text('Name your ecosystem', style: tt.headlineLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'This name identifies your device group on the local network.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xxl),
                TextFormField(
                  controller: _ctrl,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _create(),
                  decoration: const InputDecoration(
                    labelText: 'Ecosystem name',
                    hintText: 'e.g. Home, Work, Studio',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    if (v.trim().length > 50) {
                      return 'Name is too long';
                    }
                    return null;
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _loading ? null : _create,
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                      : const Text('Create'),
                ),
                const SizedBox(height: AppSpacing.base),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
