import 'dart:async';
import 'dart:typed_data';

import 'package:drishya_picker/drishya_picker.dart';
import 'package:drishya_picker/src/gallery/src/repo/gallery_repository.dart';
import 'package:drishya_picker/src/gallery/src/widgets/album_builder.dart';
import 'package:drishya_picker/src/gallery/src/widgets/gallery_builder.dart';
import 'package:drishya_picker/src/gallery/src/widgets/gallery_permission_view.dart';
import 'package:drishya_picker/src/gallery/src/widgets/lazy_load_scroll_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

///
class GalleryGridView extends StatelessWidget {
  ///
  const GalleryGridView({
    super.key,
    required this.controller,
    required this.setting,
    required this.albums,
    required this.onClosePressed,
    required this.onCameraAllowAccess,
  });

  ///
  final GalleryController controller;

  ///
  final GallerySetting setting;

  ///
  final Albums albums;

  ///
  final VoidCallback? onClosePressed;

  ///
  final VoidCallback? onCameraAllowAccess;
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.transparent,
      child: CurrentAlbumBuilder(
        albums: albums,
        builder: (context, album, child) {
          return ValueListenableBuilder<AlbumValue>(
            valueListenable: album,
            builder: (context, value, child) {
              // Error
              if (value.state == BaseState.unauthorised &&
                  value.entities.isEmpty) {
                return GalleryPermissionView(
                  setting: setting,
                  onRefresh: () {
                    if (value.assetPathEntity == null) {
                      albums.fetchAlbums(controller.setting.requestType);
                    } else {
                      album.fetchAssets();
                    }
                  },
                );
              }

              // // No data
              // if (value.state == BaseState.completed &&
              //     value.entities.isEmpty) {
              //   return Center(
              //     child: Text(
              //       controller.setting.noPhotoMsg,
              //       style: const TextStyle(
              //         color: Colors.white,
              //         fontWeight: FontWeight.w700,
              //       ),
              //     ),
              //   );
              // }

              if (value.state == BaseState.error) {
                return const Center(
                  child: Text(
                    'Something went wrong. Please try again!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              final entities = value.entities;
              final enableCamera = controller.setting.enableCamera;

              final itemCount = albums.value.state == BaseState.fetching
                  ? 20
                  : enableCamera
                      ? entities.length + 1
                      : entities.length;

              return LazyLoadScrollView(
                onEndOfPage: album.fetchAssets,
                scrollOffset: MediaQuery.of(context).size.height * 0.4,
                child: GridView.builder(
                  controller: controller.panelController.scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: controller.setting.crossAxisCount ?? 3,
                    crossAxisSpacing: 1.5,
                    mainAxisSpacing: 1.5,
                  ),
                  itemCount: itemCount,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    if (enableCamera && index == 0) {
                      return InkWell(
                        onTap: () async {
                          final beforeStatus = await Permission.camera.status;
                          final status = await Permission.camera.request();
                          if (status.isGranted) {
                            unawaited(
                              // ignore: use_build_context_synchronously
                              controller.openCamera(context).then((value) {
                                if (value != null) {
                                  album.insert(value);
                                }
                              }),
                            );
                          } else if (beforeStatus == status) {
                            onCameraAllowAccess?.call();
                          }
                        },
                        child: const Icon(
                          CupertinoIcons.camera,
                          size: 26,
                          color: Colors.black,
                        ),
                      );
                    }

                    final ind = enableCamera ? index - 1 : index;

                    final entity = albums.value.state == BaseState.fetching
                        ? null
                        : entities[ind];

                    if (entity == null) return const SizedBox();

                    return _MediaTile(controller: controller, entity: entity);
                  },
                ),
              );
            },
          );

          //
        },
      ),
    );
  }
}

///
class _MediaTile extends StatelessWidget {
  ///
  const _MediaTile({
    required this.entity,
    required this.controller,
  });

  ///
  final GalleryController controller;

  ///
  final AssetEntity entity;

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;

    final drishya = entity.toDrishya;

    return ColoredBox(
      color: Colors.grey.shade800,
      child: InkWell(
        onTap: () {
          final entity = drishya.copyWith(pickedThumbData: bytes);
          controller.select(context, entity);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            EntityThumbnail(
              entity: drishya,
              onBytesGenerated: (b) {
                bytes = b;
              },
            ),
            _SelectionCount(controller: controller, entity: entity),
          ],
        ),
      ),
    );
  }
}

class _SelectionCount extends StatelessWidget {
  const _SelectionCount({
    required this.controller,
    required this.entity,
  });

  final GalleryController controller;
  final AssetEntity entity;

  @override
  Widget build(BuildContext context) {
    return GalleryBuilder(
      controller: controller,
      builder: (value, child) {
        final actionBased =
            controller.setting.selectionMode == SelectionMode.actionBased;

        final singleSelection = actionBased
            ? !value.enableMultiSelection
            : controller.singleSelection;

        final isSelected = value.selectedEntities.contains(entity);
        final index = value.selectedEntities.indexOf(entity.toDrishya);

        Widget counter = const SizedBox();

        if (isSelected) {
          counter = CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.85),
            radius: 14,
            child: controller.singleSelection
                ? Icon(
                    CupertinoIcons.checkmark_alt,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
          );
        }

        if (actionBased && !singleSelection) {
          counter = Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: isSelected ? counter : const SizedBox(),
          );
        }

        return Container(
          color: isSelected ? Colors.white38 : Colors.transparent,
          padding: const EdgeInsets.all(6),
          child: Align(
            alignment: actionBased ? Alignment.topRight : Alignment.center,
            child: counter,
          ),
        );
      },
    );
  }
}
