import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/models/company_logo.dart';

class TransitionOverlay extends StatefulWidget {
  final IconData iconData;
  final Duration duration;
  final String pageName;

  const TransitionOverlay({
    super.key,
    required this.iconData,
    required this.pageName,
    this.duration = const Duration(seconds: 3),
  });

  @override
  _TransitionOverlayState createState() => _TransitionOverlayState();
}

class _TransitionOverlayState extends State<TransitionOverlay> with SingleTickerProviderStateMixin {
  late double progress;
  Timer? _timer;
  Timer? _blinkTimer;
  String loadingText = "Now Loading";
  int dotCount = 0;
  bool _isCompleted = false; // New state variable
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    progress = 0.0;
    _startLoading();
    _startBlinkingDots();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _opacityAnimation = Tween(begin: 1.0, end: 0.0).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // Handle completion of fade out, perhaps navigate or dispose
        }
      });
  }

  void _startLoading() {
    const timerInterval = Duration(milliseconds: 10);
    final totalTicks = (widget.duration.inMilliseconds / timerInterval.inMilliseconds).ceil();
    int tickCount = 0;

    _timer = Timer.periodic(timerInterval, (Timer timer) {
      tickCount++;
      setState(() {
        progress = min(1.0, tickCount / totalTicks);
      });

      if(progress >= 0.85) {
        _controller.forward();
        setState(() {
          progress = 1.0;
        });
      }

      if (progress == 1.0 && !_isCompleted) { // Check if progress is complete
        _isCompleted = true;
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  void _startBlinkingDots() {
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (Timer timer) {
      if (mounted) {
        setState(() {
          dotCount = (dotCount + 1) % 4;
          loadingText = "Now Loading${"." * dotCount}";
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blinkTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    CompanyLogo companyLogo = Provider.of<CompanyLogo>(context, listen: false);
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: Colors.green,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Spacer(),
              SizedBox(
                  width: 250,
                  height: 250,
                  child: companyLogo.image, // Use the provided CompanyLogo's image
                ),
              const SizedBox(height: 50),
              Icon(
                widget.iconData,
                size: 50.0,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                widget.pageName,  // Display the pageName here
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 150),
              Text(
                loadingText,  // Display the dynamic loading text here
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 5,
                  width: 200,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.greenAccent,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 5,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
