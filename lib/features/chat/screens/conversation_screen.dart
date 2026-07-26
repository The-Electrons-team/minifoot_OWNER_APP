import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_theme.dart';

class ConversationScreen extends StatelessWidget {
  const ConversationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBgCard,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: PhosphorIcon(PhosphorIconsDuotone.arrowLeft,
            color: kTextPrim,
            size: 18,
          ),
        ),
        title: const Text(
          'Conversation',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrim),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kDivider),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Fonctionnalité en cours de développement',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: kTextSub, height: 1.5),
          ),
        ),
      ),
    );
  }
}
