import 'package:balanceup_app/screens/register_screen.dart';
import 'package:balanceup_app/token_store.dart';
import 'package:flutter/material.dart';
import '../api/balanceup_api.dart';

class LoginScreen extends StatefulWidget {
  final BalanceUpApi api;
  final void Function(String token) onLoggedIn;

  const LoginScreen({
    super.key,
    required this.api,
    required this.onLoggedIn,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Login', style: TextStyle(fontSize: 24)),
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Login'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RegisterScreen(
                    api: widget.api,
                    onLoggedIn: widget.onLoggedIn,
                  ),
                ),
              );
            },
            child: const Text('Create account'),
          ),
        ],
      ),
    ),
  );
}


  Future<void> _login() async {
  setState(() => _loading = true);
  try {
    final res = await widget.api.login(
      _email.text.trim(),
      _password.text,
    );
    await TokenStore.save(res.token);
    widget.onLoggedIn(res.token);

    //widget.onLoggedIn(res.token);

  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.toString())));
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

}
