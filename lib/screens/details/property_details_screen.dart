import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/property_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../models/property_model.dart';
import '../../core/constants.dart';
import '../admin/admin_edit_property_screen.dart';
import '../../widgets/network_image_widget.dart';
import '../../widgets/full_screen_image_viewer.dart';


class PropertyDetailsScreen extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  YoutubePlayerController? _youtubeController;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    if (widget.property.youtubeLink != null &&
        widget.property.youtubeLink!.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(
        widget.property.youtubeLink!,
      );
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
        );
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  /// التحقق من كلمة السر لتفعيل وضع الأدمن
  Future<void> _checkAdminAccess() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('دخول الأدمن'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'كلمة المرور',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, controller.text == AppConstants.adminPassword);
            },
            child: const Text('دخول'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _isAdmin = true);
    } else if (confirmed == false && controller.text.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة المرور غير صحيحة'), backgroundColor: Colors.red),
      );
    }
  }

  /// حذف العقار مع تأكيد
  Future<void> _deleteProperty() async {
    // نحفظ المراجع قبل أي await
    final provider = context.read<PropertyProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف عقار "${widget.property.title}"؟\nلا يمكن التراجع عن هذه العملية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await provider.deleteProperty(widget.property.id);
    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('🗑️ تم حذف العقار بنجاح'), backgroundColor: Colors.green),
      );
      nav.pop();
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('❌ فشل حذف العقار'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _launchWhatsApp() async {
    final String message =
        "مرحباً، أنا مهتم بالعقار المسمى: ${widget.property.title} - ${widget.property.id}";
    final Uri url = Uri.parse(
      "https://wa.me/${AppConstants.contactPhone.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}",
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح الواتساب')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PropertyProvider>();
    if (!widget.property.hasTranslation(provider.currentLang) && provider.currentLang != 'ar' && !widget.property.isTranslating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.translateProperty(widget.property);
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // زر الأدمن (يظهر دائماً لكن يطلب كلمة مرور)
          if (!_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white70),
              tooltip: 'وضع الأدمن',
              onPressed: _checkAdminAccess,
            )
          else ...[  
            // أزرار التعديل والحذف (تظهر فقط للأدمن)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primaryGold),
              tooltip: 'تعديل العقار',
              onPressed: () async {
                final nav = Navigator.of(context);
                final edited = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminEditPropertyScreen(property: widget.property),
                  ),
                );
                if (edited == true && mounted) {
                  nav.pop();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'حذف العقار',
              onPressed: _deleteProperty,
            ),
          ],
          Consumer<FavoritesProvider>(
            builder: (context, favorites, _) {
              final isFav = favorites.isFavorite(widget.property.id);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : Colors.white,
                ),
                onPressed: () => favorites.toggleFavorite(widget.property.id),
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  final String lang = context
                      .read<PropertyProvider>()
                      .currentLang;
                  // ignore: deprecated_member_use
                  Share.share(
                    '${widget.property.getTranslatedTitle(lang)}\n${widget.property.getTranslatedDescription(lang)}\nالسعر / Price: ${settings.convertPrice(widget.property.price).toStringAsFixed(0)} ${settings.currencyCode}\n${widget.property.youtubeLink ?? ''}',
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Slider
            if (widget.property.images.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                  height: 350.0,
                  viewportFraction: 1.0,
                  enlargeCenterPage: false,
                  autoPlay: true,
                ),
                items: widget.property.images.map((imgUrl) {
                  return Builder(
                    builder: (BuildContext context) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImageViewer(
                                images: widget.property.images,
                                initialIndex: widget.property.images.indexOf(imgUrl),
                              ),
                            ),
                          );
                        },
                        child: SizedBox(
                          height: 350,
                          width: MediaQuery.of(context).size.width,
                          child: NetworkImageWidget(
                            imageUrl: imgUrl,
                            height: 350,
                            width: MediaQuery.of(context).size.width,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              )
            else
              Container(
                height: 350,
                color: AppColors.greyBackground,
                width: double.infinity,
                child: const Icon(
                  Icons.image_not_supported,
                  size: 100,
                  color: Colors.grey,
                ),
              ),

            // Details section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.property.category,
                          style: const TextStyle(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Consumer<SettingsProvider>(
                        builder: (context, settings, _) {
                          return Text(
                            '${settings.convertPrice(widget.property.price).toStringAsFixed(0)} ${settings.currencyCode}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGold,
                              letterSpacing: 1.1,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.property.getTranslatedTitle(
                      context.read<PropertyProvider>().currentLang,
                    ),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(
                        widget.property.country,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'الوصف',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.property.getTranslatedDescription(
                      context.read<PropertyProvider>().currentLang,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: AppColors.textDark,
                    ),
                  ),

                  // YouTube Video Player if exists
                  if (_youtubeController != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'فيديو العقار',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: YoutubePlayer(
                        controller: _youtubeController!,
                        showVideoProgressIndicator: true,
                        progressColors: const ProgressBarColors(
                          playedColor: AppColors.primaryGold,
                          handleColor: AppColors.primaryGold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 100), // spacing for floating button
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _launchWhatsApp,
        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
        icon: const Icon(Icons.message, color: Colors.white),
        label: const Text(
          'تواصل الآن',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
