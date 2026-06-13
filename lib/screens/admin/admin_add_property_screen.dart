import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../models/property_model.dart';
import '../../providers/property_provider.dart';

class AdminAddPropertyScreen extends StatefulWidget {
  const AdminAddPropertyScreen({super.key});

  @override
  State<AdminAddPropertyScreen> createState() => _AdminAddPropertyScreenState();
}

class _AdminAddPropertyScreenState extends State<AdminAddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _youtubeController = TextEditingController();
  String _selectedCountry = AppConstants.countries.first;
  String _selectedCategory = AppConstants.categories.first;

  final List<File> _selectedImagesFiles = [];
  bool _isUploading = false;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // توليد رقم تعريفي تلقائي يعتمد على الوقت لضمان تميزه
    _idController.text = 'AH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImagesFiles.addAll(images.map((x) => File(x.path)));
      });
    }
  }

  /// ضغط الصورة قبل الرفع لتقليص حجمها 10 أضعاف
  Future<File> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg');
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 75,       // جودة 75% - توازن بين الجودة والحجم
        minWidth: 1024,    // عرض أقصى 1024 بيكسل
        minHeight: 1024,   // ارتفاع أقصى 1024 بيكسل
        format: CompressFormat.jpeg,
      );
      if (result != null) {
        final compressed = File(result.path);
        debugPrint('تم ضغط الصورة: ${file.lengthSync()} → ${compressed.lengthSync()} bytes');
        return compressed;
      }
    } catch (e) {
      debugPrint('فشل ضغط الصورة: $e');
    }
    return file; // إرجاع الصورة الأصلية في حال الفشل
  }

  // Purely anonymous upload to Imgur (Zero Cost)
  Future<String?> _uploadToImgur(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgur.com/3/image'),
      );
      // This is a public client ID (might need user to get their own if it fails)
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

    // 1. Upload Images if any
    List<String> finalImageUrls = [];
    if (_selectedImagesFiles.isNotEmpty) {
      setState(() => _isUploading = true);
      for (var file in _selectedImagesFiles) {
        // ضغط الصورة أولاً قبل الرفع
        final compressed = await _compressImage(file);
        final url = await _uploadToImgur(compressed);
        if (url != null) finalImageUrls.add(url);
      }
      setState(() => _isUploading = false);
    }

    if (finalImageUrls.isEmpty && _selectedImagesFiles.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل رفع الصور، يرجى التحقق من الإنترنت')),
        );
      }
      setState(() => _isSubmitting = false);
      return;
    }

    // 2. Create Model
    final property = PropertyModel(
      id: _idController.text.trim(),
      title: _titleController.text.trim(),
      country: _selectedCountry,
      category: _selectedCategory,
      price: double.tryParse(_priceController.text.replaceAll(',', '')) ?? 1.0,
      description: _descriptionController.text.trim(),
      images: finalImageUrls,
      youtubeLink: _youtubeController.text.trim().isEmpty ? null : _youtubeController.text.trim(),
    );

    // 3. Save to GSheets
    final success = await propertyProvider.addProperty(property);

    if (!mounted) return;

    setState(() => _isSubmitting = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نشر العقار بنجاح! 🎉')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء الاتصال بـ Supabase')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة عقار جديد'),
        centerTitle: true,
      ),
      body: _isSubmitting 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.primaryGold),
                const SizedBox(height: 16),
                Text(_isUploading ? 'جاري رفع الصور...' : 'جاري حفظ البيانات في Supabase...'),
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
                  _buildTextField(_idController, 'رمز العقار (ID)', 'سيتم توليده تلقائياً', readOnly: true),
                  _buildTextField(_titleController, 'عنوان العقار', 'مثلاً: فيلا مودرن في ألانيا'),
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
                  _buildTextField(_priceController, 'السعر (بالدولار)', '150000', isNumber: true),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('وصف العقار'),
                  const SizedBox(height: 16),
                  _buildTextField(_descriptionController, 'الوصف الكامل', '', maxLines: 5),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('الوسائط'),
                  const SizedBox(height: 16),
                  _buildTextField(_youtubeController, 'رابط فيديو يوتيوب', 'https://youtube.com/...', isRequired: false),
                  
                  const SizedBox(height: 16),
                  const Text('الصور (من المعرض)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildImagePicker(),
                  
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('نشر العقار الآن'),
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
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.primaryGold, width: 4)),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {bool isNumber = false, int maxLines = 1, bool readOnly = false, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
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

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.greyBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo, color: AppColors.primaryGold, size: 32),
                Text('اضغط لإضافة صور من الاستوديو'),
              ],
            ),
          ),
        ),
        if (_selectedImagesFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImagesFiles.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_selectedImagesFiles[index], height: 80, width: 80, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImagesFiles.removeAt(index)),
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
      ],
    );
  }
}
