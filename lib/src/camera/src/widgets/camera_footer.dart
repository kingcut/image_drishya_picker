// ignore_for_file: always_use_package_imports

import 'package:drishya_picker/src/camera/src/widgets/camera_shutter_button.dart';
import 'package:flutter/material.dart';

import '../controllers/cam_controller.dart';
import 'camera_builder.dart';
import 'camera_rotate_button.dart';

///
class CameraFooter extends StatelessWidget {
  ///
  const CameraFooter({
    super.key,
    required this.controller,
  });

  ///
  final CamController controller;

  @override
  Widget build(BuildContext context) {
    return CameraBuilder(
      controller: controller,
      builder: (value, child) {
        if (value.hideCameraFooter) {
          return const SizedBox();
        }
        return child!;
      },
      child: Container(
        height: 60,
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // // Gallery preview
              // CameraGalleryButton(controller: controller),

              // // Margin
              // const SizedBox(width: 8),

              // Camera type scroll
              // Expanded(child: CameraTypeChanger(controller: controller)),
              Center(child: CameraShutterButton(controller: controller)),

              // Switch camera
              Align(
                alignment: Alignment.centerRight,
                child: CameraRotateButton(controller: controller),
              ),

              //
            ],
          ),
        ),
      ),
    );
  }
}
