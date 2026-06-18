import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:poketto/core/network/api_exception.dart';
import 'package:poketto/data/repositories/app_repositories.dart';
import 'package:poketto/home.dart';
import 'package:poketto/manage_categories_page.dart';
import 'package:poketto/monthly_overview_page.dart';
import 'package:poketto/budget_settings_page.dart';
import 'package:poketto/onboarding_screen.dart';
import 'package:poketto/providers/user_provider.dart';
import 'package:poketto/providers/theme_controller.dart';
import 'package:poketto/ui/app_theme.dart';
import 'package:poketto/ui/auth_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await initializeDateFormatting('id', null);
  Intl.defaultLocale = 'id_ID';
  final themeController = await ThemeController.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider.value(value: themeController),
      ],
      child: const MyApp(),
    ),
  );

  // Notification setup may wait on an Android permission/service response.
  // Keep it off the critical path so the first Flutter frame is never blocked.
  unawaited(_initializeNotifications());
}

Future<void> _initializeNotifications() async {
  try {
    await AppRepositories.notifications.initialize();
  } catch (error) {
    debugPrint('Notification initialization failed: $error');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeController>().themeMode;
    return MaterialApp(
      title: 'Poketto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      // The app always starts with the LaunchScreen
      home: const LaunchScreen(),
      // Define all the navigation routes
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/history': (context) => const MonthlyOverviewPage(),
        '/categories': (context) => const ManageCategoriesPage(),
        '/settings': (context) => const BudgetSettingsPage(),
      },
    );
  }
}

// LAYAR LAUNCH (1-A) - UPDATED TO BE STATEFUL
class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserStatusAndNavigate();
  }

  Future<void> _checkUserStatusAndNavigate() async {
    // Wait for a couple of seconds for the splash screen
    await Future.delayed(
        const Duration(seconds: 2)); // Biarkan splash screen terlihat
    if (!mounted) return;

    final remoteSession = await AppRepositories.auth.restoreRemoteSession();
    if (remoteSession != null && mounted) {
      Provider.of<UserProvider>(context, listen: false).setUser(
        remoteSession.user.id,
        remoteSession.user.name,
        remoteSession.user.email,
        token: remoteSession.token,
        isRemoteSession: true,
      );
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    final onboardingCompleted =
        prefs.getBool('poketto_onboarding_completed') ?? false;

    if (!mounted) return;
    if (onboardingCompleted) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF201A16), Color(0xFF0D0B0A)]
                : const [Color(0xFFFFFBF7), Color(0xFFFFE4D0)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: context.poketto.border),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(.16),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Image.asset('assets/cat_pixel.png'),
              ),
              const SizedBox(height: 20),
              Text(
                'POKETTO',
                style: AppTextStyles.hero.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text('Keuangan teratur, hidup lebih tenang',
                  style: TextStyle(color: context.poketto.mutedText)),
            ],
          ),
        ),
      ),
    );
  }
}

// LAYAR LOGIN (Updated)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final session = await AppRepositories.auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');

      Provider.of<UserProvider>(context, listen: false).setUser(
        session.user.id,
        session.user.name,
        session.user.email,
        token: session.token,
        isRemoteSession: true,
      );

      Navigator.pushReplacementNamed(context, '/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.userMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PokettoAuthShell(
      eyebrow: 'Selamat datang',
      title: 'Masuk ke Poketto',
      subtitle:
          'Lanjutkan pencatatan dan lihat kesehatan finansialmu dalam satu tempat.',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const ValueKey('login-email'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email tidak boleh kosong';
                }
                if (!value.contains('@')) return 'Email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: PokettoSpacing.md),
            TextFormField(
              key: const ValueKey('login-password'),
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_isLoading) _handleLogin();
              },
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Tampilkan password'
                      : 'Sembunyikan password',
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password tidak boleh kosong';
                }
                if (value.length < 6) return 'Password minimal 6 karakter';
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Fitur reset password belum tersedia')),
                ),
                child: const Text('Lupa kata sandi?'),
              ),
            ),
            const SizedBox(height: PokettoSpacing.xs),
            ElevatedButton(
              key: const ValueKey('login-submit'),
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Masuk'),
            ),
          ],
        ),
      ),
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Belum punya akun?',
              style: TextStyle(color: context.poketto.mutedText)),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            child: const Text('Daftar'),
          ),
        ],
      ),
    );
  }
}

// LAYAR REGISTER (Baru)
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final session = await AppRepositories.auth.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (!mounted) return;

      if (session.token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('userId');

        Provider.of<UserProvider>(context, listen: false).setUser(
          session.user.id,
          session.user.name,
          session.user.email,
          token: session.token,
          isRemoteSession: true,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun berhasil dibuat.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun berhasil dibuat. Silakan login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.userMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PokettoAuthShell(
      eyebrow: 'Akun baru',
      title: 'Mulai bersama Poketto',
      subtitle:
          'Buat akun untuk mencatat transaksi, mengatur budget, dan membaca pola pengeluaranmu.',
      showBackButton: true,
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const ValueKey('register-name'),
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nama lengkap',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nama tidak boleh kosong'
                  : null,
            ),
            const SizedBox(height: PokettoSpacing.md),
            TextFormField(
              key: const ValueKey('register-email'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email tidak boleh kosong';
                }
                if (!value.contains('@')) return 'Email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: PokettoSpacing.md),
            TextFormField(
              key: const ValueKey('register-password'),
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Tampilkan password'
                      : 'Sembunyikan password',
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: _validateRegisterPassword,
            ),
            const SizedBox(height: PokettoSpacing.md),
            TextFormField(
              key: const ValueKey('register-confirm-password'),
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_isLoading) _handleRegister();
              },
              decoration: InputDecoration(
                labelText: 'Konfirmasi password',
                prefixIcon: const Icon(Icons.verified_user_outlined),
                suffixIcon: IconButton(
                  tooltip: _obscureConfirmPassword
                      ? 'Tampilkan konfirmasi'
                      : 'Sembunyikan konfirmasi',
                  icon: Icon(_obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Konfirmasi password tidak boleh kosong';
                }
                if (value != _passwordController.text) {
                  return 'Password tidak cocok';
                }
                return null;
              },
            ),
            const SizedBox(height: PokettoSpacing.sm),
            Text(
              'Minimal 8 karakter dengan huruf besar, huruf kecil, angka, dan simbol.',
              style: AppTextStyles.caption
                  .copyWith(color: context.poketto.mutedText),
            ),
            const SizedBox(height: PokettoSpacing.lg),
            ElevatedButton(
              key: const ValueKey('register-submit'),
              onPressed: _isLoading ? null : _handleRegister,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Buat akun'),
            ),
          ],
        ),
      ),
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Sudah punya akun?',
              style: TextStyle(color: context.poketto.mutedText)),
          TextButton(
            onPressed: () => Navigator.maybePop(context),
            child: const Text('Masuk'),
          ),
        ],
      ),
    );
  }

  String? _validateRegisterPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
    if (value.length < 8) return 'Password minimal 8 karakter';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Password perlu huruf besar';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Password perlu huruf kecil';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Password perlu angka';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      return 'Password perlu simbol';
    }
    return null;
  }
}
