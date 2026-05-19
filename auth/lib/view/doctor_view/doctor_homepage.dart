import 'package:auth/view/doctor_view/doctor_notifications_page.dart';
import 'package:auth/view/screan/Auth/login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- الصفحة الرئيسية للطبيب ---
class DoctorHomePage extends StatelessWidget {
  const DoctorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String doctorUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FF),
        appBar: AppBar(
          title: const Text(
            'مرضاي المسجلين',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.blueAccent, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DoctorNotificationsPage()),
                    );
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .where('doctorUid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                          child: Text(
                            '${snapshot.data!.docs.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                }
              },
            ),
            const SizedBox(width: 5),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('profiles')
              .where('doctorUid', isEqualTo: doctorUid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('لا يوجد مرضى مسجلين حالياً'));
            }

            final patients = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final p = patients[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(p['name'] ?? 'مريض غير معروف', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('رقم الهاتف: ${p['phone'] ?? 'غير مسجل'}'),
                    trailing: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PatientHistoryScreen(
                            patientUid: p.id,
                            patientName: p['name'] ?? 'مريض',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// --- صفحة سجل المريض المعدلة لمسح البيانات عند بدء جلسة جديدة ---
class PatientHistoryScreen extends StatelessWidget {
  final String patientUid;
  final String patientName;

  const PatientHistoryScreen({
    super.key,
    required this.patientUid,
    required this.patientName,
  });

  Future<void> _resetAndOpenNewSession(BuildContext context) async {
    try {
      // 1. فتح الصلاحيات وتصفير الستيت لكل التستات في بروفايل المريض
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(patientUid)
          .update({
        'canTakeTest': true,
        'testsStatus': {
          'SDMT': true,
          'Fatigue': true,
          'Memory': true,
          'Drawing': true,
          'Mood': true,
          'FingerTap': true,
          'Balance': true,
          'Walking': true,
          'FingerToNose': true, // 🔥 مبروك! ده السطر البطل اللي حل اللغز النهائي للأزمة كلها
        }
      });

      // 2. تصفير كولكشن الـ evaluations بأمان صريح عبر الـ set(merge)
      await FirebaseFirestore.instance
          .collection('evaluations')
          .doc(patientUid)
          .set({
        'testResults': FieldValue.delete(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم بدء جلسة جديدة وتصفير كافة النتائج بنجاح 🚀"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("حدث خطأ أثناء التصفير: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FF),
        appBar: AppBar(
          title: Text(patientName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildPermissionToggle(patientUid),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text("بدء جلسة تقييم جديدة (تصفير النتائج)",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () => _resetAndOpenNewSession(context),
                ),
              ),

              const Padding(
                padding: EdgeInsets.all(20),
                child: Align(alignment: Alignment.centerRight, child: Text("نتائج التقييم الحالي:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ),

              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('evaluations')
                    .doc(patientUid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return _buildNoDataPlaceholder();
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data == null) return _buildNoDataPlaceholder();

                  final results = data['testResults'] as Map<String, dynamic>?;

                  if (results == null || results.isEmpty) {
                    return _buildNoDataPlaceholder();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        leading: const Icon(Icons.analytics_outlined, color: Colors.blue, size: 28),
                        title: const Text("نتائج الجلسة النشطة", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("تظهر هنا نتائج الاختبارات بمجرد إرسالها"),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.05),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                            ),
                            child: Column(
                              children: results.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_translateKey(entry.key), style: const TextStyle(color: Colors.black87, fontSize: 14)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text("${entry.value}",
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataPlaceholder() {
    return const Center(child: Padding(
      padding: EdgeInsets.all(40.0),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, color: Colors.grey, size: 50),
          SizedBox(height: 10), // 🔥 تم تصليحها هنا ورجعت طبيعية
          Text("لا توجد نتائج لهذه الجلسة بعد", style: TextStyle(color: Colors.grey)),
        ],
      ),
    ));
  }

  Widget _buildPermissionToggle(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('profiles').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();

        Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
        bool canTakeTest = data.containsKey('canTakeTest') ? data['canTakeTest'] : false;

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
          ),
          child: SwitchListTile(
            title: const Text("الصلاحية العامة للدخول", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(canTakeTest ? "مفتوح الآن للمريض" : "مغلق (المريض لا يستطيع الدخول)"),
            value: canTakeTest,
            activeColor: Colors.green,
            onChanged: (bool value) async {
              await FirebaseFirestore.instance.collection('profiles').doc(uid).update({'canTakeTest': value});
            },
          ),
        );
      },
    );
  }

  String _translateKey(String key) {
    switch (key) {
      case 'SDMT_ProcessingSpeed': return 'سرعة المعالجة (SDMT)';
      case 'FSS_Fatigue': return 'مستوى الإرهاق (FSS)';
      case 'FingerTap_Right': return 'نقر اليد اليمنى';
      case 'FingerTap_Left': return 'نقر اليد اليسرى';
      case 'HADS_Anxiety': return 'مستوى القلق (HADS)';
      case 'HADS_Depression': return 'مستوى الاكتئاب (HADS)';
      case 'BVMT_Drawing': return 'اختبار الرسم (BVMT)';
      case 'CVLT_Memory': return 'اختبار الذاكرة (CVLT)';
      case 'Finger_Prediction': return 'تحليل حركة اليد (Finger To Nose)';
      case 'Romberg_Prediction': return 'تحليل ثبات الاتزان (Romberg)';
      case 'Tandem_Prediction': return 'تحليل نمط السير (Tandem المشي)';
      default: return key;
    }
  }
}