import 'package:flutter/material.dart';
import 'dart:async';
import '../core/constants.dart';

class NetworkImageWidget extends StatefulWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;

  const NetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  State<NetworkImageWidget> createState() => _NetworkImageWidgetState();
}

class _NetworkImageWidgetState extends State<NetworkImageWidget> {
  int _currentTierIndex = 0;
  List<String> _tiers = [];
  bool _useFallbackImage = false;
  String _errorMessage = "";
  Timer? _timeoutTimer;


  @override
  void initState() {
    super.initState();
    _initTiers();
    _startTimeout();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    // إذا لم تحمل الصورة خلال 7 ثوانٍ، ننتقل للبروكسي التالي
    _timeoutTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && _errorMessage.isEmpty) {
        debugPrint("Image timeout for tier $_currentTierIndex, switching...");
        _nextTier("Timeout");
      }
    });
  }


  @override
  void didUpdateWidget(covariant NetworkImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _currentTierIndex = 0;
      _useFallbackImage = false;
      _errorMessage = "";
      _initTiers();
    }
  }

  void _initTiers() {
    final rawUrl = widget.imageUrl.trim();
    if (rawUrl.isEmpty || rawUrl == "null") return;

    _tiers = [];
    final cleanUrl = _cleanUrl(rawUrl);
    
    // Tier 1: Photon Proxy (Working 100% for Imgur currently)
    _tiers.add(_buildProxyUrl(cleanUrl, 'photon'));
    
    // Tier 2: Google Proxy (Fallback)
    _tiers.add(_buildProxyUrl(cleanUrl, 'google'));
    
    // Tier 3: Modern Weserv (Fallback)
    _tiers.add(_buildProxyUrl(cleanUrl, 'weserv_modern'));
    
    // Tier 4: Direct Clean Link
    _tiers.add(cleanUrl);
    
    // Tier 5: Original raw URL (Last resort)
    if (rawUrl != cleanUrl && !rawUrl.contains('proxy')) {
      _tiers.add(rawUrl);
    }
  }

  String _cleanUrl(String url) {
    String clean = url.trim();
    if (clean.isEmpty) return clean;

    // Remove any existing proxy prefixes if they somehow got into the DB
    clean = clean.replaceFirst(RegExp(r'^https?:\/\/wsrv\.nl\/\?url='), '');
    clean = clean.replaceFirst(RegExp(r'^https?:\/\/images\.weserv\.nl\/\?url='), '');
    clean = clean.replaceFirst(RegExp(r'^https?:\/\/i0\.wp\.com\/'), 'https://');

    // Robust Imgur ID extraction
    if (clean.contains('imgur.com')) {
      // Matches: imgur.com/abcde, imgur.com/a/abcde, imgur.com/gallery/abcde, i.imgur.com/abcde.jpg
      final regExp = RegExp(r'(?:i\.)?imgur\.com\/(?:gallery\/|a\/|r\/[^\/]+\/|)([a-zA-Z0-9]{5,})(?:\.[a-zA-Z0-9]+)?');
      final match = regExp.firstMatch(clean);
      if (match != null) {
        final id = match.group(1);
        if (id != null) {
          clean = 'https://i.imgur.com/$id.jpg';
        }
      }
      clean = clean.replaceFirst('http://', 'https://');
    }
    
    return clean;
  }

  String _buildProxyUrl(String url, String proxyType) {
    final encodedUrl = Uri.encodeComponent(url);
    if (proxyType == 'google') {
      return "https://images2-focus-opensocial.googleusercontent.com/gadgets/proxy?container=focus&url=$encodedUrl";
    } else if (proxyType == 'weserv_modern') {
      return "https://wsrv.nl/?url=$encodedUrl&w=1000&default=error";
    } else if (proxyType == 'weserv_legacy') {
      return "https://images.weserv.nl/?url=$encodedUrl&w=1000";
    } else if (proxyType == 'photon') {
      final path = url.replaceFirst(RegExp(r'^https?://'), '');
      return "https://i0.wp.com/$path";
    }
    return url;
  }

  void _nextTier(String error) {
    if (mounted) {
      _timeoutTimer?.cancel();
      setState(() {
        if (_currentTierIndex < _tiers.length - 1) {
          _currentTierIndex++;
          _startTimeout(); // إعادة تشغيل المؤقت للبروكسي الجديد
        } else if (!_useFallbackImage) {
          _useFallbackImage = true;
        } else {
          _errorMessage = error;
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_tiers.isEmpty) return _buildError("رابط فارغ");
    if (_errorMessage.isNotEmpty) return _buildError("خطأ في التحميل");

    final currentUrl = _useFallbackImage ? _tiers.last : _tiers[_currentTierIndex];

    return Container(
      height: widget.height,
      width: widget.width,
      color: Colors.grey[100],
      child: Image.network(
        currentUrl,
        height: widget.height,
        width: widget.width,
        fit: widget.fit,
        key: ValueKey("${currentUrl}_$_currentTierIndex"),
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _nextTier(error.toString());
          });
          return _buildLoading();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoading();
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      height: widget.height,
      width: widget.width,
      color: Colors.grey[50],
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryGold,
          ),
        ),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Container(
      height: widget.height,
      width: widget.width,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40),
            const SizedBox(height: 8),
            Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentTierIndex = 0;
                  _useFallbackImage = false;
                  _errorMessage = "";
                  _startTimeout();
                });
              },
              child: const Text("إعادة محاولة"),
            )
          ],
        ),
      ),
    );
  }
}
