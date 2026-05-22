import 'package:auth/view/doctor_view/doctor_notifications_page.dart';
import 'package:auth/view/screan/Auth/login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auth/view/chatbot/chatbot_fab.dart';


// --- الصفحة الرئيسية للطبيب | Dashboard Read Only ---
class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color _backgroundColor = Color(0xFFF5F8FF);
  static const Color _primaryColor = Colors.blueAccent;
  static const Color _darkText = Color(0xFF172033);
  static const Color _mutedText = Color(0xFF7A8194);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _docData(QueryDocumentSnapshot doc) {
    return doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  String _readString(Map<String, dynamic> data, String key, String fallback) {
    final value = data[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  bool _readBool(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  Stream<QuerySnapshot> _patientsStream(String doctorUid) {
    return FirebaseFirestore.instance
        .collection('profiles')
        .where('doctorUid', isEqualTo: doctorUid)
        .snapshots();
  }

  Stream<QuerySnapshot> _unreadNotificationsStream(String doctorUid) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('doctorUid', isEqualTo: doctorUid)
        .where('isRead', isEqualTo: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final String doctorUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: const Text(
            'لوحة تحكم الطبيب',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            _buildNotificationButton(doctorUid),
            IconButton(
              tooltip: 'تسجيل الخروج',
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
          stream: _patientsStream(doctorUid),
          builder: (context, patientSnapshot) {
            if (patientSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (patientSnapshot.hasError) {
              return _buildErrorState('حدث خطأ أثناء تحميل بيانات المرضى');
            }

            final patients = patientSnapshot.data?.docs ?? [];
            final filteredPatients = patients.where((doc) {
              final data = _docData(doc);
              final name = _readString(data, 'name', '').toLowerCase();
              final phone = _readString(data, 'phone', '').toLowerCase();
              final query = _searchQuery.toLowerCase().trim();
              return query.isEmpty || name.contains(query) || phone.contains(query);
            }).toList();

            final activePatients = patients.where((doc) {
              final data = _docData(doc);
              return _readBool(data, 'canTakeTest');
            }).length;

            final closedPatients = patients.length - activePatients;

            return StreamBuilder<QuerySnapshot>(
              stream: _unreadNotificationsStream(doctorUid),
              builder: (context, notificationSnapshot) {
                final unreadCount = notificationSnapshot.data?.docs.length ?? 0;

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildWelcomeHeader(),
                      const SizedBox(height: 16),
                      _buildStatsGrid(
                        totalPatients: patients.length,
                        activePatients: activePatients,
                        closedPatients: closedPatients,
                        unreadNotifications: unreadCount,
                        allPatients: patients,
                      ),
                      const SizedBox(height: 18),
                      _buildSearchBar(),
                      const SizedBox(height: 14),
                      _buildSectionTitle(
                        title: 'مرضاي المسجلين',
                        count: filteredPatients.length,
                      ),
                      const SizedBox(height: 10),
                      if (patients.isEmpty)
                        _buildEmptyState(
                          icon: Icons.group_off_outlined,
                          title: 'لا يوجد مرضى مسجلين حالياً',
                          subtitle: 'عند ربط المرضى بهذا الطبيب سيظهرون هنا تلقائياً.',
                        )
                      else if (filteredPatients.isEmpty)
                        _buildEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'لا توجد نتائج للبحث',
                          subtitle: 'جرب تكتب اسم أو رقم هاتف بطريقة مختلفة.',
                        )
                      else
                        ...filteredPatients.map(_buildPatientCard),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationButton(String doctorUid) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'الإشعارات',
          icon: const Icon(
            Icons.notifications_outlined,
            color: _primaryColor,
            size: 28,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DoctorNotificationsPage()),
            );
          },
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _unreadNotificationsStream(doctorUid),
          builder: (context, snapshot) {
            final count = snapshot.data?.docs.length ?? 0;
            if (count == 0) return const SizedBox.shrink();

            return Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4B7BFF), Color(0xFF65B7FF)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.medical_services_outlined, color: _primaryColor, size: 30),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلاً دكتور',
                  style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  'تابع مرضاك ونتائج التقييمات من مكان واحد',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid({
    required int totalPatients,
    required int activePatients,
    required int closedPatients,
    required int unreadNotifications,
    required List<QueryDocumentSnapshot> allPatients,
  }) {
    final openPatients = allPatients.where((doc) {
      final data = _docData(doc);
      return _readBool(data, 'canTakeTest');
    }).toList();

    final closedPatientsList = allPatients.where((doc) {
      final data = _docData(doc);
      return !_readBool(data, 'canTakeTest');
    }).toList();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _buildStatCard(
          title: 'إجمالي المرضى',
          value: '$totalPatients',
          icon: Icons.groups_2_outlined,
          color: _primaryColor,
          onTap: () => _openPatientsList(
            title: 'كل المرضى',
            patients: allPatients,
          ),
        ),
        _buildStatCard(
          title: 'جلسات مفتوحة',
          value: '$activePatients',
          icon: Icons.play_circle_outline_rounded,
          color: Colors.green,
          onTap: () => _openPatientsList(
            title: 'الجلسات المفتوحة',
            patients: openPatients,
          ),
        ),
        _buildStatCard(
          title: 'جلسات مغلقة',
          value: '$closedPatients',
          icon: Icons.lock_outline_rounded,
          color: Colors.orange,
          onTap: () => _openPatientsList(
            title: 'الجلسات المغلقة',
            patients: closedPatientsList,
          ),
        ),
        _buildStatCard(
          title: 'إشعارات جديدة',
          value: '$unreadNotifications',
          icon: Icons.notifications_active_outlined,
          color: Colors.redAccent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DoctorNotificationsPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            color: _darkText,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.touch_app_rounded, color: color.withOpacity(0.55), size: 16),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPatientsList({
    required String title,
    required List<QueryDocumentSnapshot> patients,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.82,
            decoration: const BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: _darkText,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${patients.length} مريض',
                          style: const TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: patients.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.inbox_outlined,
                          title: 'لا توجد بيانات هنا',
                          subtitle: 'لا يوجد مرضى مطابقين لهذا القسم حالياً.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                          itemCount: patients.length,
                          itemBuilder: (context, index) => _buildPatientCard(patients[index]),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'ابحث باسم المريض أو رقم الهاتف...',
          hintStyle: const TextStyle(color: _mutedText, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: _primaryColor),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, color: _mutedText),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required String title, required int count}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: _darkText, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count مريض',
            style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientCard(QueryDocumentSnapshot patientDoc) {
    final data = _docData(patientDoc);
    final name = _readString(data, 'name', 'مريض غير معروف');
    final phone = _readString(data, 'phone', 'غير مسجل');
    final canTakeTest = _readBool(data, 'canTakeTest');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientHistoryScreen(
                  patientUid: patientDoc.id,
                  patientName: name,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _primaryColor.withOpacity(0.12),
                  child: const Icon(Icons.person_rounded, color: _primaryColor, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _darkText,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, color: _mutedText, size: 15),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              phone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _mutedText, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildStatusBadge(canTakeTest),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _mutedText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool canTakeTest) {
    final color = canTakeTest ? Colors.green : Colors.orange;
    final text = canTakeTest ? 'جلسة مفتوحة' : 'في الانتظار / مغلقة';
    final icon = canTakeTest ? Icons.check_circle_outline_rounded : Icons.pause_circle_outline_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: _primaryColor.withOpacity(0.75), size: 54),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: _darkText, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: _mutedText, fontSize: 12.5, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: List.generate(4, (_) {
            return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)));
          }),
        ),
        const SizedBox(height: 18),
        const Center(child: CircularProgressIndicator(color: _primaryColor)),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 54),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _darkText, fontWeight: FontWeight.bold)),
          ],
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
        floatingActionButton: const ChatBotFAB(),
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