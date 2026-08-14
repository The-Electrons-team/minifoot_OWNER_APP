import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/owner_ui.dart';
import '../controllers/profile_controller.dart';

class PaymentMethodsScreen extends GetView<ProfileController> {
  const PaymentMethodsScreen({super.key});

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
          'Reversements',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: kTextPrim,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(
        () => ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
          children: [
            _PayoutMethodCard(
              title: 'Wave',
              subtitle: 'Numéro Wave',
              color: kBrandWave,
              bgColor: kBlueLight,
              method: 'WAVE',
              textController: controller.wavePhoneCtrl,
              selected: controller.preferredPayoutMethod.value == 'WAVE',
              onSelect: controller.selectPreferredPayoutMethod,
            ),
            const SizedBox(height: 12),
            _PayoutMethodCard(
              title: 'Orange Money',
              subtitle: 'Numéro Orange Money',
              color: kOrange,
              bgColor: kOrangeMoneySurfaceAlt,
              method: 'ORANGE_MONEY',
              textController: controller.orangePhoneCtrl,
              selected:
                  controller.preferredPayoutMethod.value == 'ORANGE_MONEY',
              onSelect: controller.selectPreferredPayoutMethod,
            ),
            const SizedBox(height: 12),
            _PayoutMethodCard(
              title: 'Yas Money',
              subtitle: 'Numéro Free / Yas',
              color: kGold,
              bgColor: kGoldLight,
              method: 'FREE_MONEY',
              textController: controller.freePhoneCtrl,
              selected: controller.preferredPayoutMethod.value == 'FREE_MONEY',
              onSelect: controller.selectPreferredPayoutMethod,
            ),
            const SizedBox(height: 18),
            _buildNotice(),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: controller.isSavingPayout.value
                    ? null
                    : controller.savePayoutInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: kGreen.withValues(alpha: 0.5),
                  elevation: 0,
                ),
                child: controller.isSavingPayout.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Enregistrer',
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
    );
  }

  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBlueLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          PhosphorIcon(PhosphorIconsDuotone.info,
            color: kBlue,
            size: 18,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Renseignez au moins un numéro et choisissez votre méthode préférée.',
              style: TextStyle(
                color: kBlue,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutMethodCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final String method;
  final TextEditingController textController;
  final bool selected;
  final ValueChanged<String> onSelect;

  const _PayoutMethodCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.method,
    required this.textController,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_PayoutMethodCard> createState() => _PayoutMethodCardState();
}

class _PayoutMethodCardState extends State<_PayoutMethodCard> {
  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasText = widget.textController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kCardShadow,
        border: widget.selected
            ? Border.all(color: widget.color.withValues(alpha: 0.45), width: 1.4)
            : Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                child: PaymentBrandBadge(method: widget.method, size: 46),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: kTextPrim,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: kTextSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => widget.onSelect(widget.method),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: widget.selected ? widget.bgColor : kBgSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        widget.selected
                            ? PhosphorIconsFill.checkCircle
                            : PhosphorIconsDuotone.circle,
                        size: 15,
                        color: widget.selected ? widget.color : kTextLight,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.selected ? 'Préféré' : 'Choisir',
                        style: TextStyle(
                          color: widget.selected ? widget.color : kTextSub,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: widget.textController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            decoration: InputDecoration(
              hintText: '77 XXX XX XX',
              prefixText: '+221 ',
              prefixStyle: const TextStyle(
                color: kTextPrim,
                fontWeight: FontWeight.w800,
              ),
              suffixIcon: hasText
                  ? GestureDetector(
                      onTap: widget.textController.clear,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: PhosphorIcon(PhosphorIcons.x,
                          color: kTextLight,
                          size: 18,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
