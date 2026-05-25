import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:auth/view/screan/Auth/login.dart';

class DoctorProfilePage extends StatelessWidget {
  const DoctorProfilePage({super.key});

  static const Color primary = Color(0xFF4285F4);
  static const Color bg = Color(0xFFF5F8FF);
  static const Color dark = Color(0xFF111827);
  static const Color muted = Color(0xFF7A8194);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: true,
          iconTheme: const IconThemeData(color: dark),
          title: const Text(
            'الملف الشخصي',
            style: TextStyle(
              color: dark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
          builder: (context, snapshot) {
            Map<String, dynamic>? data;

            if (snapshot.hasData && snapshot.data!.exists) {
              data = snapshot.data!.data() as Map<String, dynamic>?;
            }

            final String name = data?['name']?.toString().trim().isNotEmpty == true
                ? data!['name'].toString()
                : user?.displayName ?? 'Doctor';

            final String email = data?['email']?.toString().trim().isNotEmpty == true
                ? data!['email'].toString()
                : user?.email ?? 'No Email';

            final String specialization =
                data?['specialization']?.toString().trim().isNotEmpty == true
                    ? data!['specialization'].toString()
                    : 'Neurology Specialist';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4285F4), Color(0xFF2557E8)],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withOpacity(.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 55,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: dark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          specialization,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _buildInfoCard(
                    icon: Icons.email_outlined,
                    title: 'البريد الإلكتروني',
                    value: email,
                  ),
                  const SizedBox(height: 14),
                  _buildInfoCard(
                    icon: Icons.badge_outlined,
                    title: 'الدور',
                    value: 'Doctor',
                  ),
                  const SizedBox(height: 14),
                  _buildInfoCard(
                    icon: Icons.local_hospital_outlined,
                    title: 'النظام الطبي',
                    value: 'MS & Parkinson Detection',
                  ),
                  const SizedBox(height: 14),
                  _buildInfoCard(
                    icon: Icons.verified_user_outlined,
                    title: 'حالة الحساب',
                    value: 'Active',
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Colors.redAccent, Colors.red],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(.22),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();

                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: primary.withOpacity(.08),
            child: Icon(icon, color: primary),
          ),
          const Spacer(),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: muted, fontSize: 13),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(
                    color: dark,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.04),
          blurRadius: 14,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
