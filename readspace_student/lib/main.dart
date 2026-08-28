import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin
    localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel
    readSpaceChannel =
    AndroidNotificationChannel(
  'readspace_notifications',
  'ReadSpace Notifications',
  description:
      'Book issue, return and library updates',
  importance: Importance.high,
);


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform,
  );
}


Future<void> setupNotifications() async {
  await FirebaseMessaging.instance
      .requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  const androidSettings =
      AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  const initializationSettings =
      InitializationSettings(
    android: androidSettings,
  );

  await localNotifications.initialize(
    settings: initializationSettings,
  );

  final androidPlugin =
      localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin
      ?.createNotificationChannel(
    readSpaceChannel,
  );

  FirebaseMessaging.onMessage.listen(
    (RemoteMessage message) {
      final notification =
          message.notification;

      if (notification == null) {
        return;
      }

      localNotifications.show(
        id: notification.hashCode,
        title:
            notification.title ??
            'ReadSpace',
        body:
            notification.body ?? '',
        notificationDetails:
            NotificationDetails(
          android:
              AndroidNotificationDetails(
            readSpaceChannel.id,
            readSpaceChannel.name,
            channelDescription:
                readSpaceChannel.description,
            importance:
                Importance.high,
            priority:
                Priority.high,
            icon:
                '@mipmap/ic_launcher',
          ),
        ),
      );
    },
  );
}


Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized();

  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging
      .onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  await setupNotifications();

  runApp(
    const ReadSpaceStudentApp(),
  );
}

const String apiBaseUrl =
    'https://readspace-backend-dmsp.onrender.com';

class ReadSpaceStudentApp extends StatelessWidget {
  const ReadSpaceStudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ReadSpace Student',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor:
            const Color(0xFFF8F6F1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5C8FA8),
        ),
      ),
      home: const StudentLoginPage(),
    );
  }
}

// =====================================================
// STUDENT LOGIN
// =====================================================

class StudentLoginPage extends StatefulWidget {
  const StudentLoginPage({super.key});

  @override
  State<StudentLoginPage> createState() =>
      _StudentLoginPageState();
}

