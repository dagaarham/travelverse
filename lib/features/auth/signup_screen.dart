import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_exception.dart';
import '../../core/validators.dart';
import '../../providers.dart';
import '../../shared/widgets/common.dart';
import 'auth_scaffold.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _acceptedTerms = false;
  bool _termsError = false;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _termsError = !_acceptedTerms);
    if (!valid || !_acceptedTerms) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signUp(name: _name.text, email: _email.text, phone: _phone.text, password: _password.text);
      showToast('Account created. Welcome to TravelVerse!');
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
      title: 'Create account',
      subtitle: 'Join a community of travellers sharing honest experiences.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('signup_name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Full name',
                hintText: 'e.g. Prithvi Agarwal',
                prefixIcon: Icon(Icons.person_outline),
                counterText: '',
              ),
              validator: Validators.name,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('signup_email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'e.g. name@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('signup_phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')), LengthLimitingTextInputFormatter(14)],
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                hintText: '10-digit number, e.g. 9876543210',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            PasswordField(
              key: const Key('signup_password'),
              controller: _password,
              label: 'Password',
              hint: 'Create a strong password',
              helperText: 'At least 8 characters with A-Z, a-z, 0-9 and a symbol',
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            PasswordField(
              key: const Key('signup_confirm'),
              controller: _confirm,
              label: 'Confirm password',
              hint: 'Re-enter your password',
              textInputAction: TextInputAction.done,
              validator: (v) => Validators.confirmPassword(v, _password.text),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              key: const Key('signup_terms'),
              value: _acceptedTerms,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() {
                _acceptedTerms = v ?? false;
                _termsError = false;
              }),
              title: const Text('I agree to the community guidelines and privacy policy'),
              subtitle: _termsError
                  ? Text('Please accept the guidelines to continue', style: TextStyle(color: Theme.of(context).colorScheme.error))
                  : null,
            ),
            const SizedBox(height: 12),
            LoadingButton(key: const Key('signup_submit'), label: 'Create account', loading: _loading, onPressed: _submit),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Already have an account?'),
                TextButton(onPressed: () => context.pop(), child: const Text('Log in')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
