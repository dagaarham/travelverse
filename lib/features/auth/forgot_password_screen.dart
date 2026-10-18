import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_exception.dart';
import '../../core/validators.dart';
import '../../providers.dart';
import '../../shared/widgets/common.dart';
import 'auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> with SubmitValidation<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!validateForm(_formKey)) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      setState(() => _sent = true);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      title: 'Reset password',
      subtitle: 'Enter the email you signed up with and we will send you a reset link.',
      child: _sent
          ? Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.mark_email_read_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text('Check ${_email.text.trim()} for a link to reset your password.', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to login')),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              autovalidateMode: autovalidate,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'e.g. name@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 20),
                  LoadingButton(label: 'Send reset link', loading: _loading, onPressed: _submit),
                ],
              ),
            ),
    );
  }
}
