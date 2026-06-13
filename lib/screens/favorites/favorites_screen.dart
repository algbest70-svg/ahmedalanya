import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/property_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/property_card.dart';
import '../details/property_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة (Favorites)')),
      body: Consumer2<FavoritesProvider, PropertyProvider>(
        builder: (context, favProvider, propProvider, child) {
          final favoriteProperties = propProvider.properties
              .where((p) => favProvider.isFavorite(p.id))
              .toList();

          if (favoriteProperties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: AppColors.textLight.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد عقارات مفضلة',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: favoriteProperties.length,
            itemBuilder: (context, index) {
              final property = favoriteProperties[index];
              return PropertyCard(
                property: property,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PropertyDetailsScreen(property: property),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
