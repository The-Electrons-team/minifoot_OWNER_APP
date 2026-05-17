import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/chat_controller.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Screen conversation individuelle
// ══════════════════════════════════════════════════════════════════════════════

class ConversationScreen extends StatelessWidget {
  final ChatConversation conversation;

  ConversationScreen({super.key, required this.conversation}) {
    // Injecter le controller spécifique à cette conversation
    Get.put(
      ConversationController(conversation: conversation),
      tag: conversation.id,
    );
  }

  ConversationController get ctrl =>
      Get.find<ConversationController>(tag: conversation.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Messages
          Expanded(child: _buildMessageList()),
          // Réponses rapides
          _buildQuickReplies(),
          // Barre de saisie
          _buildInputBar(context),
        ],
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kBgCard,
      elevation: 0,
      leading: IconButton(
        onPressed: Get.back,
        icon: Icon(
          PhosphorIcons.arrowLeft(PhosphorIconsStyle.duotone),
          color: kTextPrim,
          size: 18,
        ),
      ),
      title: Row(
        children: [
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: conversation.avatarColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                conversation.avatarInitials,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: conversation.avatarColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.playerName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kTextPrim,
                  ),
                ),
                Text(
                  conversation.teamName,
                  style: const TextStyle(fontSize: 11, color: kTextSub),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Appel rapide (placeholder)
        IconButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Get.snackbar(
              'Appel',
              'Fonctionnalité bientôt disponible',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: kBgCard,
              colorText: kTextPrim,
              margin: const EdgeInsets.all(16),
              borderRadius: 14,
              duration: const Duration(seconds: 2),
            );
          },
          icon: Icon(
            PhosphorIcons.phone(PhosphorIconsStyle.duotone),
            color: kGreen,
            size: 22,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: kDivider),
      ),
    );
  }

  // ── Liste de messages ────────────────────────────────────────────────────────
  Widget _buildMessageList() {
    return Obx(
      () => ListView.builder(
        controller: ctrl.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        itemCount: ctrl.messages.length,
        itemBuilder: (_, i) {
          final msg = ctrl.messages[i];
          final prev = i > 0 ? ctrl.messages[i - 1] : null;
          final showTime =
              prev == null ||
              msg.timestamp.difference(prev.timestamp).inMinutes > 5;

          return Column(
            children: [
              if (showTime)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    _formatDateTime(msg.timestamp),
                    style: const TextStyle(fontSize: 11, color: kTextLight),
                  ),
                ),
              _MessageBubble(
                message: msg,
                avatarColor: conversation.avatarColor,
                initials: conversation.avatarInitials,
              ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1),
            ],
          );
        },
      ),
    );
  }

  // ── Réponses rapides ─────────────────────────────────────────────────────────
  Widget _buildQuickReplies() {
    return Container(
      height: 44,
      color: kBgCard,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: ctrl.quickReplies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            ctrl.textController.text = ctrl.quickReplies[i];
            ctrl.onTextChanged(ctrl.quickReplies[i]);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kGreenLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kGreen.withValues(alpha: 0.3)),
            ),
            child: Text(
              ctrl.quickReplies[i],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kGreen,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Barre de saisie ──────────────────────────────────────────────────────────
  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: kBgCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Champ texte
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: kBgSurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: ctrl.textController,
                onChanged: ctrl.onTextChanged,
                maxLines: null,
                style: const TextStyle(fontSize: 14, color: kTextPrim),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Écrire un message…',
                  hintStyle: TextStyle(color: kTextLight, fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Bouton envoyer
          Obx(() {
            final hasText = ctrl.textInput.value.isNotEmpty;
            return GestureDetector(
              onTap: hasText
                  ? () {
                      HapticFeedback.mediumImpact();
                      ctrl.sendMessage();
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasText ? kGreen : kBgSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: hasText ? Colors.white : kTextLight,
                  size: 22,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');

    if (diff.inDays == 0) return 'Aujourd\'hui $h:$m';
    if (diff.inDays == 1) return 'Hier $h:$m';
    return '${dt.day}/${dt.month} $h:$m';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Widget bulle de message
// ══════════════════════════════════════════════════════════════════════════════

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Color avatarColor;
  final String initials;

  const _MessageBubble({
    required this.message,
    required this.avatarColor,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = message.isOwner;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isOwner
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar joueur (gauche)
          if (!isOwner) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: avatarColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: avatarColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Bulle
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                color: isOwner ? kGreen : kBgCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isOwner ? 18 : 4),
                  bottomRight: Radius.circular(isOwner ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isOwner ? Colors.white : kTextPrim,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isOwner
                              ? Colors.white.withValues(alpha: 0.6)
                              : kTextLight,
                        ),
                      ),
                      if (isOwner) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Espace côté propriétaire (droit)
          if (isOwner) const SizedBox(width: 4),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
