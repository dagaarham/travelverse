import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_exception.dart';
import '../../core/validators.dart';
import '../../providers.dart';
import '../../shared/widgets/common.dart';
import 'auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SubmitValidation<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!validateForm(_formKey)) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(_email.text, _password.text);
      // Router redirect takes the user to Home once signed in.
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Log in to continue discovering places through travellers you trust.',
      child: Form(
        key: _formKey,
        autovalidateMode: autovalidate,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('login_email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'e.g. aria@gmail.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              PasswordField(
                key: const Key('login_password'),
                controller: _password,
                label: 'Password',
                hint: 'Enter your password',
                validator: Validators.loginPassword,
                textInputAction: TextInputAction.done,
                onSubmitted: _submit,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => context.push('/forgot-password'), child: const Text('Forgot password?')),
              ),
              const SizedBox(height: 8),
              LoadingButton(key: const Key('login_submit'), label: 'Log in', loading: _loading, onPressed: _submit),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text("New to TouchGrass?"),
                  TextButton(onPressed: () => context.push('/signup'), child: const Text('Create an account')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
