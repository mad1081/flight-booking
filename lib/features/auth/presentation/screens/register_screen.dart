import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/validators/auth_validators.dart';
import '../../domain/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({
    super.key,
    this.onSuccess,
    this.onLogin,
    this.onContinueAsGuest,
  });
  final VoidCallback? onSuccess;
  final VoidCallback? onLogin;
  final VoidCallback? onContinueAsGuest;
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
    if (success && mounted) widget.onSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Qanat аккаунтын құрыңыз',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Брондау мен сапарларыңыз әрдайым қолыңызда болады',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _name,
                      validator: AuthValidators.name,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Аты-жөні',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      validator: AuthValidators.email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      validator: AuthValidators.password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Құпиясөз',
                        helperText: 'Кемінде 8 таңба, әріп және сан',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmation,
                      validator: (value) =>
                          AuthValidators.confirmation(value, _password.text),
                      obscureText: _obscure,
                      decoration: const InputDecoration(
                        labelText: 'Құпиясөзді қайталаңыз',
                        prefixIcon: Icon(Icons.verified_user_outlined),
                      ),
                    ),
                    if (auth.hasError) ...[
                      const SizedBox(height: 16),
                      Text(
                        authErrorMessage(auth.error!),
                        style: TextStyle(
                          color:
                              auth.error is EmailConfirmationRequiredException
                              ? colors.primary
                              : colors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Аккаунт құру'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: auth.isLoading ? null : widget.onLogin,
                      child: const Text('Аккаунтым бар — кіру'),
                    ),
                    TextButton(
                      onPressed: auth.isLoading
                          ? null
                          : () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .continueAsGuest();
                              widget.onContinueAsGuest?.call();
                            },
                      child: const Text('Қонақ ретінде жалғастыру'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
