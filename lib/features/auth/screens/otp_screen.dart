import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../controllers/auth_controller.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String? firstName;
  final String? lastName;
  final String? password;
  final String? cniNumber;
  final String? profilePhotoPath;
  final String? cniFrontPath;
  final String? cniBackPath;
  final bool isNewUser;

  const OtpScreen({
    super.key,
    required this.phone,
    this.firstName,
    this.lastName,
    this.password,
    this.cniNumber,
    this.profilePhotoPath,
    this.cniFrontPath,
    this.cniBackPath,
    this.isNewUser = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  int _resendSeconds = 30;
  bool _canResend = false;
  String? _errorMessage;
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _otpFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _resendSeconds = 30;
      _canResend = false;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) {
        setState(() => _canResend = true);
        return false;
      }
      return true;
    });
  }

  void _resendCode() {
    _startCountdown();
    _authController.resendOtp(widget.phone);
  }

  Future<void> _validate() async {
    final code = _otpController.text.trim();
    final codeError = AppValidators.otp(code);
    if (codeError != null) {
      setState(() => _errorMessage = codeError);
      return;
    }

    setState(() => _errorMessage = null);

    if (widget.isNewUser) {
      try {
        // Phase 1 : Validation strict de l'OTP (active le compte côté backend)
        await _authController.verifyOtp(
          phone: widget.phone,
          code: code,
          redirect: false, // On ne redirige pas encore
        );
      } catch (e) {
        if (mounted) {
          setState(
            () => _errorMessage = 'Code invalide ou expiré. Veuillez réessayer.',
          );
        }
        return; // Arrêt critique si le code est faux
      }

      // Si on arrive ici, l'OTP est BON et le compte est ACTIVÉ en BDD.
      // Phase 2 : Upload des photos de vérification.
      // Même si l'upload échoue (ex: bucket S3 non créé sur la prod), l'utilisateur ne doit plus être bloqué.
      if (widget.cniNumber != null &&
          widget.profilePhotoPath != null &&
          widget.cniFrontPath != null &&
          widget.cniBackPath != null) {
        try {
          await _authController.uploadOwnerDocuments(
            cniNumber: widget.cniNumber!,
            profilePhoto: File(widget.profilePhotoPath!),
            cniFront: File(widget.cniFrontPath!),
            cniBack: File(widget.cniBackPath!),
          );
        } catch (e) {
          // Alerte silencieuse : on ne bloque pas la redirection !
          AppSnackbar.warning('Vérification réussie, mais l\'envoi des pièces justificatives a échoué. Contactez le support ou réessayez plus tard.');
        }
      }

      // Phase 3 : Redirection vers la page d'attente (ou home)
      _authController.goToPostAuthDestination();
    } else {
      // Cas classique de validation OTP
      try {
        await _authController.verifyOtp(
          phone: widget.phone,
          code: code,
          redirect: true,
        );
      } catch (e) {
        if (mounted) {
          setState(
            () => _errorMessage = 'Code incorrect ou expiré.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: Get.back,
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kBgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              PhosphorIconsRegular.caretLeft,
              color: kTextPrim,
              size: 18,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: PhosphorIcon(PhosphorIconsDuotone.deviceMobile,
                  color: kGreen,
                  size: 36,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 28),

              const Text(
                    'Vérification OTP',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: kTextPrim,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 10),

              Text(
                'Code envoyé au\n\u{1F1F8}\u{1F1F3} ${widget.phone.replaceAll('+221', '')}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kTextSub,
                  fontSize: 14,
                  height: 1.6,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

              const SizedBox(height: 40),

              GestureDetector(
                onTap: () => _otpFocusNode.requestFocus(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Les 6 cases faisaient 44 pt + 8 pt de marge = 312 pt,
                    // pour 264 pt disponibles sur un écran de 320 pt : le
                    // débordement était garanti. `LayoutBuilder` répartit la
                    // largeur réelle au lieu de la supposer.
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 8.0;
                        final available = constraints.maxWidth;
                        final boxWidth =
                            ((available -
                                        gap * (AppValidators.otpLength - 1)) /
                                    AppValidators.otpLength)
                                .clamp(34.0, 44.0);

                        return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(AppValidators.otpLength, (i) {
                        final code = _otpController.text;
                        final char = code.length > i ? code[i] : '';
                        final isFocused = _otpFocusNode.hasFocus && code.length == i;

                        return Container(
                          width: boxWidth,
                          height: 58,
                          margin: EdgeInsets.only(
                            right: i == AppValidators.otpLength - 1 ? 0 : gap,
                          ),
                          decoration: BoxDecoration(
                            color: kBgSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isFocused ? kGreen : kBorder,
                              width: isFocused ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              char,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: kGreen,
                              ),
                            ),
                          ),
                        );
                      }),
                        );
                      },
                    ),
                    // Fully transparent but functional single TextField
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.0,
                        child: TextField(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          keyboardType: TextInputType.number,
                          maxLength: AppValidators.otpLength,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          // Fait remplir le code automatiquement par iOS et
                          // Android à sa réception. C'est gratuit, et toute
                          // l'authentification de l'app repose sur l'OTP.
                          autofillHints: const [AutofillHints.oneTimeCode],
                          enableInteractiveSelection: true,
                          showCursor: false,
                          onChanged: (val) {
                            setState(() => _errorMessage = null);
                            if (val.length == AppValidators.otpLength) {
                              Future.delayed(const Duration(milliseconds: 200), _validate);
                            }
                          },
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: kRed, fontSize: 13),
                ),
              ],

              const SizedBox(height: 36),

              Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _authController.isLoading.value
                            ? null
                            : _validate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: kGreen.withValues(
                            alpha: 0.5,
                          ),
                          elevation: 0,
                        ),
                        child: _authController.isLoading.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Valider le code',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PhosphorIcon(PhosphorIconsDuotone.checkCircle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 300.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              GestureDetector(
                onTap: _canResend ? _resendCode : null,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: _canResend ? kGreen : kTextLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    decoration: _canResend
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: kGreen,
                  ),
                  child: Text(
                    _canResend
                        ? 'Renvoyer le code'
                        : 'Renvoyer dans $_resendSeconds s',
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 350.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
