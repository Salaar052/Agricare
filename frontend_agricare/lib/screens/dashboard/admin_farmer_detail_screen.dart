import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api/auth_service.dart';

class AdminFarmerDetailScreen extends StatefulWidget {
  const AdminFarmerDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  State<AdminFarmerDetailScreen> createState() => _AdminFarmerDetailScreenState();
}

class _AdminFarmerDetailScreenState extends State<AdminFarmerDetailScreen> {
  final AuthService _authService = AuthService();
  bool _loading = true;
  Map<String, dynamic>? _farmer;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    try {
      final data = await _authService.fetchFarmerDetailsForAdmin(widget.userId);
      if (!mounted) return;
      setState(() => _farmer = data);
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _disableSeller() async {
    try {
      await _authService.disableSellerAccount(widget.userId);
      await _loadDetail();
      if (mounted) Get.back(result: true);
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _enableSeller() async {
    try {
      await _authService.enableSellerAccount(widget.userId);
      await _loadDetail();
      if (mounted) Get.back(result: true);
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _deleteSeller() async {
    final shouldDelete = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Delete Seller Account"),
        content: const Text(
          "Are you sure you want to delete this seller account? This will delete marketplace profile and all marketplace listings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await _authService.deleteSellerAccount(widget.userId);
      if (mounted) Get.back(result: true);
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmer = _farmer;
    final isSeller = farmer?['isSeller'] == true;
    final sellerIsActive = farmer?['sellerIsActive'] == true;
    final titleColor = const Color(0xFF1F3D22);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F2),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3E6D25), Color(0xFF5D8F3F)],
            ),
          ),
        ),
        title: const Text("Farmer Details"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : farmer == null
              ? const Center(child: Text("Farmer not found"))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD2E5CC)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3E6D25).withOpacity(0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF4E5),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(Icons.person_rounded),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    farmer['username']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      color: titleColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              farmer['email']?.toString() ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: isSeller
                                    ? (sellerIsActive
                                        ? const Color(0xFFE4F3DD)
                                        : const Color(0xFFFCE8E8))
                                    : const Color(0xFFF0F2EF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isSeller
                                    ? (sellerIsActive
                                        ? "Seller (Active)"
                                        : "Seller (Disabled)")
                                    : "Not a Seller",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSeller
                                      ? (sellerIsActive
                                          ? const Color(0xFF2E6A22)
                                          : const Color(0xFF9C2E2E))
                                      : const Color(0xFF596458),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isSeller) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: sellerIsActive ? _disableSeller : _enableSeller,
                                icon: Icon(
                                  sellerIsActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                                ),
                                label: Text(
                                  sellerIsActive ? "Disable Seller" : "Enable Seller",
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _deleteSeller,
                                icon: const Icon(Icons.delete_outline),
                                label: const Text("Delete Seller"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC93A3A),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
