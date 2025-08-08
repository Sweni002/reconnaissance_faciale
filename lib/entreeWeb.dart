// ignore_for_file: deprecated_member_use_from_same_package, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EntreePageWeb extends StatefulWidget {
  const EntreePageWeb({super.key});

  @override
  State<EntreePageWeb> createState() => _EntreePageWebState();
}

class _EntreePageWebState extends State<EntreePageWeb> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  final String _viewId = 'webcamVideoElement';
  final double boxWidth = 300;
  final double boxHeight = 350;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
        final videoElement = html.VideoElement()
          ..width = boxWidth.toInt()
          ..height = boxHeight.toInt()
          ..autoplay = true
          ..style.objectFit = 'cover'
          ..style.border = 'none';

        html.window.navigator.mediaDevices?.getUserMedia({
          'video': {'facingMode': 'user'} // caméra frontale
        }).then((stream) {
          videoElement.srcObject = stream;
        }).catchError((error) {
          print('Erreur lors de l’accès à la webcam : $error');
        });

        return videoElement;
      });
    }

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Aperçu webcam HTML intégré
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: HtmlElementView(viewType: _viewId),
          ),

          // Cadre vert
          Container(
            width: boxWidth,
            height: boxHeight,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Ligne animée (scanner)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).size.height / 2 - boxHeight / 2 + (_animation.value * (boxHeight - 4)),
                child: Container(
                  width: boxWidth,
                  height: 2,
                  color: Colors.greenAccent,
                ),
              );
            },
          ),

          // Texte d'instruction
          const Positioned(
            bottom: 50,
            child: Text(
              "Veuillez positionner votre visage dans le cadre",
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
