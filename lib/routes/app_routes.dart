import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/widgets/app_snackbar.dart';
import '../features/auth/bindings/auth_binding.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/owner_pending_screen.dart';
import '../features/auth/screens/change_password_screen.dart';
import '../features/dashboard/bindings/dashboard_binding.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/terrain/bindings/terrain_binding.dart';
import '../features/terrain/screens/terrain_list_screen.dart';
import '../features/terrain/screens/terrain_detail_screen.dart';
import '../features/terrain/screens/terrain_form_screen.dart';
import '../features/reservations/bindings/reservations_binding.dart';
import '../features/reservations/screens/reservation_detail_screen.dart';
import '../features/reservations/screens/reservations_screen.dart';
import '../features/availability/bindings/availability_binding.dart';
import '../features/availability/screens/availability_screen.dart';
import '../features/payments/bindings/payments_binding.dart';
import '../features/payments/screens/payments_screen.dart';
import '../features/notifications/bindings/notifications_binding.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/profile/bindings/profile_binding.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/security_screen.dart';
import '../features/profile/screens/payment_methods_screen.dart';
import '../features/revenues/bindings/revenues_binding.dart';
import '../features/revenues/screens/revenues_screen.dart';
import '../features/chat/bindings/chat_binding.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/qr_checkin/bindings/qr_checkin_binding.dart';
import '../features/qr_checkin/screens/qr_checkin_screen.dart';
import '../features/controllers/bindings/controllers_binding.dart';
import '../features/controllers/screens/controller_detail_screen.dart';
import '../features/controllers/screens/controllers_screen.dart';
import '../features/auth/controllers/auth_controller.dart';

abstract class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const ownerPending = '/owner-pending';
  static const dashboard = '/dashboard';
  static const terrainList = '/terrains';
  static const terrainDetail = '/terrains/detail';
  static const terrainForm = '/terrains/form';
  static const reservations = '/reservations';
  static const reservationDetail = '/reservations/detail';
  static const availability = '/availability';
  static const payments = '/payments';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const security = '/profile/security';
  static const paymentMethods = '/profile/payment-methods';
  static const revenues = '/revenues';
  static const chat = '/chat';
  static const qrCheckIn = '/qr-check-in';
  static const controllers = '/controllers';
  static const controllerDetail = '/controllers/detail';
  static const changePassword = '/auth/change-password';
}

