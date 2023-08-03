import 'package:drishya_picker/drishya_picker.dart';
import 'package:flutter/material.dart';

///
class GalleryPermissionView extends StatefulWidget {
  ///
  const GalleryPermissionView({
    super.key,
    this.onRefresh,
    this.isCamera = false,
    this.setting,
  });

  ///
  final VoidCallback? onRefresh;

  ///
  final bool isCamera;

  ///
  final GallerySetting? setting;

  @override
  State<GalleryPermissionView> createState() => _GalleryPermissionViewState();
}

class _GalleryPermissionViewState extends State<GalleryPermissionView>
    with WidgetsBindingObserver {
  var _setting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _setting) {
      widget.onRefresh?.call();
      _setting = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setting = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      margin:
          widget.isCamera ? const EdgeInsets.symmetric(horizontal: 32) : null,
      decoration: BoxDecoration(
        borderRadius: widget.isCamera ? BorderRadius.circular(12) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Description
          Text(
            (widget.isCamera
                    ? widget.setting?.cameraPermissionRequestMsg
                    : widget.setting?.photoPermissionRequestMsg) ??
                '''Allow app to access your ${widget.isCamera ? 'camera' : 'album for picking media'} .''',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Allow access button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isCamera)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: OutlinedButton(
                    onPressed: Navigator.of(context).pop,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.secondary,
                      visualDensity: VisualDensity.comfortable,
                    ),
                    child: const Text('Deny Access'),
                  ),
                ),
              OutlinedButton(
                onPressed: () {
                  PhotoManager.openSetting();
                  _setting = true;
                },
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.comfortable,
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                ),
                child: Text(widget.setting?.allowAccessText ?? 'Allow Access'),
              ),
            ],
          ),

          //
        ],
      ),
    );
  }
}
