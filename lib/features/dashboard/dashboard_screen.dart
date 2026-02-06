import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';

import '../auth/login_screen.dart';
import '../inventory/inventory_screen.dart';
import '../transactions/transaction_screen.dart';
import '../transactions/delivery_list_screen.dart';
import '../transactions/delivery_history_screen.dart';
import '../report/report_screen.dart';
import '../inventory/mutation_screen.dart';
import '../inventory/supplier_screen.dart';
import '../notification/notification_screen.dart';
import '../report/audit_log_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final DashboardService _dashboardService = DashboardService();

  late bool isAdmin;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    isAdmin = _authService.isAdmin;
    userEmail = _authService.currentUser?.email;
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const LoginScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = isAdmin ? Colors.blue[800]! : Colors.orange[800]!;
    String roleText = isAdmin ? "Admin Gudang" : "Kurir Logistik";

    return Scaffold(
      backgroundColor: Colors.grey[100], 
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(25, 60, 25, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isAdmin 
                    ? [Colors.blue[900]!, Colors.blueAccent] 
                    : [Colors.orange[900]!, Colors.orangeAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(color: primaryColor.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(
                            "https://ui-avatars.com/api/?name=${userEmail ?? 'User'}&background=random&size=128"
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Selamat Datang,", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                            Text(
                              userEmail?.split('@')[0].toUpperCase() ?? "USER",
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3))
                              ),
                              child: Text(
                                roleText.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            )
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => NotificationScreen(isAdmin: isAdmin))
                            ),
                            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                            tooltip: "Notifikasi",
                          ),
                          IconButton(
                            onPressed: _handleLogout, 
                            icon: const Icon(Icons.logout, color: Colors.white),
                            tooltip: "Keluar",
                          )
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ringkasan Data", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 15),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        if (isAdmin) ...[
                          _buildLiveStatCard("Total Jenis Barang", _dashboardService.getProductCountStream(), Colors.blue, Icons.inventory_2),
                          const SizedBox(width: 15),
                          _buildLiveStatCard("Perlu Dikirim", _dashboardService.getOrderCountStream('Dikemas'), Colors.orange, Icons.local_shipping_outlined),
                          const SizedBox(width: 15),
                          _buildLiveStatCard("Riwayat Masuk", _dashboardService.getTransactionCountStream('IN'), Colors.green, Icons.download),
                        ] else ...[
                          _buildLiveStatCard("Tugas Baru", _dashboardService.getOrderCountStream('Dikirim'), Colors.orange, Icons.delivery_dining),
                          const SizedBox(width: 15),
                          _buildLiveStatCard("Paket Selesai", _dashboardService.getOrderCountStream('Sampai'), Colors.green, Icons.check_circle_outline),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Akses Cepat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 20),
                  
                  isAdmin 
                    ? _buildAdminMenu(context) 
                    : _buildCourierMenu(context),
                    
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStatCard(String title, Stream<QuerySnapshot> stream, MaterialColor color, IconData icon) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        String count = "...";
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length.toString();
        }
        return Container(
          width: 150,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                ],
              ),
              const SizedBox(height: 15),
              Text(count, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color[800])),
              const SizedBox(height: 5),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }
    );
  }
  
  Widget _buildAdminMenu(BuildContext context) {
    return Column(
      children: [
        _sectionLabel("Transaksi Harian"),
        Row(
          children: [
            Expanded(child: _modernMenuCard("Restock Masuk", Icons.add_business, Colors.green, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionScreen(isMasuk: true)));
            })),
            const SizedBox(width: 15),
            Expanded(child: _modernMenuCard("Kirim Paket", Icons.local_shipping, Colors.orange, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionScreen(isMasuk: false)));
            })),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel("Monitoring"),
        Row(
          children: [
            Expanded(child: _modernMenuCard("Cek Stok", Icons.inventory, Colors.blue, () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen()));
            })),
            const SizedBox(width: 15),
            Expanded(child: _modernMenuCard("Pantau Kurir", Icons.map_outlined, Colors.indigo, () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const DeliveryListScreen()));
            })),
          ],
        ),
        const SizedBox(height: 15),
        _modernMenuCard("Laporan Lengkap", Icons.analytics, Colors.purple, () {
           Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportScreen()));
        }, isFullWidth: true),
        const SizedBox(height: 20),
        _sectionLabel("Manajemen Data"),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _smallMenuCard("Supplier", Icons.store, Colors.teal, () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const SupplierScreen()));
              }),
              const SizedBox(width: 10),
              _smallMenuCard("Mutasi", Icons.swap_horiz, Colors.cyan, () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const MutationScreen()));
              }),
              const SizedBox(width: 10),
              _smallMenuCard("Audit Log", Icons.history_edu, Colors.blueGrey, () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const AuditLogScreen()));
              }),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildCourierMenu(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.1,
      children: [
        _modernMenuCard("Tugas Pengantaran", Icons.assignment_late, Colors.orange, () {
           Navigator.push(context, MaterialPageRoute(builder: (context) => const DeliveryListScreen()));
        }),
        _modernMenuCard("Riwayat Selesai", Icons.history, Colors.blue, () {
           Navigator.push(context, MaterialPageRoute(builder: (context) => const DeliveryHistoryScreen()));
        }),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1)),
      ),
    );
  }

  Widget _modernMenuCard(String title, IconData icon, MaterialColor color, VoidCallback onTap, {bool isFullWidth = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color[800])),
          ],
        ),
      ),
    );
  }

  Widget _smallMenuCard(String title, IconData icon, MaterialColor color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}