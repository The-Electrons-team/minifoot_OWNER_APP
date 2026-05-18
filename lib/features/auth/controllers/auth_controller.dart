import 'dart:io';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  final isLoading = false.obs;
  final user = Rxn<UserModel>();
  final token = RxnString();

  // States for obscure text (still used in some screens perhaps, but we might remove them later)
  final obscurePass = true.obs;
  final obscureConfirm = true.obs;

  void toggleObscure() => obscurePass.value = !obscurePass.value;
  void toggleObscureConfirm() => obscureConfirm.value = !obscureConfirm.value;

  void goToRegister() => Get.toNamed(Routes.register);
  void goToLogin() => Get.back();
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
    final savedToken = prefs.getString('token');

    if (savedToken == null) return false;

    try {
      final userData = await _authService.getProfile(savedToken);
      token.value = savedToken;
      user.value = UserModel.fromJson(userData);

      // Vérifier le rôle avant toute navigation
      if (user.value?.canUseOwnerApp != true) {
        await prefs.remove('token');
        token.value = null;
        user.value = null;
        return false;
      }

      await NotificationService.syncToken(savedToken);
      goToPostAuthDestination();
      return true;
    } catch (e) {
      prefs.remove('token');
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

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token.value!);
        await NotificationService.syncToken(token.value!);

        goToPostAuthDestination();
      }
    } catch (e) {
      String message = 'Erreur de connexion';
      if (e.toString().contains('COMPTE_NON_TROUVE')) {
        message = 'Compte non trouvé. Veuillez vous inscrire.';
      } else if (e.toString().contains('ID_INVALIDES')) {
        message = 'Mot de passe incorrect.';
      } else if (e.toString().contains('ROLE_NON_AUTORISE')) {
        message =
            'Ce compte est un compte joueur. Utilisez un compte propriétaire ou contrôleur.';
      } else if (e.toString().contains('SERVER_UNAVAILABLE')) {
        message =
            'Serveur indisponible. Vérifiez votre connexion internet puis réessayez.';
      }
      Get.snackbar('Erreur', message, snackPosition: SnackPosition.TOP);
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
      Get.snackbar('Erreur', e.toString().replaceAll('Exception: ', ''));
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> requestPasswordReset(String phone) async {
    isLoading.value = true;
    try {
      await _authService.forgotPassword(phone);
      Get.snackbar(
        'Code envoyé',
        'Un code de réinitialisation a été envoyé',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      String message = 'Impossible d\'envoyer le code';
      if (e.toString().contains('COMPTE_NON_TROUVE')) {
        message = 'Aucun compte trouvé avec ce numéro.';
      }
      Get.snackbar('Erreur', message, snackPosition: SnackPosition.TOP);
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
      
      Get.snackbar(
        'Mot de passe réinitialisé',
        'Connexion automatique en cours...',
        snackPosition: SnackPosition.TOP,
      );
      
      // Auto-login the user immediately after reset
      await startLogin(phone, password);
      
    } catch (e) {
      String message = 'Impossible de réinitialiser le mot de passe';
      if (e.toString().contains('CODE_INVALIDE')) {
        message = 'Code invalide ou expiré.';
      }
      Get.snackbar('Erreur', message, snackPosition: SnackPosition.TOP);
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token.value!);
        await NotificationService.syncToken(token.value!);
        if (redirect) goToPostAuthDestination();
      } else {
        throw Exception('Vérification échouée');
      }
    } catch (e) {
      Get.snackbar('Erreur', e.toString().replaceAll('Exception: ', ''));
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp(String phone) async {
    try {
      await _authService.resendOtp(phone);
      Get.snackbar(
        'Code envoyé',
        'Un nouveau code de vérification vous a été transmis.',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de renvoyer le code. Réessayez plus tard.',
        snackPosition: SnackPosition.TOP,
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
      Get.snackbar(
        'Erreur',
        'Impossible d’envoyer les documents de vérification',
        snackPosition: SnackPosition.TOP,
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

      Get.snackbar(
        'Succès',
        'Mot de passe mis à jour avec succès',
        snackPosition: SnackPosition.TOP,
      );

      goToPostAuthDestination();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de changer le mot de passe');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    token.value = null;
    user.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Get.offAllNamed(Routes.login);
  }
}
