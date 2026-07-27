import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/owner_ui.dart';
import '../../../routes/app_routes.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          behavior: HitTestBehavior.opaque,
          child: const Center(
            child: PhosphorIcon(PhosphorIcons.caretLeft,
              color: kTextPrim,
              size: 24,
            ),
          ),
        ),
        title: const Text(
          'Profil',
          style: TextStyle(
            color: kTextPrim,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: _openEditProfile,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: PhosphorIcon(PhosphorIconsDuotone.pencilSimpleLine,
                color: kGreen,
                size: 22,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadProfile,
        color: kGreen,
        backgroundColor: kBgCard,
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
          children: [
            _buildIdentityCard(),
            const SizedBox(height: 14),
            _buildStatsRow(),
            const SizedBox(height: 14),
            _buildRevenueCard(),
            const SizedBox(height: 14),
            _buildAccountCard(),
            const SizedBox(height: 16),
            _buildLogoutButton(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kCardShadow,
        ),
        child: Row(
          children: [
            _ProfileAvatar(
              initials: controller.initials,
              imageUrl: controller.avatarUrl.value,
              isUploading: controller.isUploadingAvatar.value,
              onTap: _showAvatarPicker,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.ownerName.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kTextPrim,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    controller.phone.value,
                    style: const TextStyle(
                      color: kTextSub,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: kGreenLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Compte actif',
                      style: TextStyle(
                        color: kGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Obx(
      () => Row(
        children: [
          _StatCard(
            value: '${controller.totalTerrains.value}',
            label: 'Terrains',
            icon: PhosphorIconsDuotone.soccerBall,
            color: kGreen,
            bgColor: kGreenLight,
          ),
          const SizedBox(width: 10),
          _StatCard(
            value: '${controller.totalBookings.value}',
            label: 'Réservations',
            icon: PhosphorIconsDuotone.calendarBlank,
            color: kBlue,
            bgColor: kBlueLight,
          ),
          const SizedBox(width: 10),
          _StatCard(
            value: controller.rating.value.toStringAsFixed(1),
            label: 'Note',
            icon: PhosphorIconsDuotone.star,
            color: kGold,
            bgColor: kGoldLight,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kCardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: kGoldLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: PhosphorIcon(PhosphorIconsDuotone.wallet,
                color: kGold,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revenus confirmés',
                    style: TextStyle(color: kTextSub, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${controller.formatRevenue(controller.totalRevenue.value)} F CFA',
                    style: const TextStyle(
                      color: kTextPrim,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            PhosphorIcon(PhosphorIconsDuotone.trendUp,
              color: kGold,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OwnerSectionHeader(
          title: 'Accès rapides',
          subtitle: 'Retrouvez les trois zones de gestion les plus utilisées',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickAction(
              icon: PhosphorIconsDuotone.soccerBall,
              label: 'Terrains',
              color: kGreen,
              onTap: () => Get.toNamed(Routes.terrainList),
            ),
            const SizedBox(width: 10),
            _QuickAction(
              icon: PhosphorIconsDuotone.calendarBlank,
              label: 'Réservations',
              color: kBlue,
              onTap: () => Get.toNamed(Routes.reservations),
            ),
            const SizedBox(width: 10),
            _QuickAction(
              icon: PhosphorIconsDuotone.clockCountdown,
              label: 'Créneaux',
              color: kGold,
              onTap: () => Get.toNamed(Routes.availability),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountCard() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OwnerSectionHeader(
              title: 'Informations du compte',
              subtitle:
                  'Identité, sécurité et coordonnées de reversement',
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: PhosphorIconsDuotone.identificationBadge,
              label: 'Nom complet',
              value: controller.ownerName.value,
            ),
            const Divider(height: 22, color: kDivider),
            _InfoRow(
              icon: PhosphorIconsDuotone.phone,
              label: 'Téléphone',
              value: controller.phone.value,
            ),
            const Divider(height: 22, color: kDivider),
            _InfoRow(
              icon: PhosphorIconsDuotone.calendarDots,
              label: 'Membre depuis',
              value: controller.memberSince.value,
            ),
            const Divider(height: 22, color: kDivider),
            _AccountAction(
              icon: PhosphorIcons.wallet,
              title: 'Reversements',
              subtitle: 'Wave, Orange Money, Yas Money',
              onTap: _openPaymentMethods,
            ),
            const Divider(height: 22, color: kDivider),
            _AccountAction(
              icon: PhosphorIcons.shieldCheck,
              title: 'Sécurité',
              subtitle: 'Changer le mot de passe',
              onTap: _openSecurity,
            ),
          ],
        ),
      ),
    );
  }

  void _openEditProfile() {
    controller.resetForm();
    Get.toNamed(Routes.editProfile);
  }

  void _openSecurity() {
    controller.resetPasswordForm();
    Get.toNamed(Routes.security);
  }

  void _openPaymentMethods() {
    controller.resetPayoutForm();
    Get.toNamed(Routes.paymentMethods);
  }

  void _showAvatarPicker() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
        decoration: const BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
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
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Photo de profil',
                  style: TextStyle(
                    color: kTextPrim,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _AvatarSourceTile(
                icon: PhosphorIconsDuotone.camera,
                title: 'Prendre une photo',
                onTap: () {
                  Get.back();
                  controller.pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
              _AvatarSourceTile(
                icon: PhosphorIconsDuotone.images,
                title: 'Choisir depuis la galerie',
                onTap: () {
                  Get.back();
                  controller.pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: _showLogoutDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kRed.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(PhosphorIconsDuotone.signOut,
              color: kRed,
              size: 18,
            ),
            SizedBox(width: 10),
            Text(
              'Déconnexion',
              style: TextStyle(
                color: kRed,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(22),
            boxShadow: kElevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: kRedLight,
                  shape: BoxShape.circle,
                ),
                child: PhosphorIcon(PhosphorIconsDuotone.signOut,
                  color: kRed,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Déconnexion',
                style: TextStyle(
                  color: kTextPrim,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Voulez-vous quitter votre session ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kTextSub,
                  fontSize: 14,
                  height: 1.4,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: Get.back,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          color: kTextSub,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Confirmer',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}

class _QuickAction extends StatelessWidget {
  final dynamic icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: kCardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(icon, color: color, size: 22),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kTextPrim,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final dynamic icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 78,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kCardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(11),
              ),
              child: PhosphorIcon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kTextPrim,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kTextSub,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String initials;
  final String? imageUrl;
  final bool isUploading;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.initials,
    required this.imageUrl,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(36),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: kGreenGradient,
            ),
            clipBehavior: Clip.antiAlias,
            child: AppNetworkImage(
              url: hasImage ? imageUrl : null,
              fit: BoxFit.cover,
              fallback: _AvatarInitials(initials: initials),
            ),
          ),
          if (isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: kGreen,
                shape: BoxShape.circle,
                border: Border.all(color: kBgCard, width: 2),
              ),
              child: Icon(
                PhosphorIconsBold.camera,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  final String initials;

  const _AvatarInitials({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AvatarSourceTile extends StatelessWidget {
  final dynamic icon;
  final String title;
  final VoidCallback onTap;

  const _AvatarSourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: kGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: PhosphorIcon(icon, color: kGreen, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: kTextPrim,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            PhosphorIcon(PhosphorIcons.caretRight,
              color: kTextLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final dynamic icon;
  final String label;
  final String value;
  final String? helper;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: kBgSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: PhosphorIcon(icon, color: kTextSub, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: kTextSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kTextPrim,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (helper != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kBgSurface,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              helper!,
              style: const TextStyle(
                color: kTextLight,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _AccountAction extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AccountAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: kGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: PhosphorIcon(icon, color: kGreen, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: kTextSub,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: kTextPrim,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            PhosphorIcon(PhosphorIcons.caretRight,
              color: kTextLight,
            ),
          ],
        ),
      ),
    );
  }
}
