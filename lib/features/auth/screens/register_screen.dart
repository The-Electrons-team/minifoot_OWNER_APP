import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_image.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../controllers/auth_controller.dart';
import 'otp_screen.dart';

class RegisterScreen extends GetView<AuthController> {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RegisterFlow();
  }
}

class _RegisterFlow extends StatefulWidget {
  const _RegisterFlow();

  @override
  State<_RegisterFlow> createState() => _RegisterFlowState();
}

class _RegisterFlowState extends State<_RegisterFlow> {
  final AuthController controller = Get.find<AuthController>();
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();

  final prenomCtrl = TextEditingController();
  final nomCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final cniCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  File? profilePhoto;
  File? cniFront;
  File? cniBack;
  int step = 0;

  @override
  void initState() {
    super.initState();
    for (final ctrl in [
      prenomCtrl,
      nomCtrl,
      phoneCtrl,
      cniCtrl,
      passCtrl,
      confirmPassCtrl,
    ]) {
      ctrl.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    prenomCtrl.dispose();
    nomCtrl.dispose();
    phoneCtrl.dispose();
    cniCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  String normalizePhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00221')) digits = digits.substring(5);
    if (digits.startsWith('221')) digits = digits.substring(3);
    return '+221$digits';
  }

  String localPhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00221')) digits = digits.substring(5);
    if (digits.startsWith('221')) digits = digits.substring(3);
    return digits;
  }

  String cleanCni(String value) => value.replaceAll(RegExp(r'\D'), '');

  bool get isInfoValid =>
      prenomCtrl.text.trim().length >= 2 &&
      nomCtrl.text.trim().length >= 2 &&
      localPhone(phoneCtrl.text).length == 9;

  bool get isDocumentValid =>
      cleanCni(cniCtrl.text).length == 13 &&
      profilePhoto != null &&
      cniFront != null &&
      cniBack != null;

  bool get isPasswordValid =>
      AppValidators.password(passCtrl.text.trim()) == null &&
      confirmPassCtrl.text.trim() == passCtrl.text.trim();

  bool get canContinue => step == 0
      ? isInfoValid
      : step == 1
      ? isDocumentValid
      : isPasswordValid;

