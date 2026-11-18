import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'presentation/widgets/theme_toggle_button.dart';

class AuthScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const AuthScreen({super.key, required this.themeNotifier});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // 0 = Login, 1 = Create Account
  int _selectedTab = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Sign In Form Controllers (Phone & Password ONLY)
  final _loginPhoneController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  // Sign Up Form Controllers (Full Name, Phone Number, Gmail, Password)
  final _signupNameController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  bool _obscureSignupPassword = true;

  @override
  void dispose() {
    _loginPhoneController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupPhoneController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    super.dispose();
  }

  String _cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
  }

  String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final user = parts[0];
    final domain = parts[1];
    if (user.length <= 2) return '${user[0]}***@$domain';
    return '${user.substring(0, 2)}***${user.substring(user.length - 1)}@$domain';
  }

  // ─── 1. SIGN IN (Phone Number and Password ONLY) ───────────────────────────
  Future<void> _handleLogin() async {
    final rawPhone = _loginPhoneController.text.trim();
    final password = _loginPasswordController.text;

    if (rawPhone.isEmpty || password.isEmpty) {
      _showError('Please enter both your Phone Number and Password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String targetEmail;

      if (rawPhone.contains('@')) {
        // Fallback in case user typed their email
        targetEmail = rawPhone.toLowerCase();
      } else {
        final cleanNumber = _cleanPhone(rawPhone);
        if (cleanNumber.length < 7) {
          throw 'Please enter a valid phone number (at least 7 digits).';
        }

        // Query Firestore phone_lookup/{phoneNumber} to retrieve associated Gmail
        final lookupDoc = await FirebaseFirestore.instance
            .collection('phone_lookup')
            .doc(cleanNumber)
            .get();

        if (!lookupDoc.exists || lookupDoc.data() == null) {
          throw 'No account found with phone number "$cleanNumber". Please create an account.';
        }

        final data = lookupDoc.data()!;
        targetEmail = (data['email'] as String? ?? '').trim().toLowerCase();
        if (targetEmail.isEmpty) {
          throw 'No Gmail address linked to this phone number.';
        }
      }

      // Sign in behind the scenes using retrieved Gmail & Password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: targetEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Incorrect password. Please try again.';
      } else if (e.code == 'user-not-found') {
        message = 'No user account found. Please sign up.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
      } else {
        message = e.message ?? e.code;
      }
      _showError(message);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ─── 2. SIGN UP (Full Name, Phone Number, Gmail, Password) ──────────────────
  Future<void> _handleSignUp() async {
    final fullName = _signupNameController.text.trim();
    final rawPhone = _signupPhoneController.text.trim();
    final gmail = _signupEmailController.text.trim().toLowerCase();
    final password = _signupPasswordController.text;

    if (fullName.isEmpty || rawPhone.isEmpty || gmail.isEmpty || password.isEmpty) {
      _showError('All fields (Full Name, Phone Number, Gmail, and Password) are required.');
      return;
    }

    if (!gmail.contains('@')) {
      _showError('Please enter a valid Gmail / Email address.');
      return;
    }

    final cleanNumber = _cleanPhone(rawPhone);
    if (cleanNumber.length < 7) {
      _showError('Please enter a valid phone number (at least 7 digits).');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Check if phone is already registered
      final existingPhone = await FirebaseFirestore.instance
          .collection('phone_lookup')
          .doc(cleanNumber)
          .get();

      if (existingPhone.exists) {
        throw 'Phone number "$cleanNumber" is already registered. Please log in.';
      }

      // 2. Create the user in Firebase Auth with Gmail & Password
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: gmail,
        password: password,
      );

      final user = userCredential.user!;
      await user.updateDisplayName(fullName);

      final now = DateTime.now().millisecondsSinceEpoch;

      // 3. Save mapping document in Firestore at phone_lookup/{phoneNumber}
      await FirebaseFirestore.instance.collection('phone_lookup').doc(cleanNumber).set({
        'email': gmail,
        'uid': user.uid,
        'name': fullName,
        'phone': cleanNumber,
        'createdAt': now,
      });

      // 4. Save user profile data in users/{user.uid}
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': fullName,
        'phone': cleanNumber,
        'email': gmail,
        'groupId': 'GORILLA-01',
        'avatar': '🦍',
        'createdAt': now,
        'lastActive': now,
      }, SetOptions(merge: true));

    } on FirebaseAuthException catch (e) {
      String message = 'Sign up failed';
      if (e.code == 'email-already-in-use') {
        message = 'This Gmail address is already in use. Please log in.';
      } else if (e.code == 'weak-password') {
        message = 'The password is too weak.';
      } else {
        message = e.message ?? e.code;
      }
      _showError(message);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ─── 3. FORGOT PASSWORD (Lookup via Phone -> Send Reset Email) ──────────────
  void _showForgotPasswordDialog() {
    final phoneOrEmailCtrl = TextEditingController();
    final isDark = context.isDark;

    showDialog(
      context: context,
      builder: (ctx) {
        bool isDialogLoading = false;
        String? dialogError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: AlertDialog(
                backgroundColor: isDark
                    ? const Color(0xFF101622).withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.96),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.neonCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: AppTheme.neonCyan, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Reset Password',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter your registered Phone Number or Gmail. We will look up your account and dispatch a reset link to your Gmail.',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildFrostedInputField(
                      controller: phoneOrEmailCtrl,
                      label: 'Phone or Gmail',
                      hintText: 'e.g. 01012345678 or athlete@gmail.com',
                      prefixIcon: Icons.contact_phone_rounded,
                      accentColor: AppTheme.neonCyan,
                      isDark: isDark,
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.neonRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.neonRed.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          dialogError!,
                          style: const TextStyle(color: AppTheme.neonRed, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
                actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _buildGradientButton(
                    onPressed: isDialogLoading
                        ? null
                        : () async {
                            final input = phoneOrEmailCtrl.text.trim();
                            if (input.isEmpty) {
                              setDialogState(() => dialogError = 'Please enter your phone number or email.');
                              return;
                            }

                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(ctx);

                            setDialogState(() {
                              isDialogLoading = true;
                              dialogError = null;
                            });

                            try {
                              String emailToSend;
                              if (input.contains('@')) {
                                emailToSend = input.toLowerCase();
                              } else {
                                final clean = _cleanPhone(input);
                                final lookup = await FirebaseFirestore.instance
                                    .collection('phone_lookup')
                                    .doc(clean)
                                    .get();

                                if (!lookup.exists || lookup.data() == null) {
                                  throw 'No account registered with phone number "$clean".';
                                }

                                emailToSend = (lookup.data()!['email'] as String? ?? '').trim().toLowerCase();
                                if (emailToSend.isEmpty) {
                                  throw 'No email found for this phone number.';
                                }
                              }

                              await FirebaseAuth.instance.sendPasswordResetEmail(email: emailToSend);

                              if (!ctx.mounted) return;
                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF0B1B12),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  content: Text(
                                    '✅ Reset link dispatched to ${_maskEmail(emailToSend)}! Check your inbox.',
                                    style: const TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            } catch (e) {
                              setDialogState(() {
                                isDialogLoading = false;
                                dialogError = e.toString();
                              });
                            }
                          },
                    label: 'Send Link',
                    icon: Icons.send_rounded,
                    gradientColors: const [Color(0xFF00E5FF), Color(0xFF00B0FF)],
                    shadowColor: AppTheme.neonCyan,
                    textColor: const Color(0xFF021217),
                    isLoading: isDialogLoading,
                    height: 44,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF260D14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.neonRed, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppTheme.neonRed, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gorilla;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: gc.bgCore,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161F2E).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: ListenableBuilder(
              listenable: widget.themeNotifier,
              builder: (context, _) => ThemeToggleButton(themeNotifier: widget.themeNotifier),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ─── Ambient Glow Mesh 1 (Top Left: Cyan) ─────────────────────────
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? AppTheme.neonCyan : const Color(0xFF38BDF8)).withValues(alpha: isDark ? 0.22 : 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ─── Ambient Glow Mesh 2 (Bottom Right: Green) ────────────────────
          Positioned(
            bottom: -90,
            right: -90,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? AppTheme.neonGreen : const Color(0xFF22C55E)).withValues(alpha: isDark ? 0.20 : 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ─── Ambient Glow Mesh 3 (Center subtle accent) ───────────────────
          Positioned(
            top: 240,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? AppTheme.neonPurple : const Color(0xFFA855F7)).withValues(alpha: isDark ? 0.10 : 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ─── Main Scrollable Area ─────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── Brand Header (Gorilla Badge & Typography) ────────
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFF1E293B).withValues(alpha: 0.9),
                                      const Color(0xFF0F172A).withValues(alpha: 0.9),
                                    ]
                                  : [
                                      Colors.white,
                                      const Color(0xFFF1F5F9),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.neonCyan.withValues(alpha: 0.8),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonCyan.withValues(alpha: isDark ? 0.35 : 0.25),
                                blurRadius: 24,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🦍', style: TextStyle(fontSize: 44)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          'GORILLA',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: 4.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ─── Modern Frosted Glass Card ────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF131A29).withValues(alpha: 0.78),
                                    const Color(0xFF0D121D).withValues(alpha: 0.88),
                                  ]
                                : [
                                    Colors.white.withValues(alpha: 0.92),
                                    const Color(0xFFF1F6FC).withValues(alpha: 0.85),
                                  ],
                          ),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black.withValues(alpha: 0.45) : const Color(0x18000000),
                              blurRadius: 36,
                              spreadRadius: -2,
                              offset: const Offset(0, 18),
                            ),
                            BoxShadow(
                              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.8),
                              blurRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ─── Segmented Pill-Shaped Switcher ────────
                                  _buildSegmentedSwitcher(isDark),

                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: 18),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.neonRed.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.neonRed.withValues(alpha: 0.4), width: 1),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline_rounded, color: AppTheme.neonRed, size: 18),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: const TextStyle(
                                                color: AppTheme.neonRed,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 22),

                                  // ─── Smooth Animated Cross-Fade of Forms ───
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 260),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, 0.03),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _selectedTab == 0
                                        ? KeyedSubtree(
                                            key: const ValueKey('login_form_view'),
                                            child: _buildLoginForm(isDark),
                                          )
                                        : KeyedSubtree(
                                            key: const ValueKey('signup_form_view'),
                                            child: _buildSignUpForm(isDark),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sleek Segmented Pill Switcher with Zero Border Glitches ───────────────
  Widget _buildSegmentedSwitcher(bool isDark) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF090E17).withValues(alpha: 0.85)
            : const Color(0xFFE2EAF5).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              // Vibrant Active Glowing Pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: _selectedTab == 0 ? 0 : pillWidth,
                top: 0,
                bottom: 0,
                width: pillWidth,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00FF88), Color(0xFF00C96A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF88).withValues(alpha: 0.38),
                        blurRadius: 14,
                        spreadRadius: 0,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),

              // Interactive Segment Tabs (No borders, transparent touch targets)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_selectedTab != 0) {
                          setState(() {
                            _selectedTab = 0;
                            _errorMessage = null;
                          });
                        }
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: _selectedTab == 0
                                ? const Color(0xFF02170B)
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            letterSpacing: 0.8,
                            fontFamily: 'Roboto',
                          ),
                          child: const Text('LOGIN'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_selectedTab != 1) {
                          setState(() {
                            _selectedTab = 1;
                            _errorMessage = null;
                          });
                        }
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: _selectedTab == 1
                                ? const Color(0xFF02170B)
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            letterSpacing: 0.8,
                            fontFamily: 'Roboto',
                          ),
                          child: const Text('CREATE ACCOUNT'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── LOGIN FORM ────────────────────────────────────────────────────────────
  Widget _buildLoginForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone Number Input
        _buildFrostedInputField(
          controller: _loginPhoneController,
          label: 'Phone Number',
          hintText: 'e.g. 01012345678 or +1234567890',
          prefixIcon: Icons.phone_iphone_rounded,
          accentColor: AppTheme.neonCyan,
          keyboardType: TextInputType.phone,
          isDark: isDark,
        ),
        const SizedBox(height: 14),

        // Password Input
        _buildFrostedInputField(
          controller: _loginPasswordController,
          label: 'Password',
          hintText: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          accentColor: AppTheme.neonCyan,
          obscureText: _obscureLoginPassword,
          isDark: isDark,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureLoginPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              size: 19,
            ),
            onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
          ),
        ),

        // Forgot Password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordDialog,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                color: AppTheme.neonCyan,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Gradient Action Button (Login)
        _buildGradientButton(
          onPressed: _isLoading ? null : _handleLogin,
          label: 'LOGIN',
          icon: Icons.bolt_rounded,
          gradientColors: const [Color(0xFF00E5FF), Color(0xFF00B0FF), Color(0xFF0288D1)],
          shadowColor: AppTheme.neonCyan,
          textColor: const Color(0xFF021217),
          isLoading: _isLoading,
        ),
      ],
    );
  }

  // ─── SIGN UP FORM ──────────────────────────────────────────────────────────
  Widget _buildSignUpForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Full Name
        _buildFrostedInputField(
          controller: _signupNameController,
          label: 'Full Name',
          hintText: 'e.g. Alex Titan',
          prefixIcon: Icons.person_outline_rounded,
          accentColor: AppTheme.neonGreen,
          textCapitalization: TextCapitalization.words,
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // Phone Number
        _buildFrostedInputField(
          controller: _signupPhoneController,
          label: 'Phone Number',
          hintText: 'e.g. 01012345678 or +1234567890',
          prefixIcon: Icons.phone_iphone_rounded,
          accentColor: AppTheme.neonGreen,
          keyboardType: TextInputType.phone,
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // Gmail Address
        _buildFrostedInputField(
          controller: _signupEmailController,
          label: 'Gmail / Email',
          hintText: 'e.g. athlete@gmail.com',
          prefixIcon: Icons.mail_outline_rounded,
          accentColor: AppTheme.neonGreen,
          keyboardType: TextInputType.emailAddress,
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // Password
        _buildFrostedInputField(
          controller: _signupPasswordController,
          label: 'Password',
          hintText: 'Min 6 characters',
          prefixIcon: Icons.lock_outline_rounded,
          accentColor: AppTheme.neonGreen,
          obscureText: _obscureSignupPassword,
          isDark: isDark,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureSignupPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              size: 19,
            ),
            onPressed: () => setState(() => _obscureSignupPassword = !_obscureSignupPassword),
          ),
        ),

        const SizedBox(height: 20),

        // Gradient Action Button (Sign Up)
        _buildGradientButton(
          onPressed: _isLoading ? null : _handleSignUp,
          label: 'CREATE GORILLA ACCOUNT',
          icon: Icons.fitness_center_rounded,
          gradientColors: const [Color(0xFF00FF88), Color(0xFF00E676), Color(0xFF00C96A)],
          shadowColor: AppTheme.neonGreen,
          textColor: const Color(0xFF021307),
          isLoading: _isLoading,
        ),
      ],
    );
  }

  // ─── Clean Frosted Glass Style Input Field ─────────────────────────────────
  Widget _buildFrostedInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    required Color accentColor,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool isDark = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF141C2B).withValues(alpha: 0.70)
                : Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.09) : Colors.black.withValues(alpha: 0.07),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.20) : Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(prefixIcon, color: accentColor, size: 20),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: accentColor, width: 1.8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: false,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Vibrant Gradient Cyber Button ─────────────────────────────────────────
  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required Color shadowColor,
    required Color textColor,
    bool isLoading = false,
    double height = 52,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? null
            : LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: onPressed == null ? Colors.grey.withValues(alpha: 0.3) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: shadowColor.withValues(alpha: 0.38),
                  blurRadius: 18,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: textColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
