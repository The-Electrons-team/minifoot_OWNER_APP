import 'package:flutter/material.dart';

/// `IndexedStack` qui ne construit un onglet qu'à sa première visite.
///
/// Un `IndexedStack` ordinaire construit **tous** ses enfants d'emblée : la
/// coquille de navigation déclencherait alors les appels réseau des cinq écrans
/// au démarrage. Sur une connexion 3G, c'est quatre chargements payés pour rien.
///
/// Une fois visité, un onglet reste monté : c'est tout l'intérêt de la
/// coquille — retrouver sa position de défilement et ses filtres en revenant.
class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.itemBuilder,
    required this.itemCount,
  });

  final int index;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final List<bool> _visited = List<bool>.filled(widget.itemCount, false);

  @override
  void initState() {
    super.initState();
    _visited[widget.index] = true;
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited[widget.index] = true;
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      sizing: StackFit.expand,
      children: List.generate(
        widget.itemCount,
        (i) => _visited[i]
            ? widget.itemBuilder(context, i)
            : const SizedBox.shrink(),
      ),
    );
  }
}
