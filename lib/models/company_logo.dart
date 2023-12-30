import 'dart:async';
import 'package:flutter/material.dart';

class CompanyLogo {
  final String url;
  final Image image;

  CompanyLogo(this.url) : image = Image.network(url);

  Future<void> preloadImage() async {
    final ImageStream stream = image.image.resolve(ImageConfiguration.empty);
    final Completer<void> completer = Completer<void>();

    ImageStreamListener? listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool syncCall) {
        completer.complete();
        stream.removeListener(listener!); // Remove the listener once the image is loaded
      },
      onError: (dynamic error, StackTrace? stackTrace) {
        completer.completeError(error, stackTrace);
        stream.removeListener(listener!); // Remove the listener if an error occurs
      },
    );

    stream.addListener(listener);
    return completer.future;
  }

}
