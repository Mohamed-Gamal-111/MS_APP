import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl;

class DoctorNotificationsPage extends StatelessWidget {
  const DoctorNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // جلب الـ UID الحالي بدقة
    final String? currentDoctorUid = FirebaseAuth.instance.currentUser?.uid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FF),
        appBar: AppBar(
          title: const Text('تنبيهات المرضى', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: currentDoctorUid == null 
          ? const Center(child: Text("يرجى تسجيل الدخول أولاً"))
          : StreamBuilder<QuerySnapshot>(
              // الفلترة حسب الـ doctorUid
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('doctorUid', isEqualTo: currentDoctorUid)
                  .snapshots(), 
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("حدث خطأ: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("لا توجد إشعارات مسجلة لهذا الحساب"));
                }

                // ترتيب الإشعارات يدوياً في الكود إذا فشل الـ Firebase في الترتيب
                final notifications = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final bool isRead = data['isRead'] ?? false;
                    final Timestamp? time = data['time'] as Timestamp?;
                    
                    String formattedTime = time != null 
                        ? intl.DateFormat('dd/MM - hh:mm a').format(time.toDate()) 
                        : "وقت غير معروف";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: isRead ? Colors.white : Colors.blue.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: Icon(
                          isRead ? Icons.mark_email_read_outlined : Icons.mark_email_unread,
                          color: isRead ? Colors.grey : Colors.blue,
                        ),
                        title: Text(data['message'] ?? "إشعار جديد"),
                        subtitle: Text(formattedTime, style: const TextStyle(fontSize: 12)),
                        onTap: () {
                          // تحديث الحالة عند الضغط
                          doc.reference.update({'isRead': true});
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