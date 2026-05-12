import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api/auth_service.dart';
import 'admin_farmer_detail_screen.dart';

class AdminFarmersScreen extends StatefulWidget {
  const AdminFarmersScreen({super.key});

  @override
  State<AdminFarmersScreen> createState() => _AdminFarmersScreenState();
}

class _AdminFarmersScreenState extends State<AdminFarmersScreen> {
  final AuthService _authService = AuthService();
  bool _loading = true;
  List<Map<String, dynamic>> _farmers = [];

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  Future<void> _loadFarmers() async {
    setState(() => _loading = true);
    try {
      final data = await _authService.fetchAllFarmersForAdmin();
      if (!mounted) return;
      setState(() => _farmers = data);
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text("Registered Farmers"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFarmers,
              child: _farmers.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 110),
                        Icon(Icons.people_outline_rounded, size: 52, color: Color(0xFF7A8A76)),
                        SizedBox(height: 10),
                        Center(child: Text("No farmers found")),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                      itemCount: _farmers.length,
                      itemBuilder: (context, index) {
                        final farmer = _farmers[index];
                        final userId = farmer['_id']?.toString() ?? '';
                        final isSeller = farmer['isSeller'] == true;
                        final sellerIsActive = farmer['sellerIsActive'] == true;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD2E5CC)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3E6D25).withOpacity(0.10),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            onTap: userId.isEmpty
                                ? null
                                : () async {
                                    await Get.to(
                                      () => AdminFarmerDetailScreen(userId: userId),
                                      transition: Transition.rightToLeftWithFade,
                                      duration: const Duration(milliseconds: 320),
                                    );
                                    await _loadFarmers();
                                  },
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF4E5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.agriculture_rounded),
                            ),
                            title: Text(
                              farmer['username']?.toString() ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16.5,
                                color: titleColor,
                              ),
                            ),
                            subtitle: Text(
                              farmer['email']?.toString() ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            trailing: Chip(
                              backgroundColor: isSeller
                                  ? (sellerIsActive
                                      ? const Color(0xFFE4F3DD)
                                      : const Color(0xFFFCE8E8))
                                  : const Color(0xFFF0F2EF),
                              label: Text(
                                isSeller
                                    ? (sellerIsActive ? "Seller" : "Seller (Disabled)")
                                    : "Not Seller",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSeller
                                      ? (sellerIsActive
                                          ? const Color(0xFF2E6A22)
                                          : const Color(0xFF9C2E2E))
                                      : const Color(0xFF5E6A5B),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
