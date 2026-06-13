import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../providers/property_provider.dart';
import '../../widgets/property_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../details/property_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  int _selectedCategoryIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AppConstants.countries.length,
      vsync: this,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _updateFilters();
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        Provider.of<PropertyProvider>(context, listen: false).fetchProperties();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFilters();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateFilters() {
    final provider = Provider.of<PropertyProvider>(context, listen: false);
    provider.setFilter(
      country: AppConstants.countries[_tabController.index],
      category: _selectedCategoryIndex >= 0
          ? AppConstants.categories[_selectedCategoryIndex]
          : '',
    );
  }

  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse(
      "https://wa.me/${AppConstants.contactPhone.replaceAll('+', '').replaceAll(' ', '')}",
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
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _launchWhatsApp,
        backgroundColor: const Color(0xFF25D366),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.real_estate_agent, color: AppColors.primaryGold),
            ),
            const SizedBox(width: 8),
            Text(
              'Ahmed Alanya',
              style: TextStyle(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<PropertyProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: provider.currentLang,
                    icon: const Icon(
                      Icons.language,
                      color: AppColors.primaryGold,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        provider.setLanguage(newValue);
                      }
                    },
                    items: AppConstants.languages.entries
                        .map<DropdownMenuItem<String>>((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGold,
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGold,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.primaryGold,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            fontSize: 14,
          ),
          tabs: AppConstants.countries.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBarWidget(
              onChanged: (val) {
                Provider.of<PropertyProvider>(
                  context,
                  listen: false,
                ).setSearchQuery(val);
              },
            ),
          ),

          // Categories
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: AppConstants.categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: ChoiceChip(
                    label: Text(AppConstants.categories[index]),
                    selected: isSelected,
                    selectedColor: AppColors.primaryBlue, // Dark blue for selected
                    checkmarkColor: AppColors.primaryGold,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryGold : Colors.black12,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primaryGold : AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryIndex = selected ? index : -1;
                      });
                      _updateFilters();
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          


          // Properties List
          Expanded(
            child: Consumer<PropertyProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGold,
                    ),
                  );
                }

                if (provider.properties.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.textLight.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد عقارات مطابقة للبحث',
                          style: TextStyle(color: AppColors.textLight),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.properties.length + (provider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.properties.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primaryGold),
                        ),
                      );
                    }
                    final property = provider.properties[index];
                    return PropertyCard(
                      property: property,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PropertyDetailsScreen(property: property),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}
