import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../providers/workout_provider.dart';
import '../theme.dart';
import '../widgets/category_badge.dart';

class WorkoutRecapScreen extends StatefulWidget {
  const WorkoutRecapScreen({super.key});

  @override
  State<WorkoutRecapScreen> createState() => _WorkoutRecapScreenState();
}

class _WorkoutRecapScreenState extends State<WorkoutRecapScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  // Filtre de période : 'month' ou 'year'
  String _periodType = 'month'; // 'month', 'last_month', 'year'

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);
    final history = provider.history;
    final now = DateTime.now();

    // 1. Filtrer selon la période
    late DateTime startDate;
    late DateTime endDate;
    late String periodLabel;

    if (_periodType == 'month') {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      periodLabel = DateFormat('MMMM yyyy', 'fr_FR').format(now);
    } else if (_periodType == 'last_month') {
      final prevMonthDate = DateTime(now.year, now.month - 1, 1);
      startDate = DateTime(prevMonthDate.year, prevMonthDate.month, 1);
      endDate = DateTime(prevMonthDate.year, prevMonthDate.month + 1, 0, 23, 59, 59);
      periodLabel = DateFormat('MMMM yyyy', 'fr_FR').format(prevMonthDate);
    } else {
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31, 23, 59, 59);
      periodLabel = "Année ${now.year}";
    }

    final periodSessions = history.where((s) {
      return s.startTime.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          s.startTime.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();

    // 2. Calculer les statistiques récapitulatives
    int totalWorkouts = periodSessions.length;
    int totalMinutes = 0;
    double totalVolumeKg = 0;
    Map<String, int> exerciseSetsCount = {};
    Map<String, double> exerciseMaxWeight = {};
    Map<String, int> categorySetsCount = {};
    int prCount = 0;

    for (var session in periodSessions) {
      if (session.endTime != null) {
        totalMinutes += session.endTime!.difference(session.startTime).inMinutes;
      }
      totalVolumeKg += provider.calculateSessionVolume(session);

      for (var perfEx in session.exercises) {
        final completedSets = perfEx.sets.where((s) => s.isCompleted).toList();
        if (completedSets.isEmpty) continue;

        final ex = provider.exercises.firstWhere(
          (e) => e.id == perfEx.exerciseId,
          orElse: () => Exercise(id: perfEx.exerciseId, name: 'Inconnu', category: 'Autre'),
        );

        // Compter les séries par exercice
        exerciseSetsCount[ex.name] = (exerciseSetsCount[ex.name] ?? 0) + completedSets.length;

        // Charge max par exercice
        final maxW = completedSets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
        if ((exerciseMaxWeight[ex.name] ?? 0) < maxW) {
          exerciseMaxWeight[ex.name] = maxW;
        }

        // Catégories
        final cats = ex.categories.isNotEmpty ? ex.categories : [ex.category];
        for (var c in cats) {
          categorySetsCount[c] = (categorySetsCount[c] ?? 0) + completedSets.length;
        }

        // PRs
        prCount += completedSets.where((s) => s.isWeightPR || s.is1RMPR).length;
      }
    }

    final double totalTons = totalVolumeKg / 1000.0;

    // Exercice favori
    String? favoriteExercise;
    int favoriteExerciseSets = 0;
    if (exerciseSetsCount.isNotEmpty) {
      final sorted = exerciseSetsCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      favoriteExercise = sorted.first.key;
      favoriteExerciseSets = sorted.first.value;
    }

    // Groupe musculaire roi
    String? topMuscle;
    int topMuscleSets = 0;
    if (categorySetsCount.isNotEmpty) {
      final sortedCats = categorySetsCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topMuscle = sortedCats.first.key;
      topMuscleSets = sortedCats.first.value;
    }

    // Équivalence fun
    String equivalentFun = "";
    if (totalTons >= 50) {
      equivalentFun = "C'est l'équivalent du poids d'un avion de ligne Boeing 737 ✈️ !";
    } else if (totalTons >= 20) {
      equivalentFun = "C'est l'équivalent du poids de 4 éléphants d'Afrique 🐘 !";
    } else if (totalTons >= 5) {
      equivalentFun = "C'est l'équivalent du poids de 4 voitures citadines 🚗 !";
    } else if (totalTons > 0) {
      equivalentFun = "C'est l'équivalent de 5 grands chevaux de trait 🐎 !";
    }

    return Scaffold(
      backgroundColor: const Color(0xff090a0f),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Bilan • $periodLabel",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_month, color: AppTheme.athleticBlue),
            tooltip: "Changer la période",
            onSelected: (val) {
              setState(() {
                _periodType = val;
                _currentPage = 0;
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(0);
                }
              });
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'month', child: Text("Mois en cours")),
              PopupMenuItem(value: 'last_month', child: Text("Mois dernier")),
              PopupMenuItem(value: 'year', child: Text("Année complète")),
            ],
          ),
        ],
      ),
      body: totalWorkouts == 0
          ? _buildEmptyState(periodLabel)
          : Column(
              children: [
                // Story-like progress bars at the top
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: List.generate(_totalPages, (index) {
                      final isCurrent = index == _currentPage;
                      final isPassed = index < _currentPage;

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: isPassed
                                ? AppTheme.athleticBlue
                                : (isCurrent ? Colors.white : Colors.white.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Main Slide Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                    },
                    children: [
                      // Slide 1: Volume & Dévouement
                      _buildSlideVolume(
                        periodLabel: periodLabel,
                        totalWorkouts: totalWorkouts,
                        totalMinutes: totalMinutes,
                        totalTons: totalTons,
                        equivalentFun: equivalentFun,
                      ),

                      // Slide 2: Exercice Favori
                      _buildSlideFavoriteExercise(
                        favoriteExercise: favoriteExercise ?? "Aucun",
                        setsCount: favoriteExerciseSets,
                        maxWeight: exerciseMaxWeight[favoriteExercise] ?? 0.0,
                      ),

                      // Slide 3: Records & PRs
                      _buildSlideRecords(
                        prCount: prCount,
                        provider: provider,
                        periodSessions: periodSessions,
                      ),

                      // Slide 4: Anatomie & Muscles
                      _buildSlideMuscleFocus(
                        topMuscle: topMuscle ?? "Général",
                        topMuscleSets: topMuscleSets,
                        totalSets: categorySetsCount.values.fold(0, (a, b) => a + b),
                        categoryMap: categorySetsCount,
                      ),

                      // Slide 5: Carte Récapitulative Partageable
                      _buildSlideSummaryCard(
                        periodLabel: periodLabel,
                        totalWorkouts: totalWorkouts,
                        totalTons: totalTons,
                        totalMinutes: totalMinutes,
                        prCount: prCount,
                        favoriteExercise: favoriteExercise ?? "N/A",
                        topMuscle: topMuscle ?? "N/A",
                      ),
                    ],
                  ),
                ),

                // Bottom Navigation controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        IconButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
                        )
                      else
                        const SizedBox(width: 48),

                      Text(
                        "${_currentPage + 1} / $_totalPages",
                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                      ),

                      if (_currentPage < _totalPages - 1)
                        IconButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.arrow_forward_ios, color: AppTheme.athleticBlue, size: 20),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check, color: Colors.white, size: 18),
                          label: const Text("Fermer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.athleticBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(String periodLabel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              "Aucun entraînement pour $periodLabel",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Terminez vos séances de sport pour débloquer votre récapitulatif périodique !",
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SLIDE 1 : VOLUME ====================

  Widget _buildSlideVolume({
    required String periodLabel,
    required int totalWorkouts,
    required int totalMinutes,
    required double totalTons,
    required String equivalentFun,
  }) {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff2563eb), Color(0xff7c3aed)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff2563eb).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.fitness_center, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 28),
          Text(
            "VOTRE DÉVOUEMENT",
            style: TextStyle(letterSpacing: 2, color: AppTheme.athleticBlue, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            "$totalWorkouts Séances Réalisées",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.white),
          ),
          if (totalMinutes > 0) ...[
            const SizedBox(height: 4),
            Text(
              "Temps total : ${hours > 0 ? '${hours}h ' : ''}${mins}min",
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
          const SizedBox(height: 32),

          // Tonnage Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Column(
              children: [
                Text(
                  "${totalTons.toStringAsFixed(1)} Tonnes",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Color(0xff38bdf8)),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Volume cumulé déplacé",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (equivalentFun.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    equivalentFun,
                    style: const TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SLIDE 2 : EXERCICE ROI ====================

  Widget _buildSlideFavoriteExercise({
    required String favoriteExercise,
    required int setsCount,
    required double maxWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xfff59e0b), Color(0xffef4444)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 28),
          const Text(
            "VOTRE EXERCICE FAVORI",
            style: TextStyle(letterSpacing: 2, color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            favoriteExercise,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "$setsCount",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      const Text("Séries au total", style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "${maxWeight.toStringAsFixed(1).replaceAll('.0', '')} kg",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.amber),
                      ),
                      const SizedBox(height: 4),
                      const Text("Charge Maximale", style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SLIDE 3 : RECORDS & PRs ====================

  Widget _buildSlideRecords({
    required int prCount,
    required WorkoutProvider provider,
    required List<WorkoutSession> periodSessions,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff10b981), Color(0xff06b6d4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 28),
          const Text(
            "HALL OF FAME",
            style: TextStyle(letterSpacing: 2, color: Color(0xff10b981), fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            prCount > 0 ? "$prCount Nouveaux Records Débloqués !" : "Constance & Puissance",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            prCount > 0
                ? "Chaque répétition vous a rapproché de votre meilleure version."
                : "Votre rigueur aux entraînements construit votre force de demain.",
            style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== SLIDE 4 : ANATOMIE ====================

  Widget _buildSlideMuscleFocus({
    required String topMuscle,
    required int topMuscleSets,
    required int totalSets,
    required Map<String, int> categoryMap,
  }) {
    final double pct = totalSets > 0 ? (topMuscleSets / totalSets) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xffec4899), Color(0xff8b5cf6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.accessibility_new_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 28),
          const Text(
            "GROUPE MUSCULAIRE ROI",
            style: TextStyle(letterSpacing: 2, color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            topMuscle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            "$topMuscleSets séries (${pct.toStringAsFixed(0)}% du travail global)",
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Liste des 3 principaux groupes
          ...categoryMap.entries.take(3).map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CategoryBadge(category: e.key, compact: true),
                  Text("${e.value} séries", style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== SLIDE 5 : CARTE POSTER PARTAGEABLE ====================

  Widget _buildSlideSummaryCard({
    required String periodLabel,
    required int totalWorkouts,
    required double totalTons,
    required int totalMinutes,
    required int prCount,
    required String favoriteExercise,
    required String topMuscle,
  }) {
    final hours = totalMinutes ~/ 60;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Visual Poster Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff1e1b4b), Color(0xff0f172a), Color(0xff172554)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.athleticBlue.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.fitness_center, color: AppTheme.athleticBlue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "SPORTILIFE RECAP",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5, color: Colors.white),
                        ),
                      ],
                    ),
                    Text(
                      periodLabel,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                        label: "Séances",
                        value: "$totalWorkouts",
                        icon: Icons.check_circle_outline,
                        color: const Color(0xff38bdf8),
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryMetric(
                        label: "Volume Déplacé",
                        value: "${totalTons.toStringAsFixed(1)} T",
                        icon: Icons.insights,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                        label: "Temps Entraînement",
                        value: "${hours}h",
                        icon: Icons.timer_outlined,
                        color: const Color(0xff10b981),
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryMetric(
                        label: "Records (PRs)",
                        value: "$prCount",
                        icon: Icons.emoji_events_outlined,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Exercice Roi", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text(
                              favoriteExercise,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      CategoryBadge(category: topMuscle, compact: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bouton Copier / Partager
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                final summaryText = """🏋️‍♂️ Mon Bilan SportiLife ($periodLabel) :
• $totalWorkouts séances réalisées (${hours}h d'entraînement)
• ${totalTons.toStringAsFixed(1)} Tonnes soulevées au total
• $prCount records personnels battus !
• Exercice favori : $favoriteExercise
• Groupe musculaire le plus entraîné : $topMuscle

Suivez vos entraînements avec SportiLife ! 🔥""";

                Clipboard.setData(ClipboardData(text: summaryText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Bilan copié dans le presse-papier ! Partagez-le à vos amis."),
                    backgroundColor: AppTheme.athleticBlue,
                  ),
                );
              },
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text(
                "Copier & Partager mon bilan",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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

  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}
