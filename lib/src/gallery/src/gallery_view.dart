import 'dart:async';

import 'package:drishya_picker/drishya_picker.dart';
import 'package:drishya_picker/src/animations/animations.dart';
import 'package:drishya_picker/src/camera/src/widgets/ui_handler.dart';
import 'package:drishya_picker/src/gallery/src/repo/gallery_repository.dart';
import 'package:drishya_picker/src/gallery/src/widgets/albums_page.dart';
import 'package:drishya_picker/src/gallery/src/widgets/gallery_asset_selector.dart';
import 'package:drishya_picker/src/gallery/src/widgets/gallery_grid_view.dart';
import 'package:drishya_picker/src/gallery/src/widgets/send_button.dart';
import 'package:drishya_picker/src/gallery/src/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///
///
class GalleryView extends StatefulWidget {
  ///
  const GalleryView({
    super.key,
    this.controller,
    this.setting,
    this.onCameraAllowAccess,
  });

  /// Gallery controller
  final GalleryController? controller;

  /// Gallery setting
  final GallerySetting? setting;

  ///
  final VoidCallback? onCameraAllowAccess;

  ///
  static const String name = 'GalleryView';

  ///
  /// Pick media
  static Future<List<DrishyaEntity>?> pick(
    BuildContext context, {
    /// Gallery controller
    GalleryController? controller,

    /// Gallery setting
    GallerySetting? setting,

    /// Route setting
    CustomRouteSetting? routeSetting,

    ///
    VoidCallback? onCameraAllowAccess,
  }) {
    return Navigator.of(context).push<List<DrishyaEntity>>(
      SlideTransitionPageRoute(
        builder: GalleryView(
          controller: controller,
          setting: setting,
          onCameraAllowAccess: onCameraAllowAccess,
        ),
        setting: routeSetting ??
            const CustomRouteSetting(
              settings: RouteSettings(name: name),
            ),
      ),
    );
  }

  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> {
  late final GalleryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? GalleryController();
  }

  @override
  void dispose() {
    if (widget.controller == null || _controller.autoDispose) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If [SlidableGallery] is used no need to build panel setting again
    if (!_controller.fullScreenMode) {
      return _View(
        onCameraAllowAccess: widget.onCameraAllowAccess,
        controller: _controller,
        setting: widget.setting!,
      );
    }

    // Full screen mode
    return PanelSettingBuilder(
      setting: widget.setting?.panelSetting,
      builder: (panelSetting) => _View(
        onCameraAllowAccess: widget.onCameraAllowAccess,
        controller: _controller,
        setting: (widget.setting ?? _controller.setting)
            .copyWith(panelSetting: panelSetting),
      ),
    );

    //
  }
}

///
class _View extends StatefulWidget {
  ///
  const _View({
    required this.controller,
    required this.setting,
    required this.onCameraAllowAccess,
  });

  final GalleryController controller;
  final GallerySetting setting;

  ///
  final VoidCallback? onCameraAllowAccess;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> with SingleTickerProviderStateMixin {
  late final GalleryController _controller;
  late final PanelController _panelController;

  late final AnimationController _animationController;
  late final Animation<double> _animation;
  late final Albums _albums;

  double albumHeight = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller..init(setting: widget.setting);
    _albums = Albums()..fetchAlbums(_controller.setting.requestType);

    _panelController = _controller.panelController;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      reverseDuration: const Duration(milliseconds: 300),
      value: 0,
    );

    // ignore: prefer_int_literals
    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastLinearToSlowEaseIn,
        reverseCurve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _albums.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleAlbumList(bool isVisible) {
    if (_animationController.isAnimating) return;
    _controller.setAlbumVisibility(visible: !isVisible);
    _panelController.isGestureEnabled = _animationController.value == 1.0;
    if (_animationController.value == 1.0) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  //
  void showAlert() {
    final cancel = TextButton(
      onPressed: Navigator.of(context, rootNavigator: true)
          .pop, //fix vấn đề pop dialog
      child: Text(
        widget.setting.cancelLabel ?? 'CANCEL',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
      ),
    );
    final unselectItems = TextButton(
      onPressed: () => _onSelectionClear(context),
      child: Text(
        widget.setting.unselectItemsLabel ?? 'UNSELECT ITEMS',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );

    final alertDialog = AlertDialog(
      title: Text(
        widget.setting.confirmUnselectTitle ?? 'Unselect these items?',
        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              color: Colors.white70,
            ),
      ),
      content: Text(
        widget.setting.confirmUnselectMsg ??
            'Going back will undo the selections you made.',
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Colors.grey.shade600,
            ),
      ),
      actions: [cancel, unselectItems],
      backgroundColor: Colors.grey.shade900,
      titlePadding: const EdgeInsets.all(16),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 2,
      ),
    );

    showDialog<void>(
      context: context,
      builder: (context) => alertDialog,
    );
  }

  Future<bool> _onClosePressed() async {
    if (_animationController.isAnimating) return false;

    if (_controller.albumVisibility.value) {
      _toggleAlbumList(true);
      return false;
    }

    // if (_controller.value.selectedEntities.isNotEmpty) {
    //   _showAlert();
    //   return false;
    // }

    if (_controller.fullScreenMode) {
      UIHandler.of(context).pop(widget.setting.backupEntities);
      return true;
    }

    if (_panelController.isVisible) {
      if (_panelController.value.state == PanelState.max) {
        _panelController.minimizePanel();
      } else {
        _panelController.closePanel();
      }
      return false;
    }

    return true;
  }

  void _onSelectionClear(BuildContext context) {
    _controller.clearSelection();
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _onAlbumChange(Album album) {
    if (_animationController.isAnimating) return;
    _albums.changeAlbum(album);
    _toggleAlbumList(true);
  }

  @override
  Widget build(BuildContext context) {
    final panelSetting = widget.setting.panelSetting!;
    final actionMode =
        _controller.setting.selectionMode == SelectionMode.actionBased;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: panelSetting.overlayStyle,
      child: WillPopScope(
        onWillPop: _onClosePressed,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.setting.albumTitle),
            leading: const CloseButton(),
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Body
              Column(
                children: [
                  // Gallery grid
                  Expanded(
                    child: GalleryGridView(
                      setting: widget.setting,
                      controller: _controller,
                      albums: _albums,
                      onClosePressed: _onClosePressed,
                      onCameraAllowAccess: widget.onCameraAllowAccess,
                    ),
                  ),
                ],
              ),

              // Send and edit button
              if (!actionMode)
                GalleryAssetSelector(
                  controller: _controller,
                  albums: _albums,
                ),

              // Send button
              if (actionMode)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: SendButton(controller: _controller),
                ),

              // Album list
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final offsetY = panelSetting.headerMaxHeight +
                      (panelSetting.maxHeight! - panelSetting.headerMaxHeight) *
                          (1 - _animation.value);
                  return Visibility(
                    visible: _animation.value > 0.0,
                    child: Transform.translate(
                      offset: Offset(0, offsetY),
                      child: child,
                    ),
                  );
                },
                child: AlbumsPage(
                  setting: widget.setting,
                  albums: _albums,
                  controller: _controller,
                  onAlbumChange: _onAlbumChange,
                ),
              ),

              //
            ],
          ),
        ),
      ),
    );

    //
  }
}
