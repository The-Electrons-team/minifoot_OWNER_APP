import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/chat_controller.dart';
import 'conversation_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Screen liste des conversations
// ══════════════════════════════════════════════════════════════════════════════

class ChatListScreen extends GetView<ChatController> {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Obx(() {
              final convs = controller.filteredConversations;
              if (convs.isEmpty) return _buildEmptyState();
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: convs.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 80,
                  endIndent: 16,
                  color: kDivider,
                ),
                itemBuilder: (_, i) => _ConversationTile(conversation: convs[i])
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (i * 50).ms)
                    .slideX(begin: 0.05),
              );
            }),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kBgCard,
      elevation: 0,
      leading: IconButton(
        onPressed: Get.back,
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: kTextPrim,
          size: 18,
        ),
      ),
      title: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Messages',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: kTextPrim,
              ),
            ),
            if (controller.totalUnread > 0)
              Text(
                '${controller.totalUnread} non lu(s)',
                style: const TextStyle(
                  fontSize: 11,
                  color: kGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: kDivider),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: kBgCard,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        onChanged: controller.setSearch,
        style: const TextStyle(fontSize: 14, color: kTextPrim),
        decoration: InputDecoration(
          hintText: 'Rechercher un joueur…',
          hintStyle: const TextStyle(color: kTextLight, fontSize: 14),
          prefixIcon: Icon(
            PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.duotone),
            color: kTextLight,
            size: 20,
          ),
          filled: true,
          fillColor: kBgSurface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: kBgSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.chatCircleDots(PhosphorIconsStyle.duotone),
              size: 40,
              color: kTextLight,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun message',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTextSub,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Widget tuile de conversation
// ══════════════════════════════════════════════════════════════════════════════

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;

  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Get.to(
          () => ConversationScreen(conversation: conversation),
          transition: Transition.cupertino,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: conversation.avatarColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      conversation.avatarInitials,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: conversation.avatarColor,
                      ),
                    ),
                  ),
                ),
                // Indicateur en ligne (mock)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: kGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: kBgCard, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.playerName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: kTextPrim,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastMessageTime),
                        style: TextStyle(
                          fontSize: 11,
                          color: hasUnread ? kGreen : kTextLight,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.teamName,
                    style: const TextStyle(fontSize: 11, color: kTextSub),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread ? kTextPrim : kTextSub,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return 'Hier';
  }
}
