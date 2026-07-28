import 'dart:io';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  final isLoading = false.obs;
  final user = Rxn<UserModel>();
  final token = RxnString();

  // States for obscure text (still used in some screens perhaps, but we might remove them later)
  final obscurePass = true.obs;
  final obscureConfirm = true.obs;
  var _isRevalidatingSession = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _revalidateSessionAfterResume();
    }
  }

  void toggleObscure() => obscurePass.value = !obscurePass.value;
  void toggleObscureConfirm() => obscureConfirm.value = !obscureConfirm.value;

  void goToRegister() => Get.toNamed(Routes.register);
  void goToLogin() => Get.back();

  Future<void> _cacheUser(UserModel value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.cachedUserKey, jsonEncode(value.toJson()));
  }

  Future<UserModel?> _cachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConfig.cachedUserKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> persistCurrentUser(UserModel value) async {
    user.value = value;
    await _cacheUser(value);
  }

  Future<void> _revalidateSessionAfterResume() async {
    final currentToken = token.value;
    if (currentToken == null ||
        currentToken.isEmpty ||
        _isRevalidatingSession) {
      return;
    }

    _isRevalidatingSession = true;
    try {
      final profile = await _authService.getProfile(currentToken);
      final refreshedToken = await _authService.savedToken() ?? currentToken;
      token.value = refreshedToken;
      user.value = UserModel.fromJson(profile);
      await _cacheUser(user.value!);
    } on SessionExpiredException {
      AppSnackbar.warning('Votre session a expiré. Reconnectez-vous.');
      await logout();
    } catch (_) {
      // Le réseau peut être momentanément indisponible : la session locale
      // reste valide et l'OfflineBanner informe déjà l'utilisateur.
    } finally {
      _isRevalidatingSession = false;
    }
  }

  void goToPostAuthDestination() {
    final current = user.value;
    if (current?.mustChangePassword == true) {
      Get.offAllNamed(Routes.changePassword);
      return;
    }
    if (current?.isOwner == true && current?.isOwnerApproved != true) {
      Get.offAllNamed(Routes.ownerPending);
      return;
    }
    Get.offAllNamed(Routes.dashboard);
  }

  Future<bool> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    var savedToken = prefs.getString(AppConfig.tokenKey);

    if (savedToken == null || savedToken.isEmpty) return false;

    try {
      final userData = await _authService.getProfile(savedToken);
      // After authenticatedRequest, the token in prefs may have been refreshed
      savedToken = prefs.getString(AppConfig.tokenKey) ?? savedToken;
      token.value = savedToken;
      user.value = UserModel.fromJson(userData);

      // Vérifier le rôle avant toute navigation
      if (user.value?.canUseOwnerApp != true) {
        await _authService.clearTokens();
        token.value = null;
        user.value = null;
        return false;
      }

      await _cacheUser(user.value!);
      await NotificationService.syncToken(savedToken);
      return true;
    } catch (e) {
      if (e is SessionExpiredException) {
        token.value = null;
        user.value = null;
        return false;
      }

      // Une API locale indisponible ou une coupure Wi-Fi ne doit pas effacer
      // une session valide. On garde le dernier profil connu et l'app affiche
      // ensuite sa bannière hors-ligne jusqu'au retour du réseau.
      final cached = await _cachedUser();
      if (cached != null && cached.canUseOwnerApp) {
        token.value = savedToken;
        user.value = cached;
        return true;
      }
      return false;
    }
  }

  Future<void> startLogin(String phone, String password) async {
    isLoading.value = true;
    try {
      final res = await _authService.login(phone, password);
      if (res['token'] != null) {
        token.value = res['token'];
        user.value = UserModel.fromJson(res['user']);
        if (user.value?.canUseOwnerApp != true) {
          token.value = null;
          user.value = null;
          throw Exception('ROLE_NON_AUTORISE');
        }

        await _authService.saveTokens(
          token.value!,
          res['refreshToken'] as String?,
        );
        await _cacheUser(user.value!);
        await NotificationService.syncToken(token.value!);

        goToPostAuthDestination();
      }
    } catch (e) {
      String message = 'Impossible de se connecter. Réessayez.';
      if (e.toString().contains('COMPTE_NON_TROUVE')) {
        message =
            'Aucun compte trouvé avec ce numéro. Inscrivez-vous d\'abord.';
      } else if (e.toString().contains('ID_INVALIDES')) {
        message = 'Mot de passe incorrect. Vérifiez et réessayez.';
      } else if (e.toString().contains('ROLE_NON_AUTORISE')) {
        message =
            'Ce numéro correspond à un compte joueur. Utilisez un compte propriétaire.';
      } else if (e.toString().contains('SERVER_UNAVAILABLE')) {
        message = 'Serveur indisponible. Vérifiez votre connexion internet.';
      }
      AppSnackbar.error(message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startSignup({
    required String phone,
    required String firstName,
    required String lastName,
    required String password,
    String? cniNumber,
  }) async {
    isLoading.value = true;
    try {
      await _authService.startSignup(
        phone: phone,
        firstName: firstName,
        lastName: lastName,
        password: password,
        cniNumber: cniNumber,
      );
    } catch (e) {
      final raw = e.toString();
      final String msg;
      if (raw.contains('PHONE_ALREADY_TAKEN') || raw.contains('PHONE_TAKEN')) {
        msg = 'Ce numéro est déjà associé à un compte.';
      } else if (raw.contains('INVALID_PHONE') ||
          raw.contains('PHONE_INVALIDE')) {
        msg = 'Numéro de téléphone invalide.';
      } else {
        msg =
            'Impossible de démarrer l\'inscription. Vérifiez votre connexion.';
      }
      AppSnackbar.error(msg);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> requestPasswordReset(String phone) async {
    isLoading.value = true;
    try {
      await _authService.forgotPassword(phone);
      AppSnackbar.success(
        'Un code de réinitialisation a été envoyé sur WhatsApp.',
      );
    } catch (e) {
      String message = 'Impossible d\'envoyer le code. Réessayez.';
      if (e.toString().contains('COMPTE_NON_TROUVE')) {
        message = 'Aucun compte trouvé avec ce numéro de téléphone.';
      }
      AppSnackbar.error(message);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetForgottenPassword({
    required String phone,
    required String code,
    required String password,
  }) async {
    isLoading.value = true;
    try {
      await _authService.resetPassword(
        phone: phone,
        code: code,
        password: password,
      );

      AppSnackbar.success('Mot de passe réinitialisé. Connexion en cours...');

      // Auto-login the user immediately after reset
      await startLogin(phone, password);
    } catch (e) {
      String message = 'Impossible de réinitialiser le mot de passe.';
      if (e.toString().contains('CODE_INVALIDE')) {
        message = 'Code invalide ou expiré. Demandez un nouveau code.';
      }
      AppSnackbar.error(message);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp({
    required String phone,
    required String code,
    bool redirect = true,
  }) async {
    isLoading.value = true;
    try {
      final res = await _authService.verifyOtp(phone, code);
      if (res['verified'] == true && res['token'] != null) {
        token.value = res['token'];
        user.value = UserModel.fromJson(res['user'] as Map<String, dynamic>);
        if (user.value?.canUseOwnerApp != true) {
          token.value = null;
          user.value = null;
          throw Exception('ROLE_NON_AUTORISE');
        }
        await _authService.saveTokens(
          token.value!,
          res['refreshToken'] as String?,
        );
        await _cacheUser(user.value!);
        await NotificationService.syncToken(token.value!);
        if (redirect) goToPostAuthDestination();
      } else {
        throw Exception('Vérification échouée');
      }
    } catch (e) {
      final raw = e.toString().replaceAll('Exception: ', '');
      final isRole = raw.contains('ROLE_NON_AUTORISE');
      AppSnackbar.error(
        isRole
            ? 'Ce numéro correspond à un compte joueur. Utilisez un compte propriétaire.'
            : 'Code incorrect ou expiré. Vérifiez le code reçu.',
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp(String phone) async {
    try {
      await _authService.resendOtp(phone);
      AppSnackbar.success('Nouveau code envoyé sur WhatsApp.');
    } catch (e) {
      AppSnackbar.error(
        'Impossible de renvoyer le code. Réessayez dans quelques instants.',
      );
    }
  }

  Future<void> uploadOwnerDocuments({
    required String cniNumber,
    required File profilePhoto,
    required File cniFront,
    required File cniBack,
  }) async {
    final currentToken = token.value;
    if (currentToken == null) throw Exception('SESSION_EXPIREE');

    isLoading.value = true;
    try {
      final res = await _authService.uploadOwnerDocuments(
        token: currentToken,
        cniNumber: cniNumber,
        profilePhoto: profilePhoto,
        cniFront: cniFront,
        cniBack: cniBack,
      );
      if (res['user'] is Map<String, dynamic>) {
        user.value = UserModel.fromJson(res['user'] as Map<String, dynamic>);
      }
    } catch (e) {
      AppSnackbar.error(
        'Impossible d\'envoyer les documents. Vérifiez votre connexion et réessayez.',
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changePassword(String newPassword) async {
    final currentToken = token.value;
    if (currentToken == null) throw Exception('SESSION_EXPIREE');

    isLoading.value = true;
    try {
      await _authService.forceChangePassword(
        token: currentToken,
        newPassword: newPassword,
      );

      // Update local user state
      if (user.value != null) {
        user.value = UserModel(
          id: user.value!.id,
          phone: user.value!.phone,
          firstName: user.value!.firstName,
          lastName: user.value!.lastName,
          birthDate: user.value!.birthDate,
          avatarUrl: user.value!.avatarUrl,
          cniNumber: user.value!.cniNumber,
          cniFrontUrl: user.value!.cniFrontUrl,
          cniBackUrl: user.value!.cniBackUrl,
          ownerStatus: user.value!.ownerStatus,
          ownerRejectionReason: user.value!.ownerRejectionReason,
          createdAt: user.value!.createdAt,
          position: user.value!.position,
          payoutWavePhone: user.value!.payoutWavePhone,
          payoutOrangePhone: user.value!.payoutOrangePhone,
          payoutFreePhone: user.value!.payoutFreePhone,
          preferredPayoutMethod: user.value!.preferredPayoutMethod,
          role: user.value!.role,
          mustChangePassword: false,
        );
      }

      AppSnackbar.success('Mot de passe mis à jour avec succès.');
      goToPostAuthDestination();
    } catch (e) {
      AppSnackbar.error('Impossible de changer le mot de passe. Réessayez.');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    token.value = null;
    user.value = null;
    await _authService.clearTokens();
    Get.offAllNamed(Routes.login);
  }
}
