import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_theme.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBgCard,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(PhosphorIconsRegular.caretLeft, color: kTextPrim, size: 18),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: kTextPrim,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kDivider),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: kBgSurface,
                  shape: BoxShape.circle,
                ),
                child: PhosphorIcon(PhosphorIconsDuotone.chatCircleDots,
                  size: 44,
                  color: kTextLight,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Messagerie',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kTextPrim,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Fonctionnalité en cours de développement',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: kTextSub,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'La messagerie avec les joueurs sera disponible prochainement.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: kTextLight, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
