import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/app_phone.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../routes/app_routes.dart';
import '../controllers/controllers_controller.dart';

class ControllersScreen extends GetView<ControllersController> {
  const ControllersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            PhosphorIconsRegular.caretLeft,
            size: 18,
          ),
        ),
        title: const Text(
          'Contrôleurs',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: kGreen,
        onRefresh: controller.refreshAll,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: kGreen),
            );
          }

          // L'erreur passe avant le vide : sinon une coupure réseau
          // s'affiche comme « Aucun contrôleur ».
          if (controller.errorMessage.value.isNotEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.6,
                  child: AppErrorState(
                    message: controller.errorMessage.value,
                    onRetry: controller.refreshAll,
                  ),
                ),
              ],
            );
          }

          if (controller.controllers.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 120),
              children: [
                const _EmptyControllerIcon(),
                const SizedBox(height: 16),
                // L'état vide invitait à ajouter un contrôleur… sans bouton
                // pour le faire.
                AppEmptyState(
                  title: 'Aucun contrôleur',
                  message:
                      'Ajoutez une personne de confiance pour scanner les QR '
                      'et gérer les créneaux des complexes autorisés.',
                  actionLabel: 'Ajouter un contrôleur',
                  onAction: () => _showCreateSheet(context),
                  illustration: const SizedBox.shrink(),
                ),
              ],
            );
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (scroll) {
              if (scroll.metrics.pixels >=
                  scroll.metrics.maxScrollExtent - 400) {
                controller.loadMore();
              }
              return false;
            },
            child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            itemCount:
                controller.controllers.length + (controller.hasMore ? 1 : 0),
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              if (index >= controller.controllers.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kGreen,
                      ),
                    ),
                  ),
                );
              }
              final item = controller.controllers[index];
              return _ControllerCard(
                item: item,
                onTap: () =>
                    Get.toNamed(Routes.controllerDetail, arguments: item),
                onToggle: () => controller.toggleActive(item),
              );
            },
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kGreen,
        onPressed: () => _showCreateSheet(context),
        icon: Icon(
          PhosphorIconsBold.plus,
          color: Colors.white,
        ),
        label: const Text(
          'Ajouter',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context) {
    // Le contenu est un widget à part entière : c'est lui qui crée ses
    // contrôleurs de texte et les libère dans son `dispose()`. Les libérer
    // après `await Get.bottomSheet(...)` était trop tôt — l'animation de
    // fermeture les utilise encore, d'où « A TextEditingController was used
    // after being disposed ».
    return AppBottomSheet.show<void>(
      title: 'Nouveau contrôleur',
      child: _CreateControllerSheet(
        controller: controller,
        onCreated: _showCredentials,
      ),
    );
  }


  void _showCredentials(Map<String, dynamic> credentials) {
    final message = (credentials['message'] ?? '').toString();

    // L'ancien dialogue détournait le bouton d'annulation en « Copier » : la
    // seule sortie apparente déclenchait une action, et rien ne permettait de
    // simplement fermer. Ici, trois boutons qui font ce qu'ils annoncent.
    AppBottomSheet.show<void>(
      title: 'Identifiants créés',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: kBgSurface,
              borderRadius: AppRadius.smAll,
            ),
            child: SelectableText(
              message,
              style: const TextStyle(
                fontSize: AppFontSize.bodySmall,
                color: kTextPrim,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Partager',
            icon: PhosphorIconsRegular.shareNetwork,
            onPressed: () {
              Get.back();
              SharePlus.instance.share(ShareParams(text: message));
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: 'Copier',
            icon: PhosphorIconsRegular.copy,
            variant: AppButtonVariant.secondary,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              Get.back();
              AppSnackbar.success('Identifiants copiés dans le presse-papiers.');
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _ControllerCard extends StatelessWidget {
  final OwnerControllerModel item;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _ControllerCard({
    required this.item,
    required this.onTap,
    required this.onToggle,
  });


  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(18),
            boxShadow: kCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: item.isActive ? kGreenLight : kBgSurface,
                    child: PhosphorIcon(PhosphorIconsDuotone.identificationBadge,
                      color: item.isActive ? kGreen : kTextSub,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.fullName.isEmpty ? 'Contrôleur' : item.fullName,
                          style: const TextStyle(
                            color: kTextPrim,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.phone,
                          style: const TextStyle(color: kTextSub, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: item.isActive,
                    activeThumbColor: kGreen,
                    onChanged: (_) => onToggle(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatPill(label: 'Scans', value: '${item.scans}'),
                  _StatPill(label: 'Présences', value: '${item.confirmed}'),
                  _StatPill(
                    label: 'Créneaux bloqués',
                    value: '${item.blockedSlots}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.complexes.isEmpty
                    ? 'Aucun complexe assigné'
                    : item.complexes.join(' • '),
                style: const TextStyle(
                  color: kTextLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyControllerIcon extends StatelessWidget {
  const _EmptyControllerIcon();

  @override
  Widget build(BuildContext context) {
    return PhosphorIcon(PhosphorIconsDuotone.identificationBadge,
      color: kGreen,
      size: 54,
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: kBgSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: kTextSub,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Formulaire de création d'un contrôleur.
///
/// `StatefulWidget` et non une simple fonction : les `TextEditingController`
/// doivent vivre aussi longtemps que le widget, animation de fermeture comprise.
class _CreateControllerSheet extends StatefulWidget {
  const _CreateControllerSheet({
    required this.controller,
    required this.onCreated,
  });

  final ControllersController controller;
  final void Function(Map<String, dynamic> credentials) onCreated;

  @override
  State<_CreateControllerSheet> createState() => _CreateControllerSheetState();
}

class _CreateControllerSheetState extends State<_CreateControllerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _selectedComplexes = <String>{}.obs;
  final _submitting = false.obs;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedComplexes.isEmpty) {
      AppSnackbar.warning('Sélectionnez au moins un complexe autorisé.');
      return;
    }

    _submitting.value = true;
    try {
      final credentials = await widget.controller.createController(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        // Normalisé ici : le champ acceptait n'importe quoi.
        phone: AppPhone.normalize(_phoneCtrl.text)!,
        complexIds: _selectedComplexes.toList(),
      );
      if (credentials == null) return;

      // On ferme cette feuille **et on laisse l'animation se terminer** avant
      // d'ouvrir celle des identifiants. Enchaîner les deux immédiatement
      // laisse deux feuilles dans l'arbre au même instant, d'où les
      // « Duplicate GlobalKeys » et les « deactivated widget's ancestor ».
      Get.back();
      await Future<void>.delayed(AppBottomSheet.closeAnimation);
      widget.onCreated(credentials);
    } finally {
      if (mounted) _submitting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _firstNameCtrl,
                label: 'Prénom',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.givenName],
                validator: (v) => AppValidators.required(v, label: 'Le prénom'),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppTextField(
                controller: _lastNameCtrl,
                label: 'Nom',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.familyName],
                validator: (v) => AppValidators.required(v, label: 'Le nom'),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppTextField(
                controller: _phoneCtrl,
                label: 'Téléphone',
                hint: '77 XXX XX XX',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: AppValidators.phone,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Complexes autorisés',
          style: TextStyle(
            color: kTextPrim,
            fontWeight: FontWeight.w700,
            fontSize: AppFontSize.bodySmall,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Obx(
          () => Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: widget.controller.terrains.map((terrain) {
              final selected = _selectedComplexes.contains(terrain.id);
              return FilterChip(
                selected: selected,
                label: Text(terrain.name),
                selectedColor: kGreenLight,
                checkmarkColor: kGreen,
                onSelected: (_) => selected
                    ? _selectedComplexes.remove(terrain.id)
                    : _selectedComplexes.add(terrain.id),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Obx(
          () => AppButton(
            label: 'Créer le compte',
            loading: _submitting.value,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
