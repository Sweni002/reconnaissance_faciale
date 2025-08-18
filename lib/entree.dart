import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dio_client.dart';
import 'package:lottie/lottie.dart';

class EntreePage extends StatefulWidget {
  const EntreePage({super.key});

  @override
  State<EntreePage> createState() => _EntreePageState();
}

class _EntreePageState extends State<EntreePage>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool isCameraInitialized = false;
  late FaceDetector _faceDetector;
  final double boxSize = 300.0;
  bool _isProcessing = false;
  DateTime? _lastDetectionTime;
  final Duration detectionCooldown = Duration(seconds: 5);
  final dio = DioClient().dio;
  String _status = 'idle'; // idle, loading, success, error
  Map<String, dynamic>? _personnel;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();

    // ✅ Initialiser le détecteur de visages
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
      ),
    );
     // ✅ Initialiser la caméra
    _initCamera();

    // ✅ Animation de la ligne verte
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  Widget _buildLottieAnimation() {
    switch (_status) {
      case 'loading':
        return Center(
          child: Lottie.asset('assets/loading.json', width: 150, height: 150),
        );
      case 'success':
        return Center(
          child: Lottie.asset('assets/succes.json', width: 150, height: 150),
        );
      case 'error':
        return Center(
          child: Lottie.asset('assets/error.json', width: 150, height: 150),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      InputImage inputImage;

      try {
        inputImage = _convertCameraImage(
          image,
          _cameraController!.description.sensorOrientation,
        );
      } catch (e) {
        await _showErrorDialog(context, e.toString());
        _isProcessing = false;
        return;
      }

      List<Face> faces;

      try {
        faces = await _faceDetector.processImage(inputImage);
      } catch (e) {
        await _showErrorDialog(context, e.toString());
        _isProcessing = false;
        return;
      }

      if (faces.isNotEmpty) {
        if (_status == 'loading') {
          _isProcessing = false;
          return;
        }
        final now = DateTime.now();
        if (_lastDetectionTime == null ||
            now.difference(_lastDetectionTime!) > detectionCooldown) {
          _lastDetectionTime = now;
          await _captureAndSendPhoto(context);
        }
      }
    } catch (e) {
      await _showErrorDialog(context, e.toString());
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _showDebugDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  InputImage _convertCameraImage(CameraImage image, int rotation) {
    return convertCameraImageToInputImage(image, rotation);
  }

  InputImage convertCameraImageToInputImage(CameraImage image, int rotation) {
    final int width = image.width;
    final int height = image.height;

    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    // Buffer NV21 = Y + interleaved VU
    final nv21 = Uint8List(width * height + 2 * (width ~/ 2) * (height ~/ 2));

    // Copie du plan Y
    int index = 0;
    for (int i = 0; i < height; i++) {
      final start = i * image.planes[0].bytesPerRow;
      nv21.setRange(index, index + width, image.planes[0].bytes, start);
      index += width;
    }

    // Copie des plans U et V en format VU intercalé
    for (int i = 0; i < height ~/ 2; i++) {
      for (int j = 0; j < width ~/ 2; j++) {
        final uvIndex = i * uvRowStride + j * uvPixelStride;
        nv21[index++] = image.planes[2].bytes[uvIndex]; // V
        nv21[index++] = image.planes[1].bytes[uvIndex]; // U
      }
    }

    final inputImageFormat = InputImageFormat.nv21;

    final metadata = InputImageMetadata(
      size: Size(width.toDouble(), height.toDouble()),
      rotation:
          InputImageRotationValue.fromRawValue(rotation) ??
          InputImageRotation.rotation0deg,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: nv21, metadata: metadata);
  }

  Future<void> _captureAndSendPhoto(BuildContext context) async {
    if (_isCapturing) return; // Bloque les captures multiples

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _isCapturing = true;

    setState(() {
      _status = 'loading';
    });

    try {
      await _cameraController!.stopImageStream();
      final XFile imageFile = await _cameraController!.takePicture();
      await envoyerImagePourReconnaissance(imageFile, context);
      await _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint("Erreur capture et envoi : $e");
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
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() => isCameraInitialized = true);

      await _cameraController!.startImageStream(_processCameraImage);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        print("📸 Caméra démarrée");
      });
    } catch (e) {
      debugPrint("❌ Erreur d'initialisation caméra : $e");
    }
  }

  Future<void> _disposeCamera() async {
    if (_cameraController != null) {
      try {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        await _cameraController!.dispose();
        print("✅ Caméra libérée");
      } catch (e) {
        debugPrint("Erreur lors de l'arrêt caméra : $e");
      }
    }
  }

  Future<void> envoyerImagePourReconnaissance(
    XFile imageFile,
    BuildContext context,
  ) async {
    try {
      final fileName = imageFile.name;

      final formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await dio.post(
        '/pointage/facial_client',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200) {
       String matricule = response.data['personnel']['matricule'];
  String mdp = response.data['client']?['mdp_hash'] ?? "";
  bool hasClient = response.data['has_client'] ?? false;

     setState(() {
          _status = 'success'; // affiche animation succès
        });
        await _showSuccesDialog(context, response.data['message']);

      if (hasClient) {
    // 🔹 Si le compte client existe → login direct
    _login(matricule, mdp);
  } else {
    // 🔹 Sinon → redirection vers /
   Navigator.of(context).pop(); // revient à la page précédente
  }
      } else if (response.statusCode == 400) {
        setState(() {
          _status = 'error'; // affiche animation erreur
        });

        await _showErrorDialog(context, response.data['error']);
       Navigator.of(context).pop(); // revient à la page précédente
 } else {
        setState(() {
          _status = 'error'; // affiche animation erreur
        });

        await _showErrorDialog(context, 'Code: ${response.statusCode}');
       Navigator.of(context).pop(); // revient à la page précédente
    }
    } on DioError catch (dioError) {
      setState(() {
        _status = 'error'; // affiche animation erreur
      });

      String errorMsg = dioError.response != null
          ? "${dioError.response?.data['error']}"
          : "Erreur de connexion ou timeout : Veuillez vérifier la connexion";

      await _showErrorDialog(context, errorMsg);
    Navigator.of(context).pop(); 
    } catch (e) {
      setState(() {
        _status = 'error'; 
      });

      await _showErrorDialog(context, e.toString());
    Navigator.of(context).pop(); 
    }
  }

  Future<void> _showErrorDialog(BuildContext context, String message) async {
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
                child: Lottie.asset('assets/error.json', repeat: false),
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
        _showErrorDialog(context, response.data['error']);
      Navigator.of(context).pop(); // revient à la page précédente
    }
    } catch (e) {
      _showErrorDialog(context, e.toString());
     Navigator.of(context).pop(); // revient à la page précédente
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Bloque le retour Android ou iOS quand on est en loading
        if (_status == 'loading') return false;
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              if (_status != 'loading') {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ),
        backgroundColor: Colors.black,
        body: isCameraInitialized
            ? (_status == 'loading'
                  ? Container(
                      color: Colors.black,
                      child: Center(
                        child: Lottie.asset(
                          'assets/loading.json',
                          width: 300,
                          height: 300,
                          repeat: true,
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: CameraPreview(_cameraController!),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: CameraDarkOverlay(
                              holeSize: Size(boxSize, boxSize),
                            ),
                          ),
                        ),
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
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Positioned(
                              top:
                                  MediaQuery.of(context).size.height / 2 -
                                  boxSize / 2 +
                                  (_animation.value * (boxSize - 4)),
                              left:
                                  MediaQuery.of(context).size.width / 2 -
                                  boxSize / 2,
                              child: Container(
                                width: boxSize,
                                height: 2,
                                color: Colors.greenAccent,
                              ),
                            );
                          },
                        ),
                        const Positioned(
                          bottom: 40,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Text(
                              "Veuillez positionner votre visage dans le cadre",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        // --- Animation succès ---
                        if (_status == 'success') ...[
                          Positioned.fill(
                            child: Container(color: Colors.black54),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Lottie.asset(
                                'assets/succes.json',
                                width: 250,
                                height: 250,
                                repeat: false,
                                onLoaded: (composition) {
                                  Future.delayed(composition.duration, () {
                                    if (mounted && _personnel != null) {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/pointage',
                                        arguments: _personnel,
                                      );
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        ],

                        // --- Animation erreur ---
                        if (_status == 'error') ...[
                          Positioned.fill(
                            child: Container(color: Colors.black54),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Lottie.asset(
                                'assets/error.json',
                                width: 150,
                                height: 150,
                                repeat: false,
                                onLoaded: (composition) {
                                  Future.delayed(composition.duration, () {
                                    if (mounted) {
                                      setState(() {
                                        _status = 'idle';
                                      });
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ))
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}


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

// Coins colorés
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
