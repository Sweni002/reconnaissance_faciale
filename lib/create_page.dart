import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'dio_client.dart';
import 'package:dio/dio.dart';
import 'PasswordSetupPage.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final TextEditingController _pinController = TextEditingController();
  bool isLoading = false;
  bool hasCalledConfirm = false;
  final dioClient = DioClient();
  String? errorMessage;

@override
void initState() {
  super.initState();
  _pinController.addListener(() {
    if (errorMessage != null || hasCalledConfirm) {
      setState(() {
        errorMessage = null;
        hasCalledConfirm = false; // 👈 important
      });
    }

    if (_pinController.text.length == 4 && !isLoading && !hasCalledConfirm) {
      hasCalledConfirm = true;
      _onConfirm();
    }
  });
}


@override
void dispose() {
  _pinController.dispose();
  super.dispose();
}

  void _onKeyboardTap(String value) {
    if (_pinController.text.length < 4) {
      setState(() {
        _pinController.text += value;
      });
    }
  }

  void _onBackspace() {
    if (_pinController.text.isNotEmpty) {
      setState(() {
        _pinController.text = _pinController.text.substring(
          0,
          _pinController.text.length - 1,
        );
      });
    }
  }

  Future<void> _onConfirm() async {
    setState(() {
      isLoading = true;
      hasCalledConfirm = true;
      errorMessage = null; // reset message erreur à chaque validation
    });

    final code = _pinController.text;

    try {
      final response = await dioClient.dio.get(
        '/personnels/matricule/$code',
        options: Options(
          extra: {'withCredentials': true},
          validateStatus: (status) => true,
        ),
      );
      if (response.statusCode == 200) {
      final personnel = response.data[0];
    print(personnel);
        setState(() {
          errorMessage = null;
        });
         Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PasswordPage(personnel: personnel),
    ),
  );

  _pinController.clear();
    setState(() {
    hasCalledConfirm = false;
    errorMessage = null;
  });

        } else if (response.statusCode == 401) {
        print(response.data['error']);
        setState(() {
          errorMessage = response.data['error'] ?? "Erreur inconnue";
        });
      } else if (response.statusCode == 400) {
        print(response.data['error']);
        setState(() {
          errorMessage = response.data['error'] ?? "Erreur inconnue";
        });
      }else {
  setState(() {
    errorMessage = "Erreur HTTP: ${response.statusCode}";
  });
}


    } catch (e) {
     print('Erreur réseau capturée: $e');
     setState(() {
    errorMessage = "Veuillez verifier le connexion";
    hasCalledConfirm = false;
      isLoading = false;       // stop loading ici aussi
 // 👈 aussi ici
  });
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
  
  final bool hasError = errorMessage != null;

final defaultPinTheme = PinTheme(
  width: 45,
  height: 45,
  textStyle: const TextStyle(fontSize: 24, color: Colors.white),
  decoration: BoxDecoration(
    color: Colors.grey[900],
    borderRadius: BorderRadius.circular(10),
    border: Border.all(
      color: hasError
          ? Colors.red
          : const Color.fromARGB(255, 51, 94, 143), // ✅ Bordure par défaut
      width: 2,
    ),
  ),
);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Creation compte',
            style: TextStyle(
              color: const Color.fromARGB(255, 51, 94, 143),
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: 1
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

    Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Flexible(
        child: Text(
          'Merci de saisir le numéro de votre matricule',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  ),
),
        const SizedBox(height: 10),
   Center(
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: 300), // limite la largeur max ici
    child: LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        const spacing = 16.0;
        final pinLength = 4;
        final totalSpacing = spacing * (pinLength - 1);
        final boxWidth = (maxWidth - totalSpacing) / pinLength;

        final pinTheme = PinTheme(
          width: boxWidth.clamp(30, 50), // tu peux baisser encore ici
          height: boxWidth.clamp(30, 50),
          textStyle: TextStyle(fontSize: boxWidth.clamp(18, 24) ,  color: Colors.white,  // <-- Ici
),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: errorMessage != null ? Colors.red : Color.fromARGB(255, 51, 94, 143),
              width: 2,
            ),
          ),
        );

        return Pinput(
          length: pinLength,
          controller: _pinController,
          defaultPinTheme: pinTheme,
          focusedPinTheme: pinTheme,
          readOnly: true,
          separatorBuilder: (index) => SizedBox(width: spacing),
        );
      },
    ),
  ),
),
     if (errorMessage != null)
    Visibility(
  visible: errorMessage != null,
  maintainSize: true,
  maintainAnimation: true,
  maintainState: true,
  child: Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      errorMessage ?? '',
      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
    ),
  ),
),
        const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_pinController.text.length == 4 && !isLoading && errorMessage == null)
                    ? _onConfirm
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 51, 94, 143),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ),

          buildCustomKeyboard(),
        ],
      ),
    );
  }

  Widget buildCustomKeyboard() {
    final List<List<String>> keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['0', '⌫'],
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: keys.map((row) {
          // Dernière ligne : insérer un bouton vide à gauche
          final List<String> displayRow = row.length == 2
              ? ['', ...row] // ['', '0', '⌫']
              : row;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: displayRow.map((key) {
              if (key == '') {
                // Espace vide à gauche du "0"
                return const SizedBox(width: 70, height: 70);
              }

              return Padding(
                padding: const EdgeInsets.all(10),
                child: Material(
                  color: Colors.grey[900],
                  shape: const CircleBorder(),
                  elevation: 3,
                  shadowColor: Colors.black87,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    splashColor: const Color.fromARGB(
                      255,
                      51,
                      94,
                      143,
                    ).withOpacity(0.3),
                    highlightColor: const Color.fromARGB(
                      255,
                      51,
                      94,
                      143,
                    ).withOpacity(0.15),
                    onTap: isLoading
                        ? null
                        : () {
                            if (key == '⌫') {
                              _onBackspace();
                            } else {
                              _onKeyboardTap(key);
                            }
                          },

                    child: SizedBox(
                      width: 70,
                      height: 50,
                      child: Center(
                        child: key == '⌫'
                            ? const Icon(
                                Icons.backspace,
                                color: Colors.white70,
                                size: 26,
                              )
                            : Text(
                                key,
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

}
