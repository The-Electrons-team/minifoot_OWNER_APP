import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes/app_routes.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import 'auth_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Handler des notifs en arrière-plan (top-level function obligatoire)
// ══════════════════════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase est déjà initialisé par main.dart
  debugPrint('Notif en arrière-plan : ${message.messageId}');
}

// ══════════════════════════════════════════════════════════════════════════════
// Service de notifications push
// ══════════════════════════════════════════════════════════════════════════════

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static bool _isInitialized = false;

  // ── Initialisation ──────────────────────────────────────────────────────────
  static Future<void> init() async {
    _isInitialized = true;
    
    // 1. Handler arrière-plan
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Demande de permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Permission notifs : ${settings.authorizationStatus}');

    // 3. Récupérer le token FCM (en arrière-plan pour ne pas bloquer l'app)
    _messaging.getToken().then((token) async {
      if (token != null) {
        debugPrint('FCM Token : $token');
        final jwt = await _savedJwt();
        if (jwt != null) await _sendToken(jwt, token);
      }
    }).catchError((e) {
      debugPrint('Note : Token FCM non disponible (normal sur compte Apple gratuit ou simulateur).');
    });

    // 4. Écouter les notifs en premier plan
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 5. Tap sur notif quand l'app est en arrière-plan
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // 6. Vérifier si l'app a été ouverte via une notif (app fermée)
    //    On attend que GetMaterialApp soit monté avant de naviguer
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 800), () {
        _handleNavigation(initialMessage);
      });
    }

    // 7. Token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM Token rafraîchi : $newToken');
      final jwt = await _savedJwt();
      if (jwt != null) await _sendToken(jwt, newToken);
    });
  }

  static Future<void> syncToken(String jwt) async {
    if (!_isInitialized) {
      debugPrint('Token FCM propriétaire non synchronisé : Firebase non initialisé.');
      return;
    }
    try {
      final fcmToken = await _messaging.getToken();
      if (fcmToken != null) await _sendToken(jwt, fcmToken);
    } catch (e) {
      debugPrint('Token FCM propriétaire non synchronisé : $e');
    }
  }

  static Future<String?> _savedJwt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.tokenKey);
  }

  static Future<void> _sendToken(String jwt, String fcmToken) async {
    try {
      await AuthService().updateFcmToken(jwt, fcmToken);
    } catch (e) {
      debugPrint('Erreur envoi token FCM propriétaire : $e');
    }
  }

  // ── Notif reçue en premier plan ─────────────────────────────────────────────
  static void _onForegroundMessage(RemoteMessage message) {
    debugPrint('Notif reçue (foreground) : ${message.notification?.title}');
    _showInAppBanner(message);
  }

  // ── Tap sur notif (app en arrière-plan) ─────────────────────────────────────
  static void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('App ouverte via notif : ${message.notification?.title}');
    _handleNavigation(message);
  }

  // ── Afficher une bannière in-app (premier plan) ─────────────────────────────
  static void _showInAppBanner(RemoteMessage message) {
    final title = message.notification?.title ?? 'Nouvelle notification';
    final body  = message.notification?.body ?? '';
    final type  = message.data['type'] as String? ?? 'general';

    final (Color iconColor, Color iconBg, IconData icon) = switch (type) {
      'booking'  => (kBlue,    kBlueLight,  PhosphorIconsRegular.calendarBlank),
      'payment'  => (kGreen,   kGreenLight, PhosphorIconsRegular.money),
      'review'   => (kGold,    kGoldLight,  PhosphorIconsFill.star),
      _          => (kTextSub, kBgSurface,  PhosphorIconsFill.bell),
    };

    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: kBgCard,
      colorText: kTextPrim,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      duration: const Duration(seconds: 4),
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      onTap: (_) => _handleNavigation(message),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ── Navigation selon le type de notif ───────────────────────────────────────
  static void _handleNavigation(RemoteMessage message) {
    final type = message.data['type'] as String? ?? '';
    // L'identifiant d'entité n'était pas exploité : une push « réservation
    // confirmée » ouvrait la *liste*, à charge pour le propriétaire d'y
    // retrouver la bonne ligne.
    final id = (message.data['id'] ?? message.data['entityId'] ?? '').toString();

    switch (type) {
      case 'booking':
        if (id.isNotEmpty) {
          Get.toNamed(Routes.reservationDetail, arguments: id);
        } else {
          Get.toNamed(Routes.reservations);
        }
      case 'payment':
        Get.toNamed(Routes.payments);
      case 'chat':
        Get.toNamed(Routes.chat);
      default:
        Get.toNamed(Routes.notifications);
    }
  }

  // ── Récupérer le token (pour ton backend) ───────────────────────────────────
  static Future<String?> getToken() {
    if (!_isInitialized) return Future.value(null);
    return _messaging.getToken();
  }
}
