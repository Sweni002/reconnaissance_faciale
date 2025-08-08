import 'dart:typed_data';
// Ajoute ceci pour WriteBuffer
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';
import 'dio_client.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class EntreePage extends StatefulWidget {
  const EntreePage({super.key});

  @override
  State<EntreePage> createState() => _EntreePageState();
}

class _EntreePageState extends State<EntreePage>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool isCameraInitialized = false;
  bool isDetecting = false; // Utilise bien cette variable d'instance

  final double boxSize = 300.0;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableClassification: false,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
    _initCamera();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  Future<void> captureAndSendImage(XFile file) async {
    try {
      String filename = path.basename(file.path);
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path, filename: filename),
      });

      final response = await DioClient().dio.post(
        '/facial_client',
        data: formData,
      );

      String message;
      if (response.statusCode == 200) {
        message = response.data['message'];
      } else {
        message = response.data['error'];
        
      }

      // Affiche le dialog avec le message
      if (!mounted) return; // Vérifie que le widget est encore monté
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Résultat'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Erreur capture ou envoi image: $e');

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erreur'),
          content: Text('Erreur lors de l\'envoi de l\'image : $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        isCameraInitialized = true;
      });

      // Variable d'instance isDetecting est déjà déclarée, on ne redéclare pas ici

      await _cameraController!.startImageStream((CameraImage image) async {
        if (isDetecting) return;
        isDetecting = true;

        try {
          final inputImage = _convertCameraImage(
            image,
            _cameraController!.description.sensorOrientation,
          );

          final faces = await _faceDetector.processImage(inputImage);

          if (faces.isNotEmpty) {
            print("Visage détecté !");

            await _cameraController?.stopImageStream();

            final XFile picture = await _cameraController!.takePicture();

            await captureAndSendImage(picture);

            // Optionnel: redémarrer le stream
            // await _cameraController?.startImageStream(...);
          }
        } catch (e) {
          debugPrint("Erreur détection visage : $e");
        } finally {
          isDetecting = false;
        }
      });
    } catch (e) {
      debugPrint("Erreur d'initialisation caméra : $e");
    }
  }

  InputImage _convertCameraImage(CameraImage image, int rotation) {
    final builder = BytesBuilder();
    for (final plane in image.planes) {
      builder.add(plane.bytes);
    }
    final bytes = builder.toBytes();

    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final imageRotation =
        InputImageRotationValue.fromRawValue(rotation) ??
        InputImageRotation.rotation0deg;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    final inputImageMetadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _faceDetector.close();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: Colors.white),
        ),
      ),
      backgroundColor: Colors.black,
      body: isCameraInitialized
          ? Stack(
              children: [
                // 📸 Caméra plein écran
                Positioned.fill(child: CameraPreview(_cameraController!)),

                // 🔲 Overlay noir transparent avec trou
                Positioned.fill(
                  child: CustomPaint(
                    painter: CameraDarkOverlay(
                      holeSize: Size(boxSize, boxSize),
                    ),
                  ),
                ),

                // 🟥 Cadre de scan centré avec coins colorés
                Center(
                  child: SizedBox(
                    width: boxSize,
                    height: boxSize,
                    child: Stack(
                      children: const [
                        Positioned(
                          top: 0,
                          left: 0,
                          child: CustomPaint(
                            size: Size(40, 40),
                            painter: CornerPainter(
                              color: Colors.blue,
                              top: true,
                              left: true,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: CustomPaint(
                            size: Size(40, 40),
                            painter: CornerPainter(
                              color: Colors.amber,
                              top: true,
                              right: true,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: CustomPaint(
                            size: Size(40, 40),
                            painter: CornerPainter(
                              color: Colors.green,
                              bottom: true,
                              left: true,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CustomPaint(
                            size: Size(40, 40),
                            painter: CornerPainter(
                              color: Colors.red,
                              bottom: true,
                              right: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 🟢 Ligne animée
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Positioned(
                      top:
                          MediaQuery.of(context).size.height / 2 -
                          boxSize / 2 +
                          (_animation.value * (boxSize - 4)),
                      left: MediaQuery.of(context).size.width / 2 - boxSize / 2,
                      child: Container(
                        width: boxSize,
                        height: 2,
                        color: Colors.greenAccent,
                      ),
                    );
                  },
                ),

                // 📩 Texte instruction
                const Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "Veuillez positionner votre visage dans le cadre",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

// 🎨 Overlay sombre avec trou central transparent
class CameraDarkOverlay extends CustomPainter {
  final Size holeSize;

  CameraDarkOverlay({required this.holeSize});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()
      ..addRect(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: holeSize.width,
          height: holeSize.height,
        ),
      );

    final overlayPath = Path.combine(
      PathOperation.difference,
      fullPath,
      holePath,
    );

    canvas.drawPath(overlayPath, backgroundPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// 🎨 Paint pour coins colorés
class CornerPainter extends CustomPainter {
  final Color color;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const CornerPainter({
    required this.color,
    this.top = false,
    this.bottom = false,
    this.left = false,
    this.right = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (top && left) {
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.lineTo(0, size.height);
    } else if (top && right) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (bottom && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else if (bottom && right) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