class _StudentLoginPageState
    extends State<StudentLoginPage> {
  final TextEditingController studentController =
      TextEditingController();

  bool isLoading = false;
  String errorMessage = '';

  @override
  void dispose() {
    studentController.dispose();
    super.dispose();
  }

  Future<void> registerNotificationDevice(
    String studentId,
  ) async {
    try {
      final token =
          await FirebaseMessaging.instance
              .getToken();

      if (token == null ||
          token.isEmpty) {
        return;
      }

      await http
          .post(
            Uri.parse(
              '$apiBaseUrl/students/$studentId/fcm-token',
            ),
            headers: {
              'Content-Type':
                  'application/json',
            },
            body: jsonEncode({
              'token': token,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      FirebaseMessaging.instance
          .onTokenRefresh
          .listen(
        (newToken) async {
          try {
            await http.post(
              Uri.parse(
                '$apiBaseUrl/students/$studentId/fcm-token',
              ),
              headers: {
                'Content-Type':
                    'application/json',
              },
              body: jsonEncode({
                'token': newToken,
              }),
            );
          } catch (_) {}
        },
      );
    } catch (_) {
      // Notification registration must not
      // block student login.
    }
  }

  Future<void> loginStudent() async {
    final studentId =
        studentController.text.trim().toUpperCase();

    if (studentId.isEmpty) {
      setState(() {
        errorMessage =
            'Please enter your Student ID.';
      });

      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              '$apiBaseUrl/students/lookup/$studentId',
            ),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      final data = jsonDecode(response.body);

      if (!mounted) {
        return;
      }

      if (data['success'] == true) {
        final student =
            Map<String, dynamic>.from(
          data['student'],
        );

        await registerNotificationDevice(
          studentId,
        );

        if (!mounted) {
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StudentHomePage(
              student: student,
            ),
          ),
        );
      } else {
        setState(() {
          errorMessage =
              data['message'] ??
              'Student not found.';
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage =
            'Could not connect to ReadSpace server.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Column(
            children: [
              const Spacer(),

              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFDCEAF1),
                  borderRadius:
                      BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'R',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF315F75),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'ReadSpace',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(0xFF202020),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'STUDENT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                  letterSpacing: 1.8,
                  color:
                      Color(0xFF7595A4),
                ),
              ),

              const SizedBox(height: 40),

              Container(
                padding:
                    const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        const Color(0xFFE8E4DC),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Enter your Student ID to continue.',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            Color(0xFF777777),
                      ),
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      'Student ID',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller:
                          studentController,
                      enabled: !isLoading,
                      textCapitalization:
                          TextCapitalization
                              .characters,
                      onSubmitted: (_) {
                        if (!isLoading) {
                          loginStudent();
                        }
                      },
                      decoration:
                          InputDecoration(
                        hintText:
                            'e.g. BCA002',
                        prefixIcon:
                            const Icon(
                          Icons.person_outline,
                        ),
                        filled: true,
                        fillColor:
                            const Color(
                                0xFFFAF9F6),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  14),
                        ),
                      ),
                    ),

                    if (errorMessage
                        .isNotEmpty) ...[
                      const SizedBox(height: 14),

                      _ErrorBox(
                        message: errorMessage,
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed:
                            isLoading
                                ? null
                                : loginStudent,
                        style:
                            FilledButton.styleFrom(
                          backgroundColor:
                              const Color(
                                  0xFF5E8FA6),
                          foregroundColor:
                              Colors.white,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Text(
                                'Continue',
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              const Padding(
                padding:
                    EdgeInsets.only(
                        bottom: 18),
                child: Text(
                  'ReadSpace Library Management',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFF999999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// STUDENT HOME
// =====================================================

class StudentHomePage extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentHomePage({
    super.key,
    required this.student,
  });

  @override
  State<StudentHomePage> createState() =>
      _StudentHomePageState();
}

class _StudentHomePageState
    extends State<StudentHomePage> {
  bool loansLoading = true;
  String loansError = '';
  List<dynamic> currentLoans = [];
  int borrowedCount = 0;
  num totalFine = 0;
  int unreadNotifications = 0;

  String get studentName =>
      widget.student['name']?.toString() ??
      'Student';

  String get studentId =>
      widget.student['student_id']?.toString() ??
      '-';

  String get course =>
      widget.student['course']?.toString() ??
      '-';

  String get year =>
      widget.student['year']?.toString() ??
      '-';

  String get division =>
      widget.student['division']?.toString() ??
      '-';

  @override
  void initState() {
    super.initState();
    loadCurrentLoans();
    loadUnreadNotificationCount();
  }

  Future<void> loadCurrentLoans() async {
    setState(() {
      loansLoading = true;
      loansError = '';
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              '$apiBaseUrl/students/$studentId/current-loans',
            ),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      final data = jsonDecode(response.body);

      if (!mounted) {
        return;
      }

      if (data['success'] == true) {
        setState(() {
          currentLoans =
              data['loans'] ?? [];
          borrowedCount =
              data['borrowed_count'] ?? 0;
          totalFine =
              data['total_current_fine'] ?? 0;
        });
      } else {
        setState(() {
          currentLoans = [];
          borrowedCount = 0;
          totalFine = 0;
          loansError =
              data['message'] ??
              'Could not load borrowed books.';
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        currentLoans = [];
        borrowedCount = 0;
        totalFine = 0;
        loansError =
            'Could not connect to ReadSpace server.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loansLoading = false;
        });
      }
    }
  }


  Future<void> loadUnreadNotificationCount() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$apiBaseUrl/students/$studentId/notifications',
            ),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      final data = jsonDecode(response.body);

      if (!mounted || data['success'] != true) {
        return;
      }

      final list = data['notifications'] ?? [];

      setState(() {
        unreadNotifications = list
            .where(
              (item) => item['is_read'] != true,
            )
            .length;
      });
    } catch (_) {}
  }

  String formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    try {
      final date =
          DateTime.parse(value.toString());

      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String dueStatus(dynamic dueValue) {
    if (dueValue == null) {
      return 'ACTIVE';
    }

    try {
      final due =
          DateTime.parse(dueValue.toString())
              .toLocal();

      final today = DateTime.now();

      final todayOnly = DateTime(
        today.year,
        today.month,
        today.day,
      );

      final dueOnly = DateTime(
        due.year,
        due.month,
        due.day,
      );

      final difference =
          dueOnly.difference(todayOnly).inDays;

      if (difference < 0) {
        final days = difference.abs();

        return 'OVERDUE • $days DAY${days == 1 ? '' : 'S'}';
      }

      if (difference == 0) {
        return 'DUE TODAY';
      }

      if (difference == 1) {
        return 'DUE TOMORROW';
      }

      return '$difference DAYS LEFT';
    } catch (_) {
      return 'ACTIVE';
    }
  }

  Color dueBackground(dynamic dueValue) {
    final label = dueStatus(dueValue);

    if (label.startsWith('OVERDUE')) {
      return const Color(0xFFFFECE8);
    }

    if (label == 'DUE TODAY' ||
        label == 'DUE TOMORROW') {
      return const Color(0xFFFFF4D8);
    }

    return const Color(0xFFE5F3EA);
  }

  Color dueForeground(dynamic dueValue) {
    final label = dueStatus(dueValue);

    if (label.startsWith('OVERDUE')) {
      return const Color(0xFFA94B3F);
    }

    if (label == 'DUE TODAY' ||
        label == 'DUE TOMORROW') {
      return const Color(0xFF9A6A1D);
    }

    return const Color(0xFF407A58);
  }

  Widget buildLoanCard(dynamic loan) {
    final copy =
        loan['book_copies'] ?? {};

    final book =
        copy['books'] ?? {};

    final title =
        book['title']?.toString() ??
        'Unknown Book';

    final author =
        book['author']?.toString() ??
        '-';

    final accession =
        copy['accession_number']
                ?.toString() ??
            '-';

    final fine =
        loan['current_fine'] ?? 0;

    final lateDays =
        loan['late_days'] ?? 0;

    final dueDate =
        loan['due_date'];

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE8E4DC),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                          0xFFDCEAF1),
                  borderRadius:
                      BorderRadius
                          .circular(13),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color:
                      Color(0xFF315F75),
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight
                                .w700,
                        color:
                            Color(
                                0xFF202020),
                      ),
                    ),

                    const SizedBox(
                        height: 4),

                    Text(
                      author,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Color(
                                0xFF777777),
                      ),
                    ),

                    const SizedBox(
                        height: 7),

                    Text(
                      accession,
                      style:
                          const TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight
                                .w600,
                        color:
                            Color(
                                0xFF7595A4),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      dueBackground(
                          dueDate),
                  borderRadius:
                      BorderRadius
                          .circular(20),
                ),
                child: Text(
                  dueStatus(dueDate),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing: .4,
                    color:
                        dueForeground(
                            dueDate),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(
                    14),
            decoration: BoxDecoration(
              color:
                  const Color(
                      0xFFFAF9F6),
              borderRadius:
                  BorderRadius.circular(
                      14),
            ),
            child: Column(
              children: [
                _BookInfoRow(
                  label: 'Issued',
                  value: formatDate(
                    loan['issue_date'],
                  ),
                ),

                const SizedBox(height: 10),

                _BookInfoRow(
                  label: 'Due Date',
                  value: formatDate(
                    dueDate,
                  ),
                ),

                const SizedBox(height: 10),

                _BookInfoRow(
                  label: 'Fine',
                  value: fine > 0
                      ? '₹$fine'
                      : '₹0',
                ),

                if (lateDays > 0) ...[
                  const SizedBox(
                      height: 10),

                  _BookInfoRow(
                    label: 'Late',
                    value:
                        '$lateDays day${lateDays == 1 ? '' : 's'}',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF8F6F1),
        surfaceTintColor:
            const Color(0xFFF8F6F1),
        title: const Text(
          'ReadSpace Student',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                loansLoading
                    ? null
                    : () async {
                        await loadCurrentLoans();
                        await loadUnreadNotificationCount();
                      },
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              final shouldLogout =
                  await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text(
                      'Logout',
                    ),
                    content: const Text(
                      'Are you sure you want to logout?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            false,
                          );
                        },
                        child: const Text(
                          'Cancel',
                        ),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            true,
                          );
                        },
                        child: const Text(
                          'Logout',
                        ),
                      ),
                    ],
                  );
                },
              );

              if (shouldLogout != true ||
                  !context.mounted) {
                return;
              }

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const StudentLoginPage(),
                ),
                (route) => false,
              );
            },
            icon: const Icon(
              Icons.logout_rounded,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadCurrentLoans,
          child: ListView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFDCEAF1),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                                14),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color:
                            Color(0xFF315F75),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Color(0xFF607D8B),
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            studentName,
                            style:
                                const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.w700,
                              color:
                                  Color(0xFF234E62),
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            studentId,
                            style:
                                const TextStyle(
                              fontSize: 12,
                              color:
                                  Color(0xFF607D8B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        const Color(0xFFE8E4DC),
                  ),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    _MiniInfo(
                      label: 'Course',
                      value: course,
                    ),
                    _MiniInfo(
                      label: 'Year',
                      value: year,
                    ),
                    _MiniInfo(
                      label: 'Division',
                      value: division,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon:
                          Icons
                              .menu_book_outlined,
                      label:
                          'Books Borrowed',
                      value:
                          loansLoading
                              ? '...'
                              : '$borrowedCount',
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _SummaryCard(
                      icon:
                          Icons
                              .currency_rupee,
                      label:
                          'Current Fine',
                      value:
                          loansLoading
                              ? '...'
                              : '₹$totalFine',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  const Text(
                    'Current Books',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  if (!loansLoading)
                    Text(
                      '$borrowedCount',
                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(
                                0xFF7595A4),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              if (loansLoading)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 35,
                  ),
                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                )
              else if (loansError
                  .isNotEmpty)
                _ErrorBox(
                  message: loansError,
                )
              else if (currentLoans.isEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(
                          24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                            18),
                    border: Border.all(
                      color:
                          const Color(
                              0xFFE8E4DC),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons
                            .library_books_outlined,
                        size: 42,
                        color:
                            Color(
                                0xFF9BA9AF),
                      ),

                      SizedBox(height: 10),

                      Text(
                        'No books borrowed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Books issued to you will appear here.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Color(
                                  0xFF777777),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...currentLoans.map(
                  buildLoanCard,
                ),

              const SizedBox(height: 28),

              const Text(
                'Library',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 18),

              _StudentActionCard(
                icon:
                    Icons.search_outlined,
                title:
                    'Check Book Availability',
                subtitle:
                    'Search for a book and view its status',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const BookAvailabilityPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              _StudentActionCard(
                icon:
                    Icons.notifications_none_outlined,
                title:
                    'Notifications',
                subtitle:
                    unreadNotifications > 0
                        ? '$unreadNotifications unread update${unreadNotifications == 1 ? '' : 's'}'
                        : 'View issue and return updates',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          StudentNotificationsPage(
                        studentId: studentId,
                      ),
                    ),
                  );

                  if (!mounted) {
                    return;
                  }

                  await loadUnreadNotificationCount();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              const Color(0xFFE8E4DC),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  const Color(
                      0xFFDCEAF1),
              borderRadius:
                  BorderRadius.circular(
                      11),
            ),
            child: Icon(
              icon,
              size: 20,
              color:
                  const Color(
                      0xFF315F75),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF202020),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color:
                  Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// BOOK AVAILABILITY PAGE
// =====================================================

class BookAvailabilityPage
    extends StatefulWidget {
  const BookAvailabilityPage({
    super.key,
  });

  @override
  State<BookAvailabilityPage> createState() =>
      _BookAvailabilityPageState();
}

class _BookAvailabilityPageState
    extends State<BookAvailabilityPage> {
  final TextEditingController
      searchController =
      TextEditingController();

  bool isLoading = true;
  String errorMessage = '';
  List<dynamic> books = [];

  @override
  void initState() {
    super.initState();
    searchBooks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> searchBooks() async {
    final query =
        searchController.text.trim();

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final uri = Uri.parse(
        '$apiBaseUrl/books/search',
      ).replace(
        queryParameters: {
          'q': query,
        },
      );

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
          );

      final data = jsonDecode(response.body);

      if (!mounted) {
        return;
      }

      if (data['success'] == true) {
        setState(() {
          books =
              data['books'] ?? [];
        });
      } else {
        setState(() {
          books = [];
          errorMessage =
              data['message'] ??
              'Could not load books.';
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        books = [];
        errorMessage =
            'Could not connect to ReadSpace server.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Color statusBackground(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xFFE5F3EA);

      case 'issued':
        return const Color(0xFFFFECE8);

      case 'reserved':
        return const Color(0xFFFFF4D8);

      default:
        return const Color(0xFFF0EFEA);
    }
  }

  Color statusForeground(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xFF407A58);

      case 'issued':
        return const Color(0xFFA94B3F);

      case 'reserved':
        return const Color(0xFF9A6A1D);

      default:
        return const Color(0xFF666666);
    }
  }

  Widget buildBookCard(dynamic item) {
    final book =
        item['books'] ?? {};

    final title =
        book['title']?.toString() ??
            'Unknown Book';

    final author =
        book['author']?.toString() ??
            '-';

    final category =
        book['category']?.toString() ??
            '-';

    final accession =
        item['accession_number']
                ?.toString() ??
            '-';

    final status =
        item['status']?.toString() ??
            'unknown';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE8E4DC),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                          0xFFDCEAF1),
                  borderRadius:
                      BorderRadius
                          .circular(13),
                ),
                child: const Icon(
                  Icons
                      .menu_book_outlined,
                  color:
                      Color(0xFF315F75),
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight
                                .w700,
                        color:
                            Color(
                                0xFF202020),
                      ),
                    ),

                    const SizedBox(
                        height: 4),

                    Text(
                      author,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Color(
                                0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      statusBackground(
                          status),
                  borderRadius:
                      BorderRadius
                          .circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing: .6,
                    color:
                        statusForeground(
                            status),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(
                    13),
            decoration: BoxDecoration(
              color:
                  const Color(
                      0xFFFAF9F6),
              borderRadius:
                  BorderRadius.circular(
                      13),
            ),
            child: Column(
              children: [
                _BookInfoRow(
                  label: 'Category',
                  value: category,
                ),

                const SizedBox(height: 9),

                _BookInfoRow(
                  label: 'Accession',
                  value: accession,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF8F6F1),
        surfaceTintColor:
            const Color(0xFFF8F6F1),
        title: const Text(
          'Book Availability',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: searchBooks,
          child: ListView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),
            children: [
              const Text(
                'Find a Book',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Search by title, author, accession number, barcode or ISBN.',
                style: TextStyle(
                  fontSize: 13,
                  color:
                      Color(0xFF777777),
                ),
              ),

              const SizedBox(height: 18),

              TextField(
                controller:
                    searchController,
                textInputAction:
                    TextInputAction.search,
                onSubmitted: (_) {
                  searchBooks();
                },
                decoration:
                    InputDecoration(
                  hintText:
                      'Search books...',
                  prefixIcon:
                      const Icon(
                    Icons.search,
                  ),
                  suffixIcon:
                      IconButton(
                    onPressed:
                        searchBooks,
                    icon: const Icon(
                      Icons.arrow_forward,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                            14),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                            14),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(
                              0xFFE8E4DC),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              if (isLoading)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 50,
                  ),
                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage
                  .isNotEmpty)
                _ErrorBox(
                  message:
                      errorMessage,
                )
              else if (books.isEmpty)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 50,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons
                            .search_off_outlined,
                        size: 54,
                        color:
                            Color(
                                0xFF999999),
                      ),

                      SizedBox(height: 12),

                      Text(
                        'No books found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Try another title or accession number.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Color(
                                  0xFF777777),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  '${books.length} result${books.length == 1 ? '' : 's'}',
                  style:
                      const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(
                            0xFF7595A4),
                  ),
                ),

                const SizedBox(
                    height: 12),

                ...books.map(
                  buildBookCard,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


// =====================================================
// STUDENT NOTIFICATIONS PAGE
// =====================================================

class StudentNotificationsPage extends StatefulWidget {
  final String studentId;

  const StudentNotificationsPage({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentNotificationsPage> createState() =>
      _StudentNotificationsPageState();
}

class _StudentNotificationsPageState
    extends State<StudentNotificationsPage> {
  bool isLoading = true;
  String errorMessage = '';
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              '$apiBaseUrl/students/${widget.studentId}/notifications',
            ),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      final data = jsonDecode(response.body);

      if (!mounted) {
        return;
      }

      if (data['success'] == true) {
        setState(() {
          notifications = data['notifications'] ?? [];
        });
      } else {
        setState(() {
          notifications = [];
          errorMessage =
              data['message'] ??
              'Could not load notifications.';
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        notifications = [];
        errorMessage =
            'Could not connect to ReadSpace server.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> markAsRead(
    dynamic notification,
  ) async {
    if (notification['is_read'] == true) {
      return;
    }

    final id = notification['id'];

    if (id == null) {
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse(
              '$apiBaseUrl/notifications/$id/read',
            ),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      final data = jsonDecode(response.body);

      if (!mounted || data['success'] != true) {
        return;
      }

      setState(() {
        notification['is_read'] = true;
      });
    } catch (_) {}
  }

  String formatTime(dynamic value) {
    if (value == null) {
      return '';
    }

    try {
      final date =
          DateTime.parse(value.toString()).toLocal();
      final now = DateTime.now();

      final today = DateTime(
        now.year,
        now.month,
        now.day,
      );

      final itemDay = DateTime(
        date.year,
        date.month,
        date.day,
      );

      final diff =
          today.difference(itemDay).inDays;

      final hour =
          date.hour % 12 == 0
              ? 12
              : date.hour % 12;

      final minute =
          date.minute
              .toString()
              .padLeft(2, '0');

      final period =
          date.hour >= 12 ? 'PM' : 'AM';

      final time = '$hour:$minute $period';

      if (diff == 0) {
        return 'Today • $time';
      }

      if (diff == 1) {
        return 'Yesterday • $time';
      }

      return '${date.day}/${date.month}/${date.year} • $time';
    } catch (_) {
      return value.toString();
    }
  }

  IconData iconFor(String type) {
    if (type == 'book_issued') {
      return Icons.library_add_outlined;
    }

    if (type == 'book_returned') {
      return Icons.assignment_return_outlined;
    }

    return Icons.notifications_none_outlined;
  }

  Color iconBackground(String type) {
    if (type == 'book_returned') {
      return const Color(0xFFE5F3EA);
    }

    return const Color(0xFFDCEAF1);
  }

  Color iconForeground(String type) {
    if (type == 'book_returned') {
      return const Color(0xFF407A58);
    }

    return const Color(0xFF315F75);
  }

  Widget buildCard(dynamic notification) {
    final title =
        notification['title']?.toString() ??
        'ReadSpace';

    final message =
        notification['message']?.toString() ??
        '';

    final type =
        notification['notification_type']
                ?.toString() ??
            '';

    final isRead =
        notification['is_read'] == true;

    return InkWell(
      borderRadius:
          BorderRadius.circular(18),
      onTap: () {
        markAsRead(notification);
      },
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white
              : const Color(0xFFF5FAFC),
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: isRead
                ? const Color(0xFFE8E4DC)
                : const Color(0xFFB9D8EB),
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration:
                  BoxDecoration(
                color:
                    iconBackground(type),
                borderRadius:
                    BorderRadius.circular(13),
              ),
              child: Icon(
                iconFor(type),
                color:
                    iconForeground(type),
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style:
                              TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                            color:
                                const Color(
                                    0xFF202020),
                          ),
                        ),
                      ),

                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration:
                              const BoxDecoration(
                            color:
                                Color(0xFF5E8FA6),
                            shape:
                                BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    message,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color:
                          Color(0xFF666666),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    formatTime(
                      notification['created_at'],
                    ),
                    style:
                        const TextStyle(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Color(0xFF8C9AA1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        notifications
            .where(
              (item) => item['is_read'] != true,
            )
            .length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF8F6F1),
        surfaceTintColor:
            const Color(0xFFF8F6F1),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                isLoading
                    ? null
                    : loadNotifications,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadNotifications,
          child: ListView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),
            children: [
              const Text(
                'Library Updates',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                unreadCount > 0
                    ? '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}'
                    : 'You are all caught up.',
                style:
                    const TextStyle(
                  fontSize: 12,
                  color:
                      Color(0xFF777777),
                ),
              ),

              const SizedBox(height: 20),

              if (isLoading)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 50,
                  ),
                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage
                  .isNotEmpty)
                _ErrorBox(
                  message: errorMessage,
                )
              else if (notifications
                  .isEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(28),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          const Color(0xFFE8E4DC),
                    ),
                  ),
                  child:
                      const Column(
                    children: [
                      Icon(
                        Icons
                            .notifications_none_outlined,
                        size: 48,
                        color:
                            Color(0xFF9BA9AF),
                      ),

                      SizedBox(height: 12),

                      Text(
                        'No notifications yet',
                        style:
                            TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Book issue and return updates will appear here.',
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          fontSize: 12,
                          color:
                              Color(0xFF777777),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...notifications.map(
                  buildCard,
                ),
            ],
          ),
        ),
      ),
    );
  }
}


// =====================================================
// SMALL REUSABLE WIDGETS
// =====================================================

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;

  const _MiniInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color:
                Color(0xFF888888),
          ),
        ),

        const SizedBox(height: 3),

        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w700,
            color:
                Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}

class _BookInfoRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _BookInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style:
                const TextStyle(
              fontSize: 12,
              color:
                  Color(
                      0xFF888888),
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            style:
                const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(
                      0xFF333333),
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentActionCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _StudentActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color:
                  const Color(
                      0xFFE8E4DC),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      const Color(
                          0xFFDCEAF1),
                  borderRadius:
                      BorderRadius
                          .circular(13),
                ),
                child: Icon(
                  icon,
                  color:
                      const Color(
                          0xFF315F75),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight
                                .w700,
                        color:
                            Color(
                                0xFF202020),
                      ),
                    ),

                    const SizedBox(
                        height: 4),

                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Color(
                                0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color:
                    Color(0xFF999999),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            const Color(0xFFFFECE8),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: 20,
            color:
                Color(0xFFA94B3F),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              message,
              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    Color(
                        0xFF8A3D35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