  Future<void> pickImage(ValueChanged<File> onPicked) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: kBgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 14),
              _SourceTile(
                icon: PhosphorIconsDuotone.camera,
                label: 'Prendre une photo',
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              _SourceTile(
                icon: PhosphorIconsDuotone.image,
                label: 'Choisir depuis la galerie',
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    // Compression avant envoi : une photo d'appareil pèse plusieurs Mo
    // pour un affichage de quelques centaines de pixels.
    if (picked != null) {
      final compressed = await AppImage.compress(File(picked.path));
      setState(() => onPicked(compressed));
    }
  }

  void next() {
    if (step == 0) {
      final phone = localPhone(phoneCtrl.text);
      phoneCtrl.text = phone;
      if (!isInfoValid) {
        AppSnackbar.warning('Renseignez votre prénom, nom et les 9 chiffres du téléphone.');
        return;
      }
    }

    if (step == 1) {
      cniCtrl.text = cleanCni(cniCtrl.text);
      if (!isDocumentValid) {
        AppSnackbar.warning('La CNI doit contenir 13 chiffres, avec photo profil, recto et verso.');
        return;
      }
    }

    if (step < 2) {
      setState(() => step++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> submit() async {
    final password = passCtrl.text.trim();
    final passwordError = AppValidators.password(password);
    if (passwordError != null) {
      AppSnackbar.warning('$passwordError.');
      return;
    }
    if (password != confirmPassCtrl.text.trim()) {
      AppSnackbar.warning('Les mots de passe ne correspondent pas.');
      return;
    }

    final phone = normalizePhone(phoneCtrl.text);
    await controller.startSignup(
      phone: phone,
      firstName: prenomCtrl.text.trim(),
      lastName: nomCtrl.text.trim(),
      password: password,
      cniNumber: cleanCni(cniCtrl.text),
    );

    Get.to(
      () => OtpScreen(
        phone: phone,
        isNewUser: true,
        cniNumber: cleanCni(cniCtrl.text),
        profilePhotoPath: profilePhoto!.path,
        cniFrontPath: cniFront!.path,
        cniBackPath: cniBack!.path,
      ),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 350),
    );
  }

  /// `true` si l'utilisateur a commencé à remplir le dossier d'inscription.
  bool get _hasUnsavedInput =>
      step > 0 ||
      prenomCtrl.text.trim().isNotEmpty ||
      nomCtrl.text.trim().isNotEmpty ||
      cniCtrl.text.trim().isNotEmpty ||
      profilePhoto != null ||
      phoneCtrl.text.trim().isNotEmpty ||
      passCtrl.text.trim().isNotEmpty ||
      cniFront != null ||
      cniBack != null;

  Future<void> back() async {
    if (step == 0) {
      if (_hasUnsavedInput &&
          !await AppDialog.confirmDiscard(
            message:
                'Vos informations et documents saisis seront perdus.',
          )) {
        return;
      }
      Get.back();
      return;
    }
    setState(() => step--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Intercepte le retour matériel : sans cela l'inscription — pièces
    // d'identité comprises — est détruite sans avertissement.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        back();
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              Row(
                children: [
                  GestureDetector(
                    onTap: back,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        PhosphorIconsBold.caretLeft,
                        color: kTextPrim,
                        size: 24,
                      ),
                    ),
                  ).animate().fadeIn(duration: 250.ms),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'MINIFOOT',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          color: kGreen,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                step == 0
                    ? 'Créer votre compte'
                    : step == 1
                    ? 'Vérification'
                    : 'Mot de passe',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  color: kTextPrim,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step == 0
                    ? 'Quelques informations pour ouvrir votre espace gérant.'
                    : step == 1
                    ? 'Ajoutez vos documents pour la validation admin.'
                    : 'Choisissez un mot de passe pour sécuriser le compte.',
                style: const TextStyle(
                  color: kTextSub,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              _StepperDots(active: step),
              const SizedBox(height: 22),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _InfoStep(
                      firstNameCtrl: prenomCtrl,
                      lastNameCtrl: nomCtrl,
                      phoneCtrl: phoneCtrl,
                    ),
                    _DocumentStep(
                      cniCtrl: cniCtrl,
                      profilePhoto: profilePhoto,
                      cniFront: cniFront,
                      cniBack: cniBack,
                      onProfile: () => pickImage((file) => profilePhoto = file),
                      onFront: () => pickImage((file) => cniFront = file),
                      onBack: () => pickImage((file) => cniBack = file),
                    ),
                    _PasswordStep(
                      passwordCtrl: passCtrl,
                      confirmCtrl: confirmPassCtrl,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : !canContinue
                        ? null
                        : step == 2
                        ? submit
                        : next,
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(step == 2 ? 'Créer mon compte' : 'Continuer'),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: controller.goToLogin,
                  child: const Text(
                    'Déjà un compte ? Se connecter',
                    style: TextStyle(
                      color: kGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoStep extends StatelessWidget {
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController phoneCtrl;

  const _InfoStep({
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.phoneCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          _InputField(
            controller: firstNameCtrl,
            label: 'Prénom',
            hint: 'Mamadou',
            icon: PhosphorIconsDuotone.user,
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: lastNameCtrl,
            label: 'Nom',
            hint: 'Diallo',
            icon: PhosphorIconsDuotone.userCircle,
          ),
          const SizedBox(height: 14),
          _PhoneField(controller: phoneCtrl),
        ],
      ),
    );
  }
}

class _DocumentStep extends StatelessWidget {
  final TextEditingController cniCtrl;
  final File? profilePhoto;
  final File? cniFront;
  final File? cniBack;
  final VoidCallback onProfile;
  final VoidCallback onFront;
  final VoidCallback onBack;

  const _DocumentStep({
    required this.cniCtrl,
    required this.profilePhoto,
    required this.cniFront,
    required this.cniBack,
    required this.onProfile,
    required this.onFront,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          _InputField(
            controller: cniCtrl,
            label: 'Numéro CNI',
            hint: '13 chiffres',
            icon: PhosphorIconsDuotone.identificationCard,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(13),
            ],
          ),
          const SizedBox(height: 14),
          _DocumentPicker(
            label: 'Photo de profil',
            file: profilePhoto,
            icon: PhosphorIconsDuotone.userCircle,
            onTap: onProfile,
          ),
          const SizedBox(height: 12),
          _DocumentPicker(
            label: 'CNI recto',
            file: cniFront,
            icon: PhosphorIconsDuotone.cardholder,
            onTap: onFront,
          ),
          const SizedBox(height: 12),
          _DocumentPicker(
            label: 'CNI verso',
            file: cniBack,
            icon: PhosphorIconsDuotone.cardholder,
            onTap: onBack,
          ),
        ],
      ),
    );
  }
}

/// Étape mot de passe.
///
/// `StatefulWidget` et non `StatelessWidget` : la bascule de visibilité est un
/// état local. Elle vivait dans un `Rx` créé à chaque `build()`, donc recréé à
/// chaque frame et jamais libéré.
class _PasswordStep extends StatefulWidget {
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;

  const _PasswordStep({required this.passwordCtrl, required this.confirmCtrl});

  @override
  State<_PasswordStep> createState() => _PasswordStepState();
}

class _PasswordStepState extends State<_PasswordStep> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          _InputField(
            controller: widget.passwordCtrl,
            label: 'Mot de passe',
            hint: AppValidators.passwordHint,
            icon: PhosphorIconsDuotone.lockSimple,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.newPassword],
            suffix: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              tooltip: _obscure
                  ? 'Afficher le mot de passe'
                  : 'Masquer le mot de passe',
              icon: Icon(
                _obscure
                    ? PhosphorIconsRegular.eyeClosed
                    : PhosphorIconsRegular.eye,
                color: kTextLight,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: widget.confirmCtrl,
            label: 'Confirmer le mot de passe',
            hint: 'Retapez le mot de passe',
            icon: PhosphorIconsDuotone.lockKey,
            obscureText: _obscure,
          ),
        ],
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;

  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Numéro de téléphone',
          style: TextStyle(
            color: kTextSub,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          style: const TextStyle(color: kTextPrim, fontSize: 16),
          decoration: const InputDecoration(
            hintText: '77 XXX XX XX',
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('\u{1F1F8}\u{1F1F3}', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  SizedBox(height: 22, child: VerticalDivider(color: kBorder)),
                ],
              ),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 66),
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final dynamic icon;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _InputField({
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.obscureText = false,
    this.autofillHints,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextSub,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          autofillHints: autofillHints,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: kTextPrim, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: PhosphorIcon(icon, color: kGreen, size: 20),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

class _DocumentPicker extends StatelessWidget {
  final String label;
  final File? file;
  final dynamic icon;
  final VoidCallback onTap;

  const _DocumentPicker({
    required this.label,
    required this.file,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasFile ? kGreen : kBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 58,
                height: 58,
                child: hasFile
                    ? Image.file(file!, fit: BoxFit.cover)
                    : Container(
                        color: kBorder.withValues(alpha: 0.35),
                        child: PhosphorIcon(icon, color: kTextLight, size: 24),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: kTextPrim,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasFile ? 'Image ajoutée' : 'Appuyez pour ajouter',
                    style: TextStyle(
                      color: hasFile ? kGreen : kTextLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            PhosphorIcon(
              hasFile
                  ? PhosphorIconsDuotone.checkCircle
                  : PhosphorIconsDuotone.plusCircle,
              color: hasFile ? kGreen : kTextLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: PhosphorIcon(icon, color: kGreen),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, color: kTextPrim),
      ),
    );
  }
}

class _StepperDots extends StatelessWidget {
  final int active;

  const _StepperDots({required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= active;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 4,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
            decoration: BoxDecoration(
              color: isActive ? kGreen : kBorder,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }),
    );
  }
}
