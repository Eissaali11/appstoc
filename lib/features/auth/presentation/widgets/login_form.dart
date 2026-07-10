import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/ui_helper.dart';

class LoginForm extends StatefulWidget {
  final AuthController controller;

  const LoginForm({super.key, required this.controller});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _usernameFocused = false;
  bool _passwordFocused = false;

  @override
  void initState() {
    super.initState();
    // React to authentication errors
    ever(widget.controller.errorRx, (String? errorMessage) {
      if (errorMessage != null && errorMessage.isNotEmpty) {
        UIHelper.showErrorSnackBar(errorMessage);
      }
    });

    _usernameFocus.addListener(() {
      if (mounted) setState(() => _usernameFocused = _usernameFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      if (mounted) setState(() => _passwordFocused = _passwordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      widget.controller.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Username Field ────────────────────────────────
            _buildLabel('اسم المستخدم', Icons.person_outline_rounded),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _usernameController,
              focusNode: _usernameFocus,
              isFocused: _usernameFocused,
              hint: 'أدخل اسم المستخدم',
              icon: Icons.person_rounded,
              accentColor: AppColors.primary,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_passwordFocus),
              validator: (value) => Validators.required(value),
              enabled: !widget.controller.isLoading,
            ),

            const SizedBox(height: 20),

            // ── Password Field ────────────────────────────────
            _buildLabel('كلمة المرور', Icons.lock_outline_rounded),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              isFocused: _passwordFocused,
              hint: 'أدخل كلمة المرور',
              icon: Icons.lock_rounded,
              accentColor: AppColors.accentPurple,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    key: ValueKey(_obscurePassword),
                    color: _passwordFocused
                        ? AppColors.accentPurple
                        : Colors.white30,
                    size: 20,
                  ),
                ),
              ),
              validator: (value) => Validators.required(value),
              enabled: !widget.controller.isLoading,
            ),

            const SizedBox(height: 32),

            // ── Login Button ─────────────────────────────────
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 14),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: Colors.white54,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String hint,
    required IconData icon,
    required Color accentColor,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    bool enabled = true,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: isFocused
              ? accentColor.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.08),
          width: isFocused ? 1.5 : 1,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        enabled: enabled,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        style: GoogleFonts.cairo(
          fontSize: 15,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(
            fontSize: 14,
            color: Colors.white24,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isFocused
                  ? accentColor.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: isFocused ? accentColor : Colors.white30,
              size: 17,
            ),
          ),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: suffixIcon,
                )
              : null,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          errorStyle: GoogleFonts.cairo(
            fontSize: 11,
            color: AppColors.error,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildLoginButton() {
    return Obx(
      () => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: widget.controller.isLoading
              ? null
              : const LinearGradient(
                  colors: [
                    Color(0xFF00C6A7),
                    Color(0xFF0086D4),
                  ],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
          color: widget.controller.isLoading
              ? Colors.white.withValues(alpha: 0.06)
              : null,
          boxShadow: widget.controller.isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.controller.isLoading ? null : _submit,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: Center(
              child: widget.controller.isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'جاري تسجيل الدخول...',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'دخول',
                          style: GoogleFonts.cairo(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
