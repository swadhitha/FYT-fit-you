<<<<<<< HEAD
// ...existing code...
import 'package:flutter/material.dart';
import 'package:my_flutter_app/routing/app_router.dart';
import 'package:my_flutter_app/design/app_spacing.dart';
=======
import 'package:flutter/material.dart';
import 'package:my_flutter_app/routing/app_router.dart';
>>>>>>> feature/body-metric-module-clean

class BodyScanScreen extends StatelessWidget {
  const BodyScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    // Placeholder for camera preview & MediaPipe overlay.
=======
    // Camera/pose integration can replace this placeholder while preserving flow.
>>>>>>> feature/body-metric-module-clean
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
<<<<<<< HEAD
        leading: BackButton(color: Colors.white),
=======
        leading: const BackButton(color: Colors.white),
>>>>>>> feature/body-metric-module-clean
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.black,
                alignment: Alignment.center,
<<<<<<< HEAD
                child: Container(
                  width: 200,
                  height: 360,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white70,
                      size: 96,
                    ),
                  ),
=======
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 360,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white70,
                          size: 96,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Align your full body in frame',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
>>>>>>> feature/body-metric-module-clean
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
<<<<<<< HEAD
                padding: const EdgeInsets.only(bottom: 32.0),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.bodyAnalysis,
=======
                padding: const EdgeInsets.only(bottom: 32),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.bodyMeasurement,
>>>>>>> feature/body-metric-module-clean
                  ),
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
<<<<<<< HEAD
// ...existing code...
=======
>>>>>>> feature/body-metric-module-clean
