import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dio_client.dart';
import 'package:lottie/lottie.dart';

class PasswordPage extends StatefulWidget {
  final Map<String, dynamic> personnel;

  const PasswordPage({Key? key, required this.personnel}) : super(key: key);

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final TextEditingController nomController = TextEditingController();
  final TextEditingController mdpController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool showPassword = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    print(widget.personnel);
    nomController.text = widget.personnel['nom'] ?? '';
  }

void _validerMotDePasse() async {
  final mdp = mdpController.text;
  final confirm = confirmController.text;

  if (mdp.isEmpty || confirm.isEmpty) {
    _showAlert("Veuillez remplir tous les champs.");
    return;
  }

  if (mdp != confirm) {
    _showAlert("Les mots de passe ne correspondent pas.");
    return;
  }

  if (mdp.length < 5) {
    _showAlert("Le mot de passe doit contenir au moins 5 caractères.");
    return;
  }

  setState(() => isLoading = true);

  try {
    final response = await DioClient().dio.post(
      '/clients/',
      data: {
        'idpers': widget.personnel['idpers'],
        'mdp': mdp,
      },
      options: Options(
        extra: {'withCredentials': true},
        validateStatus: (status) => true,
      ),
    );

    if (response.statusCode == 201) {
      final client = response.data['client'];
      final matricule = widget.personnel['matricule']; // récupère matricule du personnel
      final mdpPlain = mdp; // mot de passe saisi par l’utilisateur

    _showSuccesDialog(context ,"Compte créé avec succès, connexion en cours...");
   
      // ⚡ Login auto
      Future.delayed(const Duration(seconds: 1), () {
              _login(matricule, mdpPlain);
      });
    } else {
      _showAlert(response.data['error'] ?? 'Erreur lors de la création');
    }
  } catch (e) {
    final error = (e is DioException && e.response != null)
        ? e.response?.data['message'] ?? 'Erreur du serveur'
        : 'Erreur de connexion';
    _showAlert(error);
  } finally {
    setState(() => isLoading = false);
  }
}

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Information"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
 
  Future<void> _showSuccesDialog(BuildContext context, String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Lottie.asset('assets/succes.json', repeat: false),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

 Future<void> _login(String matricule, String mdp) async {
    final dioClient1 = DioClient();
    try {
      final response = await dioClient1.dio.post(
        '/auth/connexion',
        data: {'matricule': matricule, 'mdp': mdp},
        options: Options(
          extra: {'withCredentials': true},
          validateStatus: (status) => true, // <-- accepte tous les codes
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final personnel = data['client']['personnel'];

        print('data : $data');
        print('Login réussi');
        // Vérifier cookie stocké
        final cookies = await dioClient1.cookieJar.loadForRequest(
          Uri.parse(dioClient1.dio.options.baseUrl! + '/connexion'),
        );
        print('Cookies après login : $cookies');

        // Connexion réussie, redirection
        Navigator.pushNamed(
          context,
          '/pointage',
          arguments: personnel, // passe l'objet personnel comme argument
        );
      } else {
        _showAlert( response.data['error']);
      Navigator.of(context).pop(); // revient à la page précédente
    }
    } catch (e) {
      _showAlert( e.toString());
     Navigator.of(context).pop(); // revient à la page précédente
    }
  }

  @override
  void dispose() {
    nomController.dispose();
    mdpController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color.fromARGB(255, 51, 94, 143),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        title: Text(
          "Definir mot de passe",
          style: TextStyle(
            color: const Color.fromARGB(255, 51, 94, 143),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              const SizedBox(height: 25),

              // Champ nom (readonly)
              Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.only(bottom: 35),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                  leading: const Icon(Icons.person, color: Color(0xFF3A5579)),
                  title: TextField(
                    controller: nomController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: "Nom",
                      labelStyle: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                ),
              ),

              // Champ mot de passe
              Container(
                margin: const EdgeInsets.only(bottom: 25),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                  leading: const Icon(Icons.lock, color: Color(0xFF3A5579)),
                  title: TextField(
                    controller: mdpController,
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      border: const UnderlineInputBorder(),
                      labelText: "Mot de passe",
                      helperText: "Au moins 5 caractères",
                      helperStyle: const TextStyle(fontSize: 14),
                      labelStyle: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => showPassword = !showPassword),
                        icon: Icon(
                          showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF3A5579),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Champ confirmation
              Container(
                margin: const EdgeInsets.only(bottom: 25),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                  leading: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF3A5579),
                  ),
                  title: TextField(
                    controller: confirmController,
                    obscureText: !showPassword,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: "Confirmer le mot de passe",
                      labelStyle: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                ),
              ),

              // Bouton en bas
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _validerMotDePasse,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      backgroundColor: const Color(0xFF3A5579),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Valider",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
