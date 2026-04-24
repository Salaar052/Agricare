// ============================================
// FILE 8: lib/widgets/marketplace/shop_image_picker.dart
// Shop image picker widget with app theme
// ============================================

import 'package:flutter/material.dart';

class ShopImagePicker extends StatelessWidget {
  final Function(String) onImageSelected;

  const ShopImagePicker({super.key, required this.onImageSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Image picker logic here
        onImageSelected('');
      },
      child: Container(
        height: 150,
        padding: EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Color(0xFFE0E0E0),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Color(0xFFF5F9F3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 36,
                color: Color(0xFF4A7C2C),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Add Shop Image',
              style: TextStyle(
                color: Color(0xFF2D5016),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Optional',
              style: TextStyle(
                color: Color(0xFF999999),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}