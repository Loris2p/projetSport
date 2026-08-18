import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../services/share_service.dart';
import '../theme.dart';
import 'category_badge.dart';

class ImportDataDialog extends StatefulWidget {
  final VoidCallback? onImportSuccess;

  const ImportDataDialog({super.key, this.onImportSuccess});

  static Future<void> show(BuildContext context, {VoidCallback? onImportSuccess}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ImportDataDialog(onImportSuccess: onImportSuccess),
    );
  }

  @override
  State<ImportDataDialog> createState() => _ImportDataDialogState();
}

class _ImportDataDialogState extends State<ImportDataDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  
  SharedDataResult? _decodedResult;
  bool _isScanningActive = true;
  String? _parseError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _processScannedCode(String rawCode) {
    if (!_isScanningActive) return;
    final result = ShareService.decode(rawCode);
    if (result.isSuccess) {
      setState(() {
        _isScanningActive = false;
        _decodedResult = result;
        _parseError = null;
      });
    } else {
      setState(() {
        _parseError = result.errorMessage ?? "Code de partage invalide";
      });
    }
  }

  Future<void> _importData(WorkoutProvider provider) async {
    if (_decodedResult == null) return;

    try {
      final res = _decodedResult!;

      if (res.type == ShareDataType.program && res.program != null) {
        // 1. Importer les exercices personnalisés manquants
        for (var customEx in res.exercises) {
          final exists = provider.exercises.any((e) => e.id == customEx.id || e.name.toLowerCase() == customEx.name.toLowerCase());
          if (!exists) {
            await provider.createCustomExercise(
              customEx.name,
              categories: customEx.categories,
              equipment: customEx.equipment,
              notes: customEx.notes,
              videoUrl: customEx.videoUrl,
            );
          }
        }

        // 2. Créer le programme
        await provider.createProgram(
          res.program!.name,
          res.program!.description,
          res.program!.exercises,
          res.program!.exerciseGroups,
        );

        if (mounted) {
          Navigator.pop(context);
          widget.onImportSuccess?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Programme \"${res.program!.name}\" importé avec succès !")),
                ],
              ),
              backgroundColor: AppTheme.greenCheck,
            ),
          );
        }
      } else if ((res.type == ShareDataType.singleExercise || res.type == ShareDataType.exercisesBundle) && res.exercises.isNotEmpty) {
        int importedCount = 0;
        for (var ex in res.exercises) {
          final exists = provider.exercises.any((e) => e.id == ex.id || e.name.toLowerCase() == ex.name.toLowerCase());
          if (!exists) {
            await provider.createCustomExercise(
              ex.name,
              categories: ex.categories,
              equipment: ex.equipment,
              notes: ex.notes,
              videoUrl: ex.videoUrl,
            );
            importedCount++;
          }
        }

        if (mounted) {
          Navigator.pop(context);
          widget.onImportSuccess?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$importedCount exercice(s) importé(s) avec succès !"),
              backgroundColor: AppTheme.greenCheck,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'import : $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.darkBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Poignée de glissement
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Titre
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    const Icon(Icons.download_rounded, color: AppTheme.athleticBlue, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      "Importer des données",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Si un contenu a été décodé, afficher la prévisualisation
              if (_decodedResult != null && _decodedResult!.isSuccess)
                Expanded(
                  child: _buildPreviewView(workoutProvider),
                )
              else ...[
                // Onglets de capture (Scanner QR vs Coller un code)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: AppTheme.athleticBlue,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(icon: Icon(Icons.qr_code_scanner), text: "Scanner QR"),
                        Tab(icon: Icon(Icons.content_paste_rounded), text: "Coller un code"),
                      ],
                    ),
                  ),
                ),

                if (_parseError != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _parseError!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildQrScannerTab(),
                      _buildPasteCodeTab(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ==================== ONGLET SCANNER QR ====================

  Widget _buildQrScannerTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      final barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          _processScannedCode(barcode.rawValue!);
                          break;
                        }
                      }
                    },
                  ),
                  // Cadre de cadrage visuel
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.athleticBlue, width: 2.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Pointez votre appareil vers le QR Code affiché sur l'autre téléphone.",
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== ONGLET COLLER UN CODE ====================

  Widget _buildPasteCodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _codeController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: "Collez ici le code de partage (ex: SPRT1_...)",
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
              filled: true,
              fillColor: AppTheme.darkSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.darkBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.darkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.athleticBlue, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              if (_codeController.text.trim().isNotEmpty) {
                _processScannedCode(_codeController.text.trim());
              }
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text("Analyser et Prévisualiser", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.athleticBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== VUE PREVISUALISATION ====================

  Widget _buildPreviewView(WorkoutProvider provider) {
    final res = _decodedResult!;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.greenCheck.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.greenCheck.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppTheme.greenCheck, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    res.type == ShareDataType.program
                        ? "Programme détecté et prêt à être importé"
                        : "Exercice(s) détecté(s)",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _decodedResult = null;
                      _isScanningActive = true;
                    });
                  },
                  child: const Text("Annuler", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (res.type == ShareDataType.program && res.program != null) ...[
            Text(
              res.program!.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
            ),
            if (res.program!.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                res.program!.description,
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              "Contenu du programme (${res.program!.exercises.length} exercices) :",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: res.program!.exercises.length,
                itemBuilder: (context, idx) {
                  final pe = res.program!.exercises[idx];
                  final existingEx = provider.exercises.where((e) => e.id == pe.exerciseId).firstOrNull;
                  final embeddedCustom = res.exercises.where((e) => e.id == pe.exerciseId).firstOrNull;
                  final name = existingEx?.name ?? embeddedCustom?.name ?? pe.exerciseId;
                  final category = existingEx?.category ?? embeddedCustom?.category ?? 'Autre';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: AppTheme.darkSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      dense: true,
                      leading: CategoryBadge(category: category, compact: true),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      trailing: Text(
                        "${pe.setsCount} séries • ${pe.repsCount > 0 ? '${pe.repsCount} reps' : ''}",
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else if (res.exercises.isNotEmpty) ...[
            Text(
              "${res.exercises.length} exercice(s) à importer :",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: res.exercises.length,
                itemBuilder: (context, idx) {
                  final ex = res.exercises[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: AppTheme.darkSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      dense: true,
                      leading: CategoryBadge(category: ex.category, compact: true),
                      title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: (ex.equipment != null && ex.equipment!.isNotEmpty) || (ex.notes != null && ex.notes!.isNotEmpty)
                          ? Text(
                              [
                                if (ex.equipment != null && ex.equipment!.isNotEmpty) ex.equipment!,
                                if (ex.notes != null && ex.notes!.isNotEmpty) ex.notes!,
                              ].join(" • "),
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _importData(provider),
              icon: const Icon(Icons.download_done_rounded, color: Colors.white),
              label: const Text(
                "Confirmer l'importation",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.athleticBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
