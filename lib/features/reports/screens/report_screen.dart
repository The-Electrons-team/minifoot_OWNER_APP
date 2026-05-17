import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/reservation_service.dart';
import '../../../core/services/revenue_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';

enum _ReportType { revenues, reservations }

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _revenueService = RevenueService();
  final _reservationService = ReservationService();

  bool _isGenerating = false;
  Uint8List? _pdfBytes;
  String? _errorMessage;
  late _ReportType _reportType;
  late String _periodKey;

  Map<String, dynamic> get _args =>
      Get.arguments is Map<String, dynamic> ? Get.arguments : {};

  @override
  void initState() {
    super.initState();
    _reportType = _args['reportType'] == 'reservations'
        ? _ReportType.reservations
        : _ReportType.revenues;
    _periodKey = _args['periodKey']?.toString() ?? 'weekly';
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    setState(() {
      _isGenerating = true;
      _pdfBytes = null;
      _errorMessage = null;
    });

    try {
      final bytes = _reportType == _ReportType.revenues
          ? await _buildRevenuePdf(await _revenueService.getOwnerRevenueData())
          : await _buildReservationsPdf(await _loadReservations());

      if (!mounted) return;
      setState(() {
        _pdfBytes = bytes;
        _isGenerating = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Erreur génération PDF: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Impossible de générer le rapport: $error';
      });
    }
  }

  Future<List<_PdfReservation>> _loadReservations() async {
    final rows = await _reservationService.getOwnerReservations();
    final reservations = rows
        .whereType<Map<String, dynamic>>()
        .map(_PdfReservation.fromJson)
        .toList();
    reservations.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return reservations;
  }

  Future<Uint8List> _buildRevenuePdf(OwnerRevenueData data) async {
    final pdf = pw.Document();
    final theme = await _pdfTheme();
    final entries = _entriesForPeriod(data);
    final totalRevenue = entries.fold<int>(0, (sum, e) => sum + e.amount);
    final totalBookings = entries.fold<int>(0, (sum, e) => sum + e.bookings);
    final occupancy = entries.isEmpty
        ? 0.0
        : entries.fold<double>(0, (sum, e) => sum + e.occupancy) /
              entries.length;
    final bestEntry = [...entries]
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final topTerrain = data.terrainStats.isNotEmpty
        ? data.terrainStats.first
        : null;
    final paidTransactions = data.transactions
        .where((tx) => tx.status == 'paid')
        .take(8)
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: theme,
        footer: _buildFooter,
        build: (context) => [
          _buildHeader('Rapport de revenus', _periodLabel),
          pw.SizedBox(height: 22),
          pw.Row(
            children: [
              _pdfKpiCard(
                'Revenus',
                '${_formatAmountFull(totalRevenue)} F CFA',
                _green,
              ),
              pw.SizedBox(width: 10),
              _pdfKpiCard('Réservations', '$totalBookings', _blue),
              pw.SizedBox(width: 10),
              _pdfKpiCard('Occupation', _formatPercent(occupancy), _gold),
            ],
          ),
          pw.SizedBox(height: 22),
          _sectionTitle('Détail par période'),
          _revenueTable(entries),
          if (data.terrainStats.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _sectionTitle('Top terrains'),
            _terrainTable(data.terrainStats),
          ],
          if (paidTransactions.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _sectionTitle('Derniers paiements confirmés'),
            _transactionTable(paidTransactions),
          ],
          pw.SizedBox(height: 20),
          _observationBox([
            if (bestEntry.isNotEmpty && bestEntry.first.amount > 0)
              'Meilleure période : ${bestEntry.first.label} avec ${_formatAmountFull(bestEntry.first.amount)} F CFA.',
            if (topTerrain != null)
              'Terrain le plus performant : ${topTerrain.name} (${_formatAmountFull(topTerrain.amount)} F CFA).',
            data.pendingAmount > 0
                ? 'Paiements encore en attente : ${_formatAmountFull(data.pendingAmount)} F CFA.'
                : 'Aucun paiement en attente dans les transactions chargées.',
          ]),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _buildReservationsPdf(
    List<_PdfReservation> reservations,
  ) async {
    final pdf = pw.Document();
    final theme = await _pdfTheme();
    final confirmed = reservations
        .where((item) => item.status == 'Confirmée')
        .toList();
    final pending = reservations
        .where((item) => item.status == 'En attente')
        .length;
    final cancelled = reservations
        .where((item) => item.status == 'Annulée')
        .length;
    final confirmedAmount = confirmed.fold<int>(
      0,
      (sum, item) => sum + item.amount,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        theme: theme,
        footer: _buildFooter,
        build: (context) => [
          _buildHeader('Rapport des réservations', 'Toutes les réservations'),
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              _pdfKpiCard('Total', '${reservations.length}', _green),
              pw.SizedBox(width: 10),
              _pdfKpiCard('Confirmées', '${confirmed.length}', _blue),
              pw.SizedBox(width: 10),
              _pdfKpiCard('En attente', '$pending', _gold),
              pw.SizedBox(width: 10),
              _pdfKpiCard('Annulées', '$cancelled', _red),
              pw.SizedBox(width: 10),
              _pdfKpiCard(
                'Montant confirmé',
                '${_formatAmountFull(confirmedAmount)} F CFA',
                _green,
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          _sectionTitle('Détail des réservations'),
          if (reservations.isEmpty)
            _emptyBox('Aucune réservation trouvée pour vos terrains.')
          else
            _reservationTable(reservations.take(25).toList()),
          if (reservations.length > 25) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Affichage limité aux 25 réservations les plus récentes.',
              style: const pw.TextStyle(color: _textSub, fontSize: 9),
            ),
          ],
          pw.SizedBox(height: 18),
          _observationBox([
            'Les réservations confirmées correspondent aux créneaux validés par paiement.',
            'Les réservations en attente doivent être finalisées par paiement pour confirmer le créneau.',
            'Le propriétaire conserve la possibilité de refuser uniquement les réservations en attente.',
          ]),
        ],
      ),
    );

    return pdf.save();
  }

  Future<pw.ThemeData> _pdfTheme() async => pw.ThemeData.withFont(
    base: pw.Font.helvetica(),
    bold: pw.Font.helveticaBold(),
    italic: pw.Font.helveticaOblique(),
  );

  pw.Widget _buildHeader(String title, String subtitle) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: const pw.BoxDecoration(
        color: _green,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(14)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MiniFoot Owner',
                style: pw.TextStyle(
                  fontSize: 21,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                '$title - $subtitle',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                _ownerName,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _ownerPhone,
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _formatDate(DateTime.now()),
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfKpiCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          border: pw.Border.all(color: _border, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: _textSub),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              maxLines: 2,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 15,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _revenueTable(List<OwnerRevenueEntry> entries) {
    if (entries.isEmpty) {
      return _emptyBox('Aucune donnée de revenus pour cette période.');
    }

    return pw.TableHelper.fromTextArray(
      headers: ['Période', 'Revenus (F CFA)', 'Réservations', 'Occupation'],
      data: entries
          .map(
            (entry) => [
              entry.label,
              _formatAmountFull(entry.amount),
              '${entry.bookings}',
              _formatPercent(entry.occupancy),
            ],
          )
          .toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: _green),
      cellStyle: const pw.TextStyle(fontSize: 10),
      rowDecoration: const pw.BoxDecoration(color: _bgSoft),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      border: pw.TableBorder.all(color: _border, width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
    );
  }

  pw.Widget _terrainTable(List<TerrainRevenueStat> stats) {
    return pw.TableHelper.fromTextArray(
      headers: ['Terrain', 'Revenus (F CFA)', 'Performance'],
      data: stats
          .map(
            (stat) => [
              stat.name,
              _formatAmountFull(stat.amount),
              _formatPercent(stat.rate),
            ],
          )
          .toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: _blue),
      cellStyle: const pw.TextStyle(fontSize: 10),
      border: pw.TableBorder.all(color: _border, width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    );
  }

  pw.Widget _transactionTable(List<OwnerTransaction> transactions) {
    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Client', 'Terrain', 'Méthode', 'Montant'],
      data: transactions
          .map(
            (tx) => [
              tx.dateLabel,
              tx.client,
              tx.terrain,
              tx.method,
              _formatAmountFull(tx.amount),
            ],
          )
          .toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: _green),
      cellStyle: const pw.TextStyle(fontSize: 9),
      border: pw.TableBorder.all(color: _border, width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    );
  }

  pw.Widget _reservationTable(List<_PdfReservation> reservations) {
    return pw.TableHelper.fromTextArray(
      headers: [
        'Date',
        'Créneau',
        'Terrain',
        'Client',
        'Statut',
        'Paiement',
        'Montant',
      ],
      data: reservations
          .map(
            (item) => [
              item.dateLabel,
              item.timeSlot,
              item.terrain,
              item.client,
              item.status,
              item.paymentStatus,
              _formatAmountFull(item.amount),
            ],
          )
          .toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 8.5,
      ),
      headerDecoration: const pw.BoxDecoration(color: _green),
      cellStyle: const pw.TextStyle(fontSize: 8.5),
      border: pw.TableBorder.all(color: _border, width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
        6: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _observationBox(List<String> lines) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFE8F5E9),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFB2DFDB),
          width: 0.5,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Observations',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
              color: _green,
            ),
          ),
          pw.SizedBox(height: 7),
          ...lines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                '- $line',
                style: const pw.TextStyle(fontSize: 10, color: _textSub),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _emptyBox(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _bgSoft,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10, color: _textSub),
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Généré par MiniFoot Owner App',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
          pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;
    HapticFeedback.mediumImpact();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$_fileName.pdf');
    await file.writeAsBytes(_pdfBytes!);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: _shareText),
    );
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    HapticFeedback.mediumImpact();
    await Printing.layoutPdf(onLayout: (_) async => _pdfBytes!);
  }

  void _changeReportType(_ReportType type) {
    if (_reportType == type) return;
    HapticFeedback.selectionClick();
    setState(() => _reportType = type);
    _generatePdf();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
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
        title: const Text(
          'Rapport PDF',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kTextPrim,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_pdfBytes != null) ...[
            IconButton(
              onPressed: _sharePdf,
              icon: Icon(
                PhosphorIcons.shareNetwork(PhosphorIconsStyle.duotone),
                color: kGreen,
                size: 22,
              ),
              tooltip: 'Partager',
            ),
            IconButton(
              onPressed: _printPdf,
              icon: Icon(
                PhosphorIcons.printer(PhosphorIconsStyle.duotone),
                color: kGreen,
                size: 22,
              ),
              tooltip: 'Imprimer',
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kDivider),
        ),
      ),
      body: _isGenerating
          ? _buildLoadingState()
          : _pdfBytes != null
          ? _buildPdfPreview()
          : _buildErrorState(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: kGreenLight,
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: kGreen, strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Génération du rapport ${_reportLabel.toLowerCase()}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kTextPrim,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Préparation des données réelles',
            style: TextStyle(fontSize: 13, color: kTextSub),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPreview() {
    return Column(
      children: [
        _buildReportSwitch(),
        Expanded(
          child: PdfPreview(
            build: (_) async => _pdfBytes!,
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            pdfPreviewPageDecoration: BoxDecoration(
              color: Colors.white,
              boxShadow: kCardShadow,
            ),
          ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildReportSwitch() {
    return Container(
      color: kBgCard,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _ReportChip(
            label: 'Revenus',
            icon: PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
            selected: _reportType == _ReportType.revenues,
            onTap: () => _changeReportType(_ReportType.revenues),
          ),
          const SizedBox(width: 10),
          _ReportChip(
            label: 'Réservations',
            icon: PhosphorIcons.calendarBlank(PhosphorIconsStyle.duotone),
            selected: _reportType == _ReportType.reservations,
            onTap: () => _changeReportType(_ReportType.reservations),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _printPdf,
                icon: Icon(
                  PhosphorIcons.printer(PhosphorIconsStyle.duotone),
                  color: kGreen,
                  size: 20,
                ),
                label: const Text(
                  'Imprimer',
                  style: TextStyle(color: kGreen, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _sharePdf,
                icon: Icon(
                  PhosphorIcons.shareNetwork(PhosphorIconsStyle.duotone),
                  size: 20,
                ),
                label: const Text(
                  'Partager',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.warningCircle(PhosphorIconsStyle.duotone),
              size: 64,
              color: kRed,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Erreur de génération',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: kTextPrim),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _generatePdf,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  List<OwnerRevenueEntry> _entriesForPeriod(OwnerRevenueData data) {
    switch (_periodKey) {
      case 'daily':
        return data.dailyEntries;
      case 'monthly':
        return data.monthlyEntries;
      case 'weekly':
      default:
        return data.weeklyEntries;
    }
  }

  String get _periodLabel {
    switch (_periodKey) {
      case 'daily':
        return 'Cette semaine';
      case 'monthly':
        return 'Ces 6 mois';
      case 'weekly':
      default:
        return 'Ce mois';
    }
  }

  String get _reportLabel =>
      _reportType == _ReportType.revenues ? 'Revenus' : 'Réservations';

  String get _fileName => _reportType == _ReportType.revenues
      ? 'rapport_minifoot_revenus'
      : 'rapport_minifoot_reservations';

  String get _shareText => _reportType == _ReportType.revenues
      ? 'Rapport de revenus MiniFoot Owner'
      : 'Rapport de réservations MiniFoot Owner';

  String get _ownerName {
    if (!Get.isRegistered<AuthController>()) return 'Propriétaire MiniFoot';
    final user = Get.find<AuthController>().user.value;
    final name = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    return name.isEmpty ? 'Propriétaire MiniFoot' : name;
  }

  String get _ownerPhone {
    if (!Get.isRegistered<AuthController>()) return '';
    return Get.find<AuthController>().user.value?.phone ?? '';
  }

  static String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  static String _formatAmountFull(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  static String _formatPercent(double value) => '${(value * 100).round()}%';
}

class _PdfReservation {
  final DateTime sortDate;
  final String dateLabel;
  final String client;
  final String terrain;
  final String timeSlot;
  final int amount;
  final String status;
  final String paymentStatus;

  const _PdfReservation({
    required this.sortDate,
    required this.dateLabel,
    required this.client,
    required this.terrain,
    required this.timeSlot,
    required this.amount,
    required this.status,
    required this.paymentStatus,
  });

  factory _PdfReservation.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final terrain = json['terrain'] as Map<String, dynamic>?;
    final firstName = (user?['firstName'] ?? '').toString().trim();
    final lastName = (user?['lastName'] ?? '').toString().trim();
    final client = '$firstName $lastName'.trim();
    final date = DateTime.tryParse(json['date']?.toString() ?? '')?.toLocal();

    return _PdfReservation(
      sortDate: date ?? DateTime.fromMillisecondsSinceEpoch(0),
      dateLabel: date == null
          ? (json['date'] ?? '').toString()
          : DateFormat('dd MMM yyyy', 'fr_FR').format(date),
      client: client.isEmpty ? 'Client MiniFoot' : client,
      terrain: (terrain?['name'] ?? 'Terrain').toString(),
      timeSlot: _formatSlot(json['startSlot'], json['endSlot']),
      amount: _asInt(json['finalPrice'] ?? json['totalPrice']),
      status: _formatStatus(json['status']),
      paymentStatus: _formatPaymentStatus(json['payments']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatSlot(dynamic start, dynamic end) {
    final startText = start?.toString() ?? '';
    final endText = end?.toString() ?? '';
    if (startText.isEmpty && endText.isEmpty) return '';
    return '$startText - $endText';
  }

  static String _formatStatus(dynamic value) {
    switch (value?.toString()) {
      case 'CONFIRMED':
      case 'COMPLETED':
        return 'Confirmée';
      case 'CANCELLED':
        return 'Annulée';
      case 'PENDING_PAYMENT':
      default:
        return 'En attente';
    }
  }

  static String _formatPaymentStatus(dynamic value) {
    if (value is! List || value.isEmpty) return 'Aucun paiement';
    final lastPayment = value.last;
    final status = lastPayment is Map<String, dynamic>
        ? lastPayment['status']?.toString()
        : null;
    switch (status) {
      case 'COMPLETED':
        return 'Payé';
      case 'FAILED':
        return 'Échoué';
      case 'REFUNDED':
        return 'Remboursé';
      case 'PENDING':
      default:
        return 'En attente';
    }
  }
}

class _ReportChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ReportChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          decoration: BoxDecoration(
            color: selected ? kGreen : kBgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? kGreen : kBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.white : kTextSub, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : kTextSub,
                  fontSize: 13,
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

const _green = PdfColor.fromInt(0xFF006F39);
const _gold = PdfColor.fromInt(0xFFF59E0B);
const _blue = PdfColor.fromInt(0xFF1565C0);
const _red = PdfColor.fromInt(0xFFEF4444);
const _textSub = PdfColor.fromInt(0xFF6B7280);
const _border = PdfColor.fromInt(0xFFE5E0D8);
const _bgSoft = PdfColor.fromInt(0xFFF8F8F8);
