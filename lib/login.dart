import 'package:flutter/material.dart';
import 'dio_client.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});
  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;

  final TextEditingController nomController = TextEditingController();
  final TextEditingController mdpController = TextEditingController();

  final dioClient = DioClient();

  Future<void> _login() async {
    final matricule = nomController.text.trim();
    final mdp = mdpController.text.trim();

    if (matricule.isEmpty || mdp.isEmpty) {
      _showDialog(
        'Champs requis',
        'Veuillez entrer votre nom et votre mot de passe.',
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await dioClient.dio.post(
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
        final cookies = await dioClient.cookieJar.loadForRequest(
          Uri.parse(dioClient.dio.options.baseUrl! + '/connexion'),
        );
        print('Cookies après login : $cookies');

        // Connexion réussie, redirection
        Navigator.pushNamed(context, '/pointage' ,
         arguments: personnel, // passe l'objet personnel comme argument
);
      } else {
        _showDialog('Erreur', response.data['message']);
      }
    } catch (e) {
      _showDialog('Erreur', 'Veuillez verifier le connexion');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

  return Scaffold(
    extendBodyBehindAppBar: true,
    resizeToAvoidBottomInset: true,
    backgroundColor: Colors.white,
    body: Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 210,
                  width: double.infinity,
                  child: Image.asset('assets/v2.jpg', fit: BoxFit.cover),
                ),

                Transform.translate(
                  offset: const Offset(0, -55),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 30,
                    ),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(65),
                        topRight: Radius.circular(65),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 15),
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            "Connexion",
                            style: TextStyle(
                              fontSize: 28,
                              letterSpacing: 2,
                              color: Color.fromARGB(255, 13, 91, 136),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(bottom: 35, top: 5),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 30,
                            ),
                            leading: const Icon(
                              Icons.email,
                              size: 27,
                              color: Color.fromARGB(255, 58, 85, 121),
                            ),
                            title: TextField(
                              controller: nomController,
                              decoration: const InputDecoration(
                                border: UnderlineInputBorder(),
                                labelText: "Nom",
                                labelStyle: TextStyle(
                                  fontSize: 18,
                                  color: Color.fromARGB(255, 117, 117, 117),
                                ),
                              ),
                            ),
                          ),
                        ),

                        Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(bottom: 25),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 30,
                            ),
                            leading: const Icon(
                              Icons.lock_clock_rounded,
                              size: 27,
                              color: Color.fromARGB(255, 58, 85, 121),
                            ),
                            title: TextField(
                              controller: mdpController,
                              obscureText: true,
                              decoration: InputDecoration(
                                border: const UnderlineInputBorder(),
                                labelText: "Mot de passe",
                                labelStyle: const TextStyle(
                                  fontSize: 18,
                                  color: Color.fromARGB(255, 117, 117, 117),
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.remove_red_eye_rounded,
                                    size: 27,
                                    color: Color.fromARGB(255, 58, 85, 121),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 51, 94, 143),
                              padding: const EdgeInsets.all(22),
                              elevation: 8,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    "Se connecter",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Vous n'avez pas de compte ?",
                              style: TextStyle(fontSize: 15),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/create');
                              },
                              child: const Text(
                                "Inscrivez-vous",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    floatingActionButton: isKeyboardVisible
        ? null
        : FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/entree');
                                },
                                icon: const Icon(Icons.login, size: 25),
                                label: const Text(
                                  "Entrée",
                                  style: TextStyle(fontSize: 18),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    51,
                                    94,
                                    143,
                                  ),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 22,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.settings_backup_restore_sharp,
                                  size: 27,
                                ),
                                label: const Text(
                                  "Sortie",
                                  style: TextStyle(fontSize: 18),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color.fromARGB(
                                    255,
                                    51,
                                    94,
                                    143,
                                  ),
                                  side: const BorderSide(
                                    color: Color.fromARGB(255, 51, 94, 143),
                                    width: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 22,
                                  ),
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
            child: const Icon(Icons.fit_screen_sharp),
            backgroundColor: const Color.fromARGB(255, 58, 85, 121),
            elevation: 10,
          ),
  );
}

}
