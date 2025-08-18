import 'package:flutter/material.dart';
import 'package:awesome_calendart/awesome_calendart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dio_client.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class PointagePage extends StatefulWidget {
  const PointagePage({super.key});

  @override
  State<PointagePage> createState() => _PointagePageState();
}

class _PointagePageState extends State<PointagePage> {
  DateTime selectedDate = DateTime.now();
  String? idpers;
  int? idpersa;
  String? nomPersonnel;
  String? imagePersonnel;
List<PointageMensuel> data = [];

  final dioClient = DioClient();
  bool isLoading = true;

  Map<String, dynamic>? pointageData;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final personnel = ModalRoute.of(context)?.settings.arguments as Map?;

      if (personnel == null) {
        // Redirection vers la route d'accueil si aucun personnel n'est fourni
        Navigator.of(context).pushReplacementNamed('/');
        return;
      }

      idpers = personnel['idpers'].toString();
      idpersa = personnel['idpers'];
      nomPersonnel = personnel['nom']; // 🟢 Récupère le nom ici
      imagePersonnel = personnel['image']; // ⚠️ null si pas d'image
      _fetchPointageMensuel(idpersa!);

      _fetchPointage(idpers!);
      setState(() {}); // Mettre à jour l'affichage
    });
  }

  Future<bool> _onWillPop() async {
    // Ici on bloque le retour (bouton back), tu peux afficher un toast ou dialog si tu veux
    return false;
  }

  Future<void> _fetchPointage(String idpers) async {
    setState(() {
      isLoading = true;
    });
    final String formattedDate =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    try {
      final response = await dioClient.dio.get(
        '/pointage/facial/par_date',
        queryParameters: {'date': formattedDate, 'idpers': idpers},
        options: Options(
          extra: {'withCredentials': true},
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        setState(() {
          pointageData = data.isNotEmpty ? data.first : null;
          print("Pointage récupéré : $pointageData");
          isLoading = false;
        });
      } else {
        print("Erreur: ${response.data}");
      }
    } catch (e) {
      print("Erreur de requête : $e");
    }
  }

  void _deconnecter() {
    Navigator.of(context).pushReplacementNamed('/');
  }

  Future<void> _fetchPointageMensuel(int idpers) async {
    try {
      final response = await dioClient.dio.get(
        '/pointage/facial/resume_par_mois',
        queryParameters: {'idpers': idpers},
        options: Options(
          extra: {'withCredentials': true},
          validateStatus: (status) => true,
        ),
      );
if (response.statusCode == 200) {
  final List jsonData = response.data;

  setState(() {
    data = jsonData.map((e) {
      // Assure-toi que les valeurs sont bien des int
      return PointageMensuel.fromJson({
        "mois": e['mois'] is int ? e['mois'] : int.parse(e['mois'].toString()),
        "annee": e['annee'] is int ? e['annee'] : int.parse(e['annee'].toString()),
        "nb_jours_pointages": e['nb_jours_pointages'] is int
            ? e['nb_jours_pointages']
            : int.parse(e['nb_jours_pointages'].toString()),
        "jours_presence": e['jours_presence'] is int
            ? e['jours_presence']
            : int.parse(e['jours_presence'].toString()),
        "jours_absence": e['jours_absence'] is int
            ? e['jours_absence']
            : int.parse(e['jours_absence'].toString()),
      });
    }).toList();
  });

} else {
  print("Erreur API résumé : ${response.data}");
}
    } catch (e) {
      print("Erreur récupération résumé mensuel : $e");
    }
  }

  String _moisEnFrancais(int mois) {
    const moisFr = [
      '', // index 0 inutilisé
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return moisFr[mois];
  }

 
  String formatHeure(String heure) {
    if (heure == "---" || heure.isEmpty) return "---";
    // On suppose que l'heure est toujours au format HH:mm
    return heure.replaceFirst(":", "h:");
  }

  Widget buildSessionTile({
    required String title,
    required Color color,
    required IconData icon,
    required String statut,
    required String entree,
    required String sortie,
    required IconData entreeIcon,
    required IconData sortieIcon,
    required Color entreeColor,
    required Color sortieColor,
    String? justificatif,
  }) {
    // Détermine si la personne est absente (entrée et sortie à "---")
    final bool isAbsent = entree == "---" && sortie == "---";

    // Ne pas afficher l'icône d'expansion si absent ET pas de justificatif valide
    final bool hideExpansionIcon =
        isAbsent &&
        (justificatif == null ||
            justificatif.trim().isEmpty ||
            justificatif.trim().toLowerCase() == "null");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 15,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ExpansionTile(
          iconColor: Colors.grey,
          collapsedIconColor: Colors.grey,
          initiallyExpanded: true,
          trailing: hideExpansionIcon
              ? SizedBox.shrink()
              : null, // ici la condition
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: const Color(0xFF2C2C2C),
          collapsedBackgroundColor: const Color(0xFF2C2C2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: Icon(icon, size: 35, color: color),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          subtitle: Text(
            statut,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.grey,
              letterSpacing: 2,
            ),
          ),
          children: [
            if (!isAbsent) // Affiche les heures uniquement si présent
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: entreeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(entreeIcon, color: entreeColor, size: 28),
                            const SizedBox(height: 5),
                            Text(
                              formatHeure(entree),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: entreeColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              "Entrée",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(
                                  255,
                                  96,
                                  125,
                                  141,
                                ), // Bleu-gris foncé, agréable et lisible
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: sortieColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(sortieIcon, color: sortieColor, size: 28),
                            const SizedBox(height: 5),
                            Text(
                              formatHeure(sortie),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: sortieColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              "Sortie",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(
                                  255,
                                  131,
                                  76,
                                  76,
                                ), // Gris moyen
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Affiche le justificatif même en cas d’absence
            if (justificatif != null &&
                justificatif.trim().isNotEmpty &&
                justificatif.trim().toLowerCase() != "null") ...[
              const Divider(color: Colors.white12, indent: 20, endIndent: 20),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note_alt, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Justificatif : $justificatif",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color.fromARGB(255, 56, 56, 56),
          elevation: 0,
          titleSpacing: 0,
          title: Row(
            children: [
              const SizedBox(width: 15),
              Container(
                width: 45,
                height: 40,
                child: Image.asset('assets/finances.png', fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Text(
                "${selectedDate.day} ${_moisEnFrancais(selectedDate.month)} ${selectedDate.year}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 88, 135, 197),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () async {
                  final logout = await showMenu<String>(
                    context: context,
                    color: const Color.fromARGB(255, 56, 56, 56),
                    position: RelativeRect.fromLTRB(1000, 80, 20, 100),
                    items: [
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: const [
                            Icon(Icons.logout, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'Se déconnecter',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );

                  if (logout == 'logout') {
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                },
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade300,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: imagePersonnel != null
                        ? NetworkImage(
                            'http://127.0.0.1:5000/uploads/${imagePersonnel!}',
                          )
                        : null,
                    child: imagePersonnel == null
                        ? Text(
                            nomPersonnel != null && nomPersonnel!.isNotEmpty
                                ? nomPersonnel![0]
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black87,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),

        backgroundColor: const Color.fromARGB(255, 41, 41, 41),

        body: SingleChildScrollView(
          child: Column(
            children: [
              // 📅 Calendrier
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 25,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C), // Fond plus sombre et élégant
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Titre personnalisé
                    Row(
                      children: const [
                        Icon(
                          Icons.calendar_month,
                          color: Colors.deepPurpleAccent,
                          size: 24,
                        ),
                        SizedBox(width: 10),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 📅 Calendrier amélioré
                    TableCalendar(
                      locale: 'fr_FR',
                      calendarFormat: CalendarFormat.month,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Mois',
                      },
                      firstDay: DateTime(2000),
                      lastDay: DateTime(2100),
                      focusedDay: selectedDate,
                      selectedDayPredicate: (day) =>
                          isSameDay(day, selectedDate),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          selectedDate = selectedDay;
                        });
                        if (idpers != null) {
                          _fetchPointage(idpers!);
                        }
                      },
                      onPageChanged: (focusedDay) {
                        setState(() {
                          selectedDate = focusedDay;
                        });
                      },
                      headerStyle: const HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: const TextStyle(color: Colors.white),
                        weekendTextStyle: const TextStyle(color: Colors.grey),
                        outsideDaysVisible: false,
                        todayDecoration: BoxDecoration(
                          color: Colors.deepPurpleAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurpleAccent.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: const TextStyle(color: Colors.white),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekendStyle: TextStyle(color: Colors.grey),
                        weekdayStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),

              // 🌤️ Matin
              if (pointageData != null) ...[
                buildSessionTile(
                  title: "Matin",
                  color: const Color.fromARGB(255, 51, 94, 143),
                  icon: Icons.wb_sunny_outlined,
                  statut: pointageData!['absence_matin'] == true
                      ? "Absent"
                      : (pointageData!['retard_matin'] == true
                            ? "Retard"
                            : (pointageData!['heure_entree_matin'] == null &&
                                      pointageData!['heure_sortie_matin'] ==
                                          null
                                  ? "---"
                                  : "Présent")),
                  entree: pointageData!['heure_entree_matin'] ?? "---",
                  sortie: pointageData!['heure_sortie_matin'] ?? "---",
                  entreeIcon: Icons.login,
                  sortieIcon: Icons.settings_backup_restore_rounded,
                  entreeColor: Colors.green, // ✅ Toujours la même couleur
                  sortieColor: Colors.red,
                  justificatif:
                      pointageData!['justificatif'], // ✅ Toujours la même couleur
                ),
                buildSessionTile(
                  title: "Après-midi",
                  color: Colors.deepPurple,
                  icon: Icons.nightlight_round,
                  statut: pointageData!['absence_soir'] == true
                      ? "Absent"
                      : (pointageData!['retard_soir'] == true
                            ? "Retard"
                            : (pointageData!['heure_entree_soir'] == null &&
                                      pointageData!['heure_sortie_soir'] == null
                                  ? "---"
                                  : "Présent")),
                  entree: pointageData!['heure_entree_soir'] ?? "---",
                  sortie: pointageData!['heure_sortie_soir'] ?? "---",
                  entreeIcon: Icons.login,
                  sortieIcon: Icons.settings_backup_restore_rounded,
                  entreeColor: Colors.orange, // ✅ Même couleur même si null
                  sortieColor: Colors.redAccent,
                  justificatif:
                      pointageData!['justificatif'], // ✅ Même couleur même si null
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      "Aucun pointage pour ce jour",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // 📈 Résumé mensuel amélioré
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C), // Fond plus doux
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
   child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        const Icon(
          Icons.pie_chart_outline,
          color: Colors.deepPurpleAccent,
          size: 24,
        ),
        const SizedBox(width: 10),
        // Texte dynamique selon les absences
        Text(
          (data.any((p) => p.joursAbsence != null && p.joursAbsence > 0))
              ? "Absence par mois"
              : "Présence par mois",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ],
    ),
    const SizedBox(height: 20),
    SizedBox(
      height: 440,
      child: SfCircularChart(
        backgroundColor: Colors.transparent,
        legend: Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap,
          textStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          format: 'point.x : point.y jours',
        ),
        series: <DoughnutSeries<PointageMensuel, String>>[
          DoughnutSeries<PointageMensuel, String>(
            dataSource: data,
            xValueMapper: (PointageMensuel p, _) => _moisEnFrancais(p.mois),
            yValueMapper: (PointageMensuel p, _) =>
                (p.joursAbsence == 0 || p.joursAbsence == null)
                    ? p.joursPresence
                    : p.joursAbsence,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            radius: '85%',
            innerRadius: '65%',
            explode: true,
            explodeIndex: 0,
            name: (data.any((p) =>
                    p.joursAbsence != null && p.joursAbsence > 0))
                ? 'Absence'
                : 'Présence',
            pointColorMapper: (PointageMensuel p, _) {
              switch (p.mois) {
                case 1: return Colors.indigo;
                case 2: return Colors.deepPurple;
                case 3: return Colors.purpleAccent;
                case 4: return Colors.teal;
                case 5: return Colors.green;
                case 6: return Colors.orange;
                case 7: return Colors.redAccent;
                case 8: return Colors.brown;
                case 9: return Colors.cyan;
                case 10: return Colors.amber;
                case 11: return Colors.pink;
                case 12: return Colors.lime;
                default: return Colors.grey;
              }
            },
          ),
        ],
      ),
    ),
  ],
)
              ),
              ),
            ],
          ),
        ),

        // ⚙️ FAB
      floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Options',
                style: TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(255, 206, 205, 205),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: ()async {
                        Navigator.pop(context);
                     await Navigator.pushNamed(context, '/entree');
  
  _fetchPointageMensuel(idpersa!);
  _fetchPointage(idpers!);
       },
                      icon: const Icon(Icons.login, size: 25),
                      label: const Text(
                        "Entrée",
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 31, 58, 88),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: ()async {
                        Navigator.pop(context);
             await Navigator.pushNamed(context, '/sortie');

  // Une fois de retour, on rafraîchit
  _fetchPointageMensuel(idpersa!);
  _fetchPointage(idpers!);
       },
                      icon: const Icon(Icons.settings_backup_restore_sharp, size: 27),
                      label: const Text(
                        "Sortie",
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2C),
                        foregroundColor: const Color.fromARGB(255, 51, 94, 143),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 51, 94, 143),
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  },
  icon: const Icon(Icons.fit_screen_sharp),
  label: const Text("Scan"),
  backgroundColor: const Color.fromARGB(255, 43, 62, 88),
  elevation: 10,
),

      ),
    );
  }
}

class PointageMensuel {
  final int mois;
  final int annee;
  final int nbJoursPointages;
  final int joursPresence;
  final int joursAbsence;

  PointageMensuel({
    required this.mois,
    required this.annee,
    required this.nbJoursPointages,
    required this.joursPresence,
    required this.joursAbsence,
  });

factory PointageMensuel.fromJson(Map<String, dynamic> json) {
  return PointageMensuel(
    mois: json['mois'] is String ? int.parse(json['mois']) : json['mois'],
    annee: json['annee'] is String ? int.parse(json['annee']) : json['annee'],
    nbJoursPointages: json['nb_jours_pointages'] == null
        ? 0
        : (json['nb_jours_pointages'] is String
            ? int.parse(json['nb_jours_pointages'])
            : json['nb_jours_pointages']),
    joursPresence: json['jours_presence'] == null
        ? 0
        : (json['jours_presence'] is String
            ? int.parse(json['jours_presence'])
            : json['jours_presence']),
    joursAbsence: json['jours_absence'] == null
        ? 0
        : (json['jours_absence'] is String
            ? int.parse(json['jours_absence'])
            : json['jours_absence']),
  );
}


}
