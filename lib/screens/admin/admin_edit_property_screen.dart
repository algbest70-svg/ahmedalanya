import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../models/property_model.dart';
import '../../providers/property_provider.dart';
import '../../widgets/network_image_widget.dart';

class AdminEditPropertyScreen extends StatefulWidget {
  final PropertyModel property;

  const AdminEditPropertyScreen({super.key, required this.property});

  @override
  State<AdminEditPropertyScreen> createState() => _AdminEditPropertyScreenState();
}

class _AdminEditPropertyScreenState extends State<AdminEditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _youtubeController;

  late String _selectedCountry;
  late String _selectedCategory;

  // الصور الحالية (روابط موجودة)
  late List<String> _existingImageUrls;
  // صور جديدة سيتم رفعها
  final List<File> _newImageFiles = [];

  bool _isUploading = false;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.property.title);
    final formatter = NumberFormat('#,###');
    _priceController = TextEditingController(text: formatter.format(widget.property.price));
    _descriptionController = TextEditingController(text: widget.property.description);
    _youtubeController = TextEditingController(text: widget.property.youtubeLink ?? '');
    _selectedCountry = widget.property.country;
    _selectedCategory = widget.property.category;
    _existingImageUrls = List<String>.from(widget.property.images);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _newImageFiles.addAll(images.map((x) => File(x.path)));
      });
    }
  }

  Future<String?> _uploadToImgur(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgur.com/3/image'),
      );
      request.headers['Authorization'] = 'Client-ID 546c25a59c58ad7';
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final decodedData = json.decode(responseData);
      if (response.statusCode == 200 && decodedData['success']) {
        return decodedData['data']['link'];
      }
    } catch (e) {
      debugPrint('Imgur Upload Error: $e');
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final propertyProvider = context.read<PropertyProvider>();
    setState(() => _isSubmitting = true);

    // رفع الصور الجديدة إن وجدت
    List<String> newUploadedUrls = [];
    if (_newImageFiles.isNotEmpty) {
      setState(() => _isUploading = true);
      for (var file in _newImageFiles) {
        final url = await _uploadToImgur(file);
        if (url != null) newUploadedUrls.add(url);
      }
      setState(() => _isUploading = false);
    }

    // دمج الصور القديمة + الجديدة
    final allImages = [..._existingImageUrls, ...newUploadedUrls];

    final updatedProperty = PropertyModel(
      id: widget.property.id,
      title: _titleController.text.trim(),
      country: _selectedCountry,
      category: _selectedCategory,
      price: double.tryParse(_priceController.text.replaceAll(',', '')) ?? widget.property.price,
      description: _descriptionController.text.trim(),
      images: allImages,
      youtubeLink: _youtubeController.text.trim().isEmpty
          ? null
          : _youtubeController.text.trim(),
    );

    final success = await propertyProvider.updateProperty(updatedProperty);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم تحديث العقار بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // true = تم التعديل
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ فشل تحديث العقار، حاول مرة أخرى'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل العقار'),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.primaryGold,
      ),
      body: _isSubmitting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primaryGold),
                  const SizedBox(height: 16),
                  Text(
                    _isUploading ? 'جاري رفع الصور...' : 'جاري حفظ التعديلات...',
                    style: const TextStyle(color: AppColors.textDark),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('المعلومات الأساسية'),
                    const SizedBox(height: 16),
                    // ID (للعرض فقط)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'رمز العقار: ${widget.property.id}',
                        style: const TextStyle(color: AppColors.textLight),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_titleController, 'عنوان العقار', ''),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'الدولة',
                            _selectedCountry,
                            AppConstants.countries,
                            (val) => setState(() => _selectedCountry = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            'النوع',
                            _selectedCategory,
                            AppConstants.categories,
                            (val) => setState(() => _selectedCategory = val!),
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(_priceController, 'السعر (بالدولار)', '', isNumber: true),

                    const SizedBox(height: 24),
                    _buildSectionTitle('وصف العقار'),
                    const SizedBox(height: 16),
                    _buildTextField(_descriptionController, 'الوصف الكامل', '', maxLines: 5),

                    const SizedBox(height: 24),
                    _buildSectionTitle('الوسائط'),
                    const SizedBox(height: 16),
                    _buildTextField(_youtubeController, 'رابط فيديو يوتيوب', 'https://youtube.com/...', isRequired: false),

                    const SizedBox(height: 16),
                    _buildSectionTitle('الصور الحالية'),
                    const SizedBox(height: 12),
                    if (_existingImageUrls.isEmpty)
                      const Text('لا توجد صور', style: TextStyle(color: AppColors.textLight))
                    else
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingImageUrls.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: NetworkImageWidget(
                                      imageUrl: _existingImageUrls[index],
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _existingImageUrls.removeAt(index),
                                      ),
                                      child: Container(
                                        color: Colors.red,
                                        padding: const EdgeInsets.all(2),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 20),
                    _buildSectionTitle('إضافة صور جديدة'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.greyBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: AppColors.primaryGold),
                            Text('اضغط لإضافة صور'),
                          ],
                        ),
                      ),
                    ),
                    if (_newImageFiles.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _newImageFiles.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _newImageFiles[index],
                                      height: 80, width: 80, fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 0, right: 0,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _newImageFiles.removeAt(index)),
                                      child: Container(
                                        color: Colors.black54,
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'حفظ التعديلات',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.primaryGold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.primaryGold, width: 4)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.multiline,
        maxLines: maxLines,
        inputFormatters: isNumber ? [ThousandSeparatorInputFormatter()] : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) return 'هذا الحقل مطلوب';
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    // تأكد أن القيمة موجودة في القائمة
    final safeValue = items.contains(value) ? value : items.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: safeValue,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14))))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
