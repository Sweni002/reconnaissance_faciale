import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dio_client.dart';

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

  setState(() => isLoading = true); // ⏳ Démarre le chargement

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
if (mdp.length < 5) {
  _showAlert("Le mot de passe doit contenir au moins 5 caractères.");
  return;
}
    if (response.statusCode == 201) {
      _showAlert(response.data['message']);
    } else {
      _showAlert(response.data['error']);
    }
  } catch (e) {
    final error = (e is DioException && e.response != null)
        ? e.response?.data['message'] ?? 'Erreur du serveur'
        : 'Erreur de connexion';
    _showAlert(error);
  }finally {
    setState(() => isLoading = false); // ✅ Fin du chargement
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
      backgroundColor: Colors.white ,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
         leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color.fromARGB(255, 51, 94, 143)),
          onPressed: () => Navigator.pop(context),
          
        ),
        centerTitle: false,
        title: Text("Definir mot de passe" ,style: TextStyle(color: const Color.fromARGB(255, 51, 94, 143) ,
        fontWeight:  FontWeight.bold ,letterSpacing: 1),),
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
                labelStyle: const TextStyle(fontSize: 18, color: Colors.grey),
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
            leading: const Icon(Icons.lock_outline, color: Color(0xFF3A5579)),
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
                      style:
                          TextStyle(fontSize: 18, color: Colors.white),
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
