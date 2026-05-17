import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
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
            Icons.arrow_back_ios_new_rounded,
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

          if (controller.controllers.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 120),
              children: const [
                Icon(Icons.badge_outlined, color: kGreen, size: 54),
                SizedBox(height: 16),
                Text(
                  'Aucun contrôleur',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kTextPrim,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ajoute une personne de confiance pour scanner les QR et gérer les créneaux des complexes autorisés.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextSub, fontSize: 13, height: 1.4),
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            itemCount: controller.controllers.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              return _ControllerCard(
                item: controller.controllers[index],
                onTap: () => Get.toNamed(
                  Routes.controllerDetail,
                  arguments: controller.controllers[index],
                ),
                onToggle: () =>
                    controller.toggleActive(controller.controllers[index]),
              );
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kGreen,
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Ajouter',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+221');
    final selectedComplexes = <String>{}.obs;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Nouveau contrôleur',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kTextPrim,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: firstNameCtrl,
                decoration: const InputDecoration(labelText: 'Prénom'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),

              const SizedBox(height: 16),
              const Text(
                'Complexes autorisés',
                style: TextStyle(
                  color: kTextPrim,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.terrains.map((terrain) {
                    final selected = selectedComplexes.contains(terrain.id);
                    return FilterChip(
                      selected: selected,
                      label: Text(terrain.name),
                      selectedColor: kGreenLight,
                      checkmarkColor: kGreen,
                      onSelected: (_) {
                        selected
                            ? selectedComplexes.remove(terrain.id)
                            : selectedComplexes.add(terrain.id);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final credentials = await controller.createController(
                      firstName: firstNameCtrl.text.trim(),
                      lastName: lastNameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      complexIds: selectedComplexes.toList(),
                    );
                    if (credentials == null) return;
                    Get.back();
                    _showCredentials(credentials);
                  },
                  child: const Text('Créer le compte'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showCredentials(Map<String, dynamic> credentials) {
    final message = (credentials['message'] ?? '').toString();
    Get.defaultDialog(
      title: 'Identifiants créés',
      middleText: message,
      textCancel: 'Copier',
      textConfirm: 'Partager',
      onCancel: () {
        Clipboard.setData(ClipboardData(text: message));
        Get.back();
        Get.snackbar('Copié', 'Identifiants copiés');
      },
      onConfirm: () {
        Get.back();
        SharePlus.instance.share(ShareParams(text: message));
      },
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

  String _formatAmount(int amount) {
    final text = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return '${buffer.toString()} F';
  }

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
                    child: Icon(
                      Icons.badge_outlined,
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
