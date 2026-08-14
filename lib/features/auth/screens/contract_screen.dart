import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';

const String kContractAcceptedKey = 'contractAccepted_v1';

class ContractScreen extends StatefulWidget {
  const ContractScreen({super.key});

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  bool _accepted = false;
  bool _loading = false;

  Future<void> _accept() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kContractAcceptedKey, true);
    Get.offAllNamed(Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: appSurfaceDecoration(
                      color: kGreenLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const PhosphorIcon(
                      PhosphorIconsDuotone.fileText,
                      color: kGreen,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Contrat propriétaire',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: kTextPrim,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Lisez et acceptez les conditions avant de continuer.',
                    style: TextStyle(
                      fontSize: 13,
                      color: kTextSub,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: appSurfaceDecoration(
                  color: kBgCard,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: kCardShadow,
                ),
                child: const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ContractSection(
                        title: '1. Objet du contrat',
                        body:
                            'Le présent contrat régit l\'utilisation de la plateforme Minifoot Pro par le propriétaire de terrain (ci-après "le Gérant"). En acceptant ce contrat, le Gérant s\'engage à respecter les conditions d\'utilisation de la plateforme.',
                      ),
                      _ContractSection(
                        title: '2. Commissions et reversements',
                        body:
                            'Minifoot Pro prélève une commission de 5 % sur chaque paiement encaissé via la plateforme. Le Gérant reçoit 95 % de chaque paiement. Les reversements sont effectués sur le compte mobile money configuré dans l\'application, dans un délai de 24 à 48 heures ouvrées après demande.',
                      ),
                      _ContractSection(
                        title: '3. Responsabilités du Gérant',
                        body:
                            'Le Gérant s\'engage à maintenir ses informations à jour, à respecter les réservations confirmées, à assurer la disponibilité du terrain aux créneaux indiqués et à ne pas annuler de réservations de manière abusive.',
                      ),
                      _ContractSection(
                        title: '4. Utilisation de la plateforme',
                        body:
                            'Le Gérant s\'interdit toute utilisation frauduleuse de la plateforme, notamment la création de fausses réservations, la manipulation des paiements ou tout comportement de nature à nuire aux utilisateurs ou à la plateforme.',
                      ),
                      _ContractSection(
                        title: '5. Résiliation',
                        body:
                            'Minifoot Pro se réserve le droit de suspendre ou résilier l\'accès du Gérant en cas de manquement aux présentes conditions. Le Gérant peut résilier son compte à tout moment en contactant le support.',
                      ),
                      _ContractSection(
                        title: '6. Données personnelles',
                        body:
                            'Les données collectées sont utilisées exclusivement pour le fonctionnement de la plateforme. Elles ne sont pas partagées avec des tiers sans consentement, sauf obligation légale.',
                      ),
                      SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _accepted = !_accepted),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: appSurfaceDecoration(
                            color: _accepted ? kGreen : kBgSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _accepted ? kGreen : kBorder,
                            ),
                          ),
                          child: _accepted
                              ? const PhosphorIcon(
                                  PhosphorIconsBold.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "J'ai lu et j'accepte les conditions du contrat",
                            style: TextStyle(
                              fontSize: 13,
                              color: kTextPrim,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: (_accepted && !_loading) ? _accept : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        disabledBackgroundColor: kGreen.withValues(alpha: 0.4),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Continuer',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
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
}

class _ContractSection extends StatelessWidget {
  final String title;
  final String body;

  const _ContractSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: kTextPrim,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(fontSize: 13, color: kTextSub, height: 1.6),
          ),
        ],
      ),
    );
  }
}
