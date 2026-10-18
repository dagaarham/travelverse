import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_exception.dart';
import '../../core/validators.dart';
import '../../providers.dart';
import '../../shared/widgets/common.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> with SubmitValidation<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _phone, _city, _bio;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider).value;
    _name = TextEditingController(text: p?.name);
    _phone = TextEditingController(text: p?.phone);
    _city = TextEditingController(text: p?.homeCity);
    _bio = TextEditingController(text: p?.bio);
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _city, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!validateForm(_formKey)) return;
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(userRepositoryProvider).updateProfile(uid, name: _name.text, phone: _phone.text, homeCity: _city.text, bio: _bio.text);
      showToast('Profile updated');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(profileProvider).value?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        autovalidateMode: autovalidate,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: email,
                enabled: false,
                decoration: const InputDecoration(labelText: 'Email (cannot be changed)', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  hintText: 'e.g. Arham Daga',
                  prefixIcon: Icon(Icons.person_outline),
                  counterText: '',
                ),
                validator: Validators.name,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')), LengthLimitingTextInputFormatter(14)],
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  hintText: '10-digit number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: Validators.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _city,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Home city', hintText: 'e.g. Mumbai', prefixIcon: Icon(Icons.home_outlined)),
                validator: (v) => Validators.text(v, 'Home city', min: 2, max: 40),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bio,
                maxLength: 150,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio (optional)',
                  hintText: 'Tell travellers a little about yourself',
                  alignLabelWithHint: true,
                ),
                validator: (v) => Validators.optionalText(v, 'Bio', max: 150),
              ),
              const SizedBox(height: 20),
              LoadingButton(label: 'Save', loading: _loading, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