final appPages = [
  // Auth — fade in doux
  GetPage(
    name: Routes.splash,
    page: () => const SplashScreen(),
    binding: AuthBinding(),
    transition: Transition.fadeIn,
    transitionDuration: const Duration(milliseconds: 400),
  ),
  GetPage(
    name: Routes.onboarding,
    page: () => const OnboardingScreen(),
    binding: AuthBinding(),
    transition: Transition.fadeIn,
    transitionDuration: const Duration(milliseconds: 600),
  ),
  GetPage(
    name: Routes.login,
    page: () => const LoginScreen(),
    binding: AuthBinding(),
    transition: Transition.fadeIn,
    transitionDuration: const Duration(milliseconds: 400),
  ),
  GetPage(
    name: Routes.register,
    page: () => const RegisterScreen(),
    binding: AuthBinding(),
    transition: Transition.rightToLeftWithFade,
    transitionDuration: const Duration(milliseconds: 350),
  ),
  GetPage(
    name: Routes.otp,
    page: () => OtpScreen(phone: Get.arguments as String? ?? ''),
    binding: AuthBinding(),
    transition: Transition.rightToLeftWithFade,
    transitionDuration: const Duration(milliseconds: 350),
  ),

  // Dashboard — zoom in depuis le login
  GetPage(
    name: Routes.dashboard,
    page: () => const DashboardScreen(),
    binding: DashboardBinding(),
    transition: Transition.zoom,
    transitionDuration: const Duration(milliseconds: 500),
  ),

  // Features — slide fluide depuis la droite
  GetPage(
    name: Routes.terrainList,
    page: () => const TerrainListScreen(),
    binding: TerrainBinding(),
    transition: Transition.cupertino,
    transitionDuration: const Duration(milliseconds: 300),
  ),
  GetPage(
    name: Routes.terrainDetail,
    page: () => const TerrainDetailScreen(),
    binding: TerrainBinding(),
    transition: Transition.cupertino,
    transitionDuration: const Duration(milliseconds: 300),
  ),
  GetPage(
    name: Routes.terrainForm,
    page: () => const TerrainFormScreen(),
    binding: TerrainBinding(),
    middlewares: [_OwnerOnlyMiddleware()],
    transition: Transition.rightToLeftWithFade,
    transitionDuration: const Duration(milliseconds: 300),
  ),
  GetPage(
    name: Routes.ownerPending,
    page: () => const OwnerPendingScreen(),
    binding: AuthBinding(),
    transition: Transition.fadeIn,
    transitionDuration: const Duration(milliseconds: 350),
  ),
  GetPage(
    name: Routes.reservations,
    page: () => const ReservationsScreen(),
    binding: ReservationsBinding(),
    transition: Transition.cupertino,
    transitionDuration: const Duration(milliseconds: 300),
  ),
  GetPage(
    name: Routes.reservationDetail,
    page: () => const ReservationDetailScreen(),
    binding: ReservationsBinding(),
    transition: Transition.cupertino,
    transitionDuration: const Duration(milliseconds: 300),
  ),
  GetPage(
    name: Routes.availability,
    page: () => const AvailabilityScreen(),
    binding: AvailabilityBinding(),
    transition: Transition.cupertino,
    transitionDuration: const Duration(milliseconds: 300),
  ),
  GetPage(
    name: Routes.payments,
    page: () => const PaymentsScreen(),
    binding: PaymentsBinding(),
    middlewares: [_OwnerOnlyMiddleware()],
    transition: Transition.cupertino,
    transitionDuration: const Duration(milliseconds: 300),
  ),
  GetPage(
    name: Routes.notifications,
    page: () => const NotificationsScreen(),
    binding: NotificationsBinding(),
    transition: Transition.downToUp,
    transitionDuration: const Duration(milliseconds: 300),
  ),
  GetPage(
    name: Routes.profile,
    page: () => const ProfileScreen(),
    binding: ProfileBinding(),
    transition: Transition.downToUp,
    transitionDuration: const Duration(milliseconds: 350),
  ),
  GetPage(
    name: Routes.editProfile,
    page: () => const EditProfileScreen(),
    binding: ProfileBinding(),
    transition: Transition.rightToLeftWithFade,
    transitionDuration: const Duration(milliseconds: 300),
  ),
  GetPage(
    name: Routes.security,
    page: () => const SecurityScreen(),
    binding: ProfileBinding(),
    transition: Transition.rightToLeftWithFade,
    transitionDuration: const Duration(milliseconds: 300),
  ),
  GetPage(
    name: Routes.paymentMethods,
    page: () => const PaymentMethodsScreen(),
    binding: ProfileBinding(),
    middlewares: [_OwnerOnlyMiddleware()],
    transition: Transition.rightToLeftWithFade,
    transitionDuration: const Duration(milliseconds: 300),
  ),
  GetPage(
    name: Routes.revenues,
    page: () => const RevenuesScreen(),
    binding: RevenuesBinding(),
    middlewares: [_OwnerOnlyMiddleware()],
    transition: Transition.cupertino,
    transitionDuration: const Duration(milliseconds: 300),
  ),
  GetPage(
    name: Routes.chat,
    page: () => const ChatListScreen(),
    binding: ChatBinding(),
    transition: Transition.downToUp,
    transitionDuration: const Duration(milliseconds: 300),
  ),
  GetPage(
    name: Routes.qrCheckIn,
    page: () => const QrCheckInScreen(),
    binding: QrCheckInBinding(),
    transition: Transition.cupertino,
    transitionDuration: const Duration(milliseconds: 300),
  ),
  GetPage(
    name: Routes.controllers,
    page: () => const ControllersScreen(),
    binding: ControllersBinding(),
    middlewares: [_OwnerOnlyMiddleware()],
    transition: Transition.cupertino,
    transitionDuration: const Duration(milliseconds: 300),
  ),
  GetPage(
    name: Routes.controllerDetail,
    page: () => const ControllerDetailScreen(),
    binding: ControllersBinding(),
    middlewares: [_OwnerOnlyMiddleware()],
    transition: Transition.cupertino,
    transitionDuration: const Duration(milliseconds: 300),
  ),
  GetPage(
    name: Routes.changePassword,
    page: () => const ForceChangePasswordScreen(),
    binding: AuthBinding(),
    transition: Transition.fadeIn,
    transitionDuration: const Duration(milliseconds: 350),
  ),
];

class _OwnerOnlyMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<AuthController>()) return null;
    final auth = Get.find<AuthController>();
    if (auth.user.value?.isOwner == true &&
        auth.user.value?.isOwnerApproved == true) {
      return null;
    }

    AppSnackbar.warning('Votre compte gérant doit être validé avant cette action.');
    return const RouteSettings(name: Routes.ownerPending);
  }
}
