import 'package:drishya_picker/src/editor/editor.dart';
import 'package:drishya_picker/src/editor/src/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const _top = 16.0;

///
class EditorOverlay extends StatelessWidget {
  ///
  const EditorOverlay({
    super.key,
    required this.controller,
  });

  ///
  final DrishyaEditingController controller;

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding.top;
    final top = safePadding == 0 ? _top : 0.0;
    return ValueListenableBuilder<EditorValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              //

              // // Textfield
              // EditorTextfield(controller: controller),

              // Close button
              Positioned(
                left: _top,
                top: top,
                child: EditorCloseButton(controller: controller),
              ),

              // // Background changer
              // Positioned(
              //   left: 16,
              //   bottom: 16,
              //   child: BackgroundSwitcher(controller: controller),
              // ),

              // Screenshot capture button
              Positioned(
                right: _top,
                bottom: _top,
                child: EditorShutterButton(controller: controller),
              ),

              // // Sticker buttons
              // Positioned(
              //   right: 16,
              //   top: controller.value.isStickerPickerOpen ? 0.0 : _top,
              //   child: EditorButtonCollection(controller: controller),
              // ),

              //
            ],
          ),
        );
      },
    );
  }
}
