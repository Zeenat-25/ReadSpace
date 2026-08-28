import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const ReadSpaceStaffApp());
}

const String apiBaseUrl =
    'https://readspace-backend-dmsp.onrender.com';
final ValueNotifier<int> activityRefreshNotifier = ValueNotifier<int>(0);

class ReadSpaceStaffApp extends StatelessWidget {
  const ReadSpaceStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ReadSpace Staff',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F6F1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5C8FA8),
        ),
      ),
      home: const StaffLoginPage(),
    );
  }
}

// =====================================================
// LOGIN PAGE
// =====================================================

class StaffLoginPage extends StatefulWidget {
  const StaffLoginPage({super.key});

  @override
  State<StaffLoginPage> createState() =>
      _StaffLoginPageState();
}

class _StaffLoginPageState extends State<StaffLoginPage> {
  final TextEditingController librarianController =
      TextEditingController();

  bool isLoading = false;
  String errorMessage = '';

  @override
  void dispose() {
    librarianController.dispose();
    super.dispose();
  }

  Future<void> continueToStaffApp() async {
    final librarianId =
        librarianController.text.trim().toUpperCase();

    if (librarianId.isEmpty) {
      setState(() {
        errorMessage =
            'Please enter your Librarian ID.';
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
              '$apiBaseUrl/librarians/validate/$librarianId',
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
        final librarian =
            data['librarian'] ?? {};

        final librarianName =
            librarian['name']?.toString() ??
            'Librarian';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StaffHomePage(
              librarianId: librarianId,
              librarianName:
                  librarianName,
            ),
          ),
        );
      } else {
        setState(() {
          errorMessage =
              data['message'] ??
              'Librarian not found.';
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
                'STAFF',
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
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Enter your staff ID to continue.',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            Color(0xFF777777),
                      ),
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      'Librarian ID',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller:
                          librarianController,
                      enabled: !isLoading,
                      textCapitalization:
                          TextCapitalization
                              .characters,
                      onSubmitted: (_) {
                        if (!isLoading) {
                          continueToStaffApp();
                        }
                      },
                      decoration:
                          InputDecoration(
                        hintText:
                            'e.g. LIB001',
                        prefixIcon:
                            const Icon(
                          Icons.badge_outlined,
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

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(
                                12),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                                  0xFFFFECE8),
                          borderRadius:
                              BorderRadius
                                  .circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 20,
                              color:
                                  Color(
                                      0xFFA94B3F),
                            ),

                            const SizedBox(
                                width: 9),

                            Expanded(
                              child: Text(
                                errorMessage,
                                style:
                                    const TextStyle(
                                  color:
                                      Color(
                                          0xFF8A3D35),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                                : continueToStaffApp,
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
// STAFF HOME PAGE
// =====================================================

class StaffHomePage extends StatefulWidget {
  final String librarianId;
  final String librarianName;

  const StaffHomePage({
    super.key,
    required this.librarianId,
    required this.librarianName,
  });

  @override
  State<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends State<StaffHomePage> {
  bool isActivityLoading = true;
  List<dynamic> activities = [];

  @override
  void initState() {
    super.initState();
    activityRefreshNotifier.addListener(_refreshActivity);
    loadActivity();
  }

  @override
  void dispose() {
    activityRefreshNotifier.removeListener(_refreshActivity);
    super.dispose();
  }

  void _refreshActivity() {
    loadActivity();
  }

  Future<void> loadActivity() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/librarians/${widget.librarianId}/activity'),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() {
        activities = data['success'] == true ? (data['activities'] ?? []) : [];
        isActivityLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => isActivityLoading = false);
    }
  }

  String timeAgo(dynamic value) {
    if (value == null) return '';
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F1),
        title: const Text('ReadSpace Staff', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadActivity,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEAF1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  const Icon(Icons.badge_outlined, color: Color(0xFF315F75)),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Signed in as', style: TextStyle(fontSize: 12, color: Color(0xFF607D8B))),
                    Text(widget.librarianName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(widget.librarianId, style: const TextStyle(fontSize: 12, color: Color(0xFF607D8B))),
                  ]),
                ]),
              ),
              const SizedBox(height: 28),
              const Text('Library Actions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: _ActionCard(
                  icon: Icons.library_add_outlined,
                  title: 'Issue Book',
                  subtitle: 'Issue a book to a student',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IssueBookPage(librarianId: widget.librarianId))),
                )),
                const SizedBox(width: 14),
                Expanded(child: _ActionCard(
                  icon: Icons.assignment_return_outlined,
                  title: 'Return Book',
                  subtitle: 'Return an issued book',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReturnBookPage(librarianId: widget.librarianId))),
                )),
              ]),
              const SizedBox(height: 14),
              _ActionCard(
                icon: Icons.qr_code_scanner_outlined,
                title: 'Scan Book',
                subtitle: 'Scan barcode or accession number',
                onTap: () async {
                  final result = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const BookScannerPage()));
                  if (!mounted || result == null || result.isEmpty) return;
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailsPage(code: result, librarianId: widget.librarianId)));
                },
              ),
              const SizedBox(height: 14),
              _ActionCard(
                icon: Icons.menu_book_outlined,
                title: 'Active Loans',
                subtitle: 'View currently issued books',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveLoansPage())),
              ),
              const SizedBox(height: 28),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Recent Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                TextButton.icon(onPressed: loadActivity, icon: const Icon(Icons.refresh, size: 18), label: const Text('Refresh')),
              ]),
              const SizedBox(height: 8),
              if (isActivityLoading)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else if (activities.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8E4DC))),
                  child: const Text('No recent activity yet.', style: TextStyle(color: Color(0xFF777777))),
                )
              else
                ...activities.take(5).map((item) {
                  final returned = item['type'] == 'returned';
                  final accession = item['accession_number']?.toString() ?? '-';
                  final studentId = item['student_id']?.toString() ?? '-';
                  final title = item['book_title']?.toString() ?? accession;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8E4DC))),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: const Color(0xFFE5F3EA), borderRadius: BorderRadius.circular(12)),
                        child: Icon(returned ? Icons.assignment_return_outlined : Icons.library_add_outlined, color: const Color(0xFF407A58), size: 21),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(returned ? 'Book Returned' : 'Book Issued', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 3),
                        Text(returned ? '$accession • $title' : '$accession → $studentId', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                      ])),
                      const SizedBox(width: 8),
                      Text(timeAgo(item['created_at']), style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                    ]),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// ISSUE BOOK PAGE
// =====================================================

class IssueBookPage extends StatefulWidget {
  final String librarianId;
  final String? initialAccession;

  const IssueBookPage({
    super.key,
    required this.librarianId,
    this.initialAccession,
  });

  @override
  State<IssueBookPage> createState() =>
      _IssueBookPageState();
}

class _IssueBookPageState extends State<IssueBookPage> {
  final TextEditingController studentController =
      TextEditingController();

  final TextEditingController accessionController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.initialAccession != null) {
      accessionController.text =
          widget.initialAccession!;
    }
  }

  bool isLoading = false;
  String message = '';
  bool success = false;

  bool studentLoading = false;
  String studentLookupMessage = '';
  Map<String, dynamic>? verifiedStudent;
  int activeStudentLoans = 0;

  @override
  void dispose() {
    studentController.dispose();
    accessionController.dispose();
    super.dispose();
  }

  Future<void> lookupStudent() async {
    final studentId =
        studentController.text.trim().toUpperCase();

    if (studentId.isEmpty) {
      setState(() {
        verifiedStudent = null;
        activeStudentLoans = 0;
        studentLookupMessage =
            'Enter a Student ID first.';
      });
      return;
    }

    setState(() {
      studentLoading = true;
      studentLookupMessage = '';
      verifiedStudent = null;
      activeStudentLoans = 0;
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
        setState(() {
          verifiedStudent =
              Map<String, dynamic>.from(
            data['student'],
          );

          activeStudentLoans =
              data['active_loans_count'] ?? 0;

          studentLookupMessage = '';
        });
      } else {
        setState(() {
          verifiedStudent = null;
          activeStudentLoans = 0;
          studentLookupMessage =
              data['message'] ??
              'Student not found.';
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        verifiedStudent = null;
        activeStudentLoans = 0;
        studentLookupMessage =
            'Could not verify student.';
      });
    } finally {
      if (mounted) {
        setState(() {
          studentLoading = false;
        });
      }
    }
  }

  Future<void> issueBook() async {
    final studentId =
        studentController.text.trim().toUpperCase();

    final accessionNumber =
        accessionController.text.trim().toUpperCase();

    if (studentId.isEmpty ||
        accessionNumber.isEmpty) {
      setState(() {
        success = false;
        message =
            'Please enter Student ID and Accession Number.';
      });

      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final response = await http.post(
        Uri.parse(
          '$apiBaseUrl/issue-book',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'student_id': studentId,
          'accession_number': accessionNumber,
          'librarian_id': widget.librarianId,
        }),
      ).timeout(
        const Duration(seconds: 10),
      );

      final data = jsonDecode(response.body);

      if (!mounted) {
        return;
      }

      if (data['success'] == true) {
        final dueDate = data['due_date'];
        final dueText = formatDate(dueDate);

        studentController.clear();
        accessionController.clear();

        if (!mounted) {
          return;
        }

        final messenger =
            ScaffoldMessenger.of(context);

        activityRefreshNotifier.value++;

        Navigator.of(context).popUntil(
          (route) => route.isFirst,
        );

        messenger.clearSnackBars();

        messenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                const Color(0xFF407A58),
            duration:
                const Duration(seconds: 3),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Book issued successfully • Due $dueText',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        return;
      } else {
        setState(() {
          success = false;
          message =
              data['message'] ??
              'Could not issue book.';
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        success = false;
        message =
            'Could not connect to ReadSpace server.\n'
            '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    try {
      final date = DateTime.parse(
        value.toString(),
      );

      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F1),
        title: const Text(
          'Issue Book',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEAF1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      color: Color(0xFF315F75),
                    ),

                    const SizedBox(width: 12),

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Issuing as',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF607D8B),
                          ),
                        ),

                        Text(
                          widget.librarianId,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              const Text(
                'Issue Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'Enter the student and physical book details.',
                style: TextStyle(
                  color: Color(0xFF777777),
                ),
              ),

              const SizedBox(height: 26),

              const Text(
                'Student ID',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: studentController,
                textCapitalization:
                    TextCapitalization.characters,
                onChanged: (_) {
                  if (verifiedStudent != null ||
                      studentLookupMessage.isNotEmpty) {
                    setState(() {
                      verifiedStudent = null;
                      activeStudentLoans = 0;
                      studentLookupMessage = '';
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'e.g. BCA002',
                  prefixIcon: const Icon(
                    Icons.person_outline,
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Verify Student',
                    onPressed:
                        studentLoading
                            ? null
                            : lookupStudent,
                    icon: studentLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons
                                .verified_user_outlined,
                          ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      studentLoading
                          ? null
                          : lookupStudent,
                  icon: const Icon(
                    Icons.search,
                  ),
                  label: Text(
                    studentLoading
                        ? 'Checking Student...'
                        : 'Verify Student',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(0xFF315F75),
                    side: const BorderSide(
                      color:
                          Color(0xFFB9D8EB),
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                  ),
                ),
              ),

              if (verifiedStudent != null) ...[
                const SizedBox(height: 14),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFE5F3EA),
                    borderRadius:
                        BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          const Color(0xFFCDE5D6),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                                  12),
                        ),
                        child: const Icon(
                          Icons
                              .check_circle_outline,
                          color:
                              Color(0xFF407A58),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              verifiedStudent?[
                                          'name']
                                      ?.toString() ??
                                  'Student',
                              style:
                                  const TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w700,
                                color:
                                    Color(0xFF315F42),
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              [
                                verifiedStudent?[
                                        'course'],
                                verifiedStudent?[
                                        'year'],
                                verifiedStudent?[
                                        'division'],
                              ]
                                  .where(
                                    (value) =>
                                        value != null &&
                                        value
                                            .toString()
                                            .trim()
                                            .isNotEmpty,
                                  )
                                  .join(' • '),
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                color:
                                    Color(0xFF52705D),
                              ),
                            ),

                            const SizedBox(height: 7),

                            Text(
                              '$activeStudentLoans active loan${activeStudentLoans == 1 ? '' : 's'}',
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    Color(0xFF407A58),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (studentLookupMessage
                  .isNotEmpty) ...[
                const SizedBox(height: 12),

                Container(
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
                          studentLookupMessage,
                          style:
                              const TextStyle(
                            fontSize: 12,
                            color:
                                Color(0xFF8A3D35),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              const Text(
                'Accession Number',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: accessionController,
                textCapitalization:
                    TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g. ACC007',
                  prefixIcon: const Icon(
                    Icons.menu_book_outlined,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () async {
                      final result =
                          await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const BookScannerPage(),
                        ),
                      );

                      if (!mounted ||
                          result == null ||
                          result.isEmpty) {
                        return;
                      }

                      setState(() {
                        accessionController.text =
                            result
                                .trim()
                                .toUpperCase();
                      });
                    },
                    icon: const Icon(
                      Icons.qr_code_scanner,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed:
                      isLoading ? null : issueBook,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_outline,
                        ),
                  label: Text(
                    isLoading
                        ? 'Issuing...'
                        : 'Confirm Issue',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF5E8FA6),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              if (message.isNotEmpty) ...[
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: success
                        ? const Color(0xFFE5F3EA)
                        : const Color(0xFFFFECE8),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        success
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: success
                            ? const Color(0xFF407A58)
                            : const Color(0xFFA94B3F),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            color: success
                                ? const Color(
                                    0xFF315F42)
                                : const Color(
                                    0xFF8A3D35),
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
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
// RETURN BOOK PAGE
// =====================================================

class ReturnBookPage extends StatefulWidget {
  final String librarianId;
  final String? initialAccession;

  const ReturnBookPage({
    super.key,
    required this.librarianId,
    this.initialAccession,
  });

  @override
  State<ReturnBookPage> createState() =>
      _ReturnBookPageState();
}

class _ReturnBookPageState
    extends State<ReturnBookPage> {
  final TextEditingController accessionController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.initialAccession != null) {
      accessionController.text =
          widget.initialAccession!;
    }
  }

  bool isLoading = false;
  bool success = false;
  String message = '';

  @override
  void dispose() {
    accessionController.dispose();
    super.dispose();
  }

  Future<void> returnBook() async {
    final accessionNumber =
        accessionController.text.trim().toUpperCase();

    if (accessionNumber.isEmpty) {
      setState(() {
        success = false;
        message = 'Please enter the Accession Number.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/return-book'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'accession_number': accessionNumber,
          'librarian_id': widget.librarianId,
        }),
      ).timeout(
        const Duration(seconds: 10),
      );

      final data = jsonDecode(response.body);

      if (!mounted) {
        return;
      }

      if (data['success'] == true) {
        final lateDays =
            data['late_days'] ?? 0;
        final fineAmount =
            data['fine_amount'] ?? 0;

        accessionController.clear();

        if (!mounted) {
          return;
        }

        final messenger =
            ScaffoldMessenger.of(context);

        activityRefreshNotifier.value++;

        Navigator.of(context).popUntil(
          (route) => route.isFirst,
        );

        messenger.clearSnackBars();

        messenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                const Color(0xFF407A58),
            duration:
                const Duration(seconds: 3),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fineAmount > 0
                        ? 'Book returned successfully • Fine ₹$fineAmount • $lateDays late day${lateDays == 1 ? '' : 's'}'
                        : 'Book returned successfully • No fine',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        return;
      } else {
        setState(() {
          success = false;
          message =
              data['message'] ?? 'Could not return book.';
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        success = false;
        message =
            'Could not connect to ReadSpace server.\n'
            '$error';
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F1),
        title: const Text(
          'Return Book',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEAF1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      color: Color(0xFF315F75),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Returning as',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF607D8B),
                          ),
                        ),
                        Text(
                          widget.librarianId,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Return Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Enter the accession number of the issued book.',
                style: TextStyle(
                  color: Color(0xFF777777),
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Accession Number',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: accessionController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g. ACC005',
                  prefixIcon: const Icon(
                    Icons.menu_book_outlined,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () async {
                      final result =
                          await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const BookScannerPage(),
                        ),
                      );

                      if (!mounted ||
                          result == null ||
                          result.isEmpty) {
                        return;
                      }

                      setState(() {
                        accessionController.text =
                            result
                                .trim()
                                .toUpperCase();
                      });
                    },
                    icon: const Icon(
                      Icons.qr_code_scanner,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : returnBook,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.assignment_return_outlined,
                        ),
                  label: Text(
                    isLoading
                        ? 'Returning...'
                        : 'Confirm Return',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5E8FA6),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: success
                        ? const Color(0xFFE5F3EA)
                        : const Color(0xFFFFECE8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        success
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: success
                            ? const Color(0xFF407A58)
                            : const Color(0xFFA94B3F),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            color: success
                                ? const Color(0xFF315F42)
                                : const Color(0xFF8A3D35),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
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
// BOOK DETAILS PAGE
// =====================================================

class BookDetailsPage extends StatefulWidget {
  final String code;
  final String librarianId;

  const BookDetailsPage({
    super.key,
    required this.code,
    required this.librarianId,
  });

  @override
  State<BookDetailsPage> createState() =>
      _BookDetailsPageState();
}

class _BookDetailsPageState
    extends State<BookDetailsPage> {
  bool isLoading = true;
  String errorMessage = '';

  Map<String, dynamic>? bookCopy;
  Map<String, dynamic>? activeLoan;

  @override
  void initState() {
    super.initState();
    loadBook();
  }

  Future<void> loadBook() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              '$apiBaseUrl/books/lookup/${Uri.encodeComponent(widget.code)}',
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
          bookCopy =
              Map<String, dynamic>.from(
            data['book_copy'],
          );

          if (data['active_loan'] != null) {
            activeLoan =
                Map<String, dynamic>.from(
              data['active_loan'],
            );
          } else {
            activeLoan = null;
          }
        });
      } else {
        setState(() {
          errorMessage =
              data['message'] ??
              'Book not found.';
        });
      }
    } catch (error) {
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

  @override
  Widget build(BuildContext context) {
    final book =
        bookCopy?['books'];

    final status =
        bookCopy?['status']
                ?.toString()
                .toLowerCase() ??
            '';

    final isAvailable =
        status == 'available';

    final isIssued =
        status == 'issued';

    final accession =
        bookCopy?['accession_number']
                ?.toString() ??
            '-';

    final barcode =
        bookCopy?['barcode']
                ?.toString() ??
            '-';

    final student =
        activeLoan?['students'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF8F6F1),
        surfaceTintColor:
            const Color(0xFFF8F6F1),
        title: const Text(
          'Book Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed:
                isLoading
                    ? null
                    : loadBook,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: SafeArea(
        child: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                              24),
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 52,
                            color:
                                Color(0xFFA94B3F),
                          ),

                          const SizedBox(
                              height: 14),

                          Text(
                            errorMessage,
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              fontSize: 15,
                              color:
                                  Color(
                                      0xFF8A3D35),
                            ),
                          ),

                          const SizedBox(
                              height: 18),

                          FilledButton(
                            onPressed:
                                loadBook,
                            child:
                                const Text(
                              'Retry',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding:
                        const EdgeInsets.all(
                            20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(20),
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        20),
                            border:
                                Border.all(
                              color:
                                  const Color(
                                      0xFFE8E4DC),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                          0xFFDCEAF1),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              16),
                                ),
                                child:
                                    const Icon(
                                  Icons
                                      .menu_book_outlined,
                                  size: 28,
                                  color:
                                      Color(
                                          0xFF315F75),
                                ),
                              ),

                              const SizedBox(
                                  width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      book?['title']
                                              ?.toString() ??
                                          'Unknown Book',
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            20,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                        color:
                                            Color(
                                                0xFF202020),
                                      ),
                                    ),

                                    const SizedBox(
                                        height: 5),

                                    Text(
                                      book?['author']
                                              ?.toString() ??
                                          '-',
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            13,
                                        color:
                                            Color(
                                                0xFF777777),
                                      ),
                                    ),

                                    const SizedBox(
                                        height: 12),

                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal:
                                            11,
                                        vertical: 6,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            isAvailable
                                                ? const Color(
                                                    0xFFE5F3EA)
                                                : isIssued
                                                    ? const Color(
                                                        0xFFFFECE8)
                                                    : const Color(
                                                        0xFFF2F0EA),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                                    20),
                                      ),
                                      child: Text(
                                        status
                                            .toUpperCase(),
                                        style:
                                            TextStyle(
                                          fontSize:
                                              10,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                          letterSpacing:
                                              .6,
                                          color:
                                              isAvailable
                                                  ? const Color(
                                                      0xFF407A58)
                                                  : isIssued
                                                      ? const Color(
                                                          0xFFA94B3F)
                                                      : const Color(
                                                          0xFF666666),
                                        ),
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
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(18),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                                    0xFFFAF9F6),
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        18),
                          ),
                          child: Column(
                            children: [
                              _BookDetailRow(
                                label:
                                    'Accession',
                                value:
                                    accession,
                              ),

                              const SizedBox(
                                  height: 12),

                              _BookDetailRow(
                                label:
                                    'Barcode',
                                value:
                                    barcode,
                              ),

                              const SizedBox(
                                  height: 12),

                              _BookDetailRow(
                                label:
                                    'Category',
                                value:
                                    book?['category']
                                            ?.toString() ??
                                        '-',
                              ),

                              const SizedBox(
                                  height: 12),

                              _BookDetailRow(
                                label:
                                    'ISBN',
                                value:
                                    book?['isbn']
                                            ?.toString() ??
                                        '-',
                              ),
                            ],
                          ),
                        ),

                        if (isIssued &&
                            activeLoan != null) ...[
                          const SizedBox(
                              height: 18),

                          const Text(
                            'Current Loan',
                            style:
                                TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),

                          const SizedBox(
                              height: 12),

                          Container(
                            width:
                                double.infinity,
                            padding:
                                const EdgeInsets
                                    .all(18),
                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                      0xFFFFF7F5),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          18),
                              border:
                                  Border.all(
                                color:
                                    const Color(
                                        0xFFF1D8D2),
                              ),
                            ),
                            child: Column(
                              children: [
                                _BookDetailRow(
                                  label:
                                      'Student',
                                  value:
                                      '${student?['name'] ?? '-'}',
                                ),

                                const SizedBox(
                                    height: 12),

                                _BookDetailRow(
                                  label:
                                      'Student ID',
                                  value:
                                      '${student?['student_id'] ?? '-'}',
                                ),

                                const SizedBox(
                                    height: 12),

                                _BookDetailRow(
                                  label:
                                      'Issued',
                                  value:
                                      formatDate(
                                    activeLoan?[
                                        'issue_date'],
                                  ),
                                ),

                                const SizedBox(
                                    height: 12),

                                _BookDetailRow(
                                  label:
                                      'Due',
                                  value:
                                      formatDate(
                                    activeLoan?[
                                        'due_date'],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        if (isAvailable)
                          SizedBox(
                            width:
                                double.infinity,
                            height: 54,
                            child:
                                FilledButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            IssueBookPage(
                                      librarianId:
                                          widget
                                              .librarianId,
                                      initialAccession:
                                          accession,
                                    ),
                                  ),
                                );
                              },
                              icon:
                                  const Icon(
                                Icons
                                    .library_add_outlined,
                              ),
                              label:
                                  const Text(
                                'Issue This Book',
                              ),
                              style:
                                  FilledButton
                                      .styleFrom(
                                backgroundColor:
                                    const Color(
                                        0xFF5E8FA6),
                                foregroundColor:
                                    Colors.white,
                              ),
                            ),
                          ),

                        if (isIssued)
                          SizedBox(
                            width:
                                double.infinity,
                            height: 54,
                            child:
                                FilledButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            ReturnBookPage(
                                      librarianId:
                                          widget
                                              .librarianId,
                                      initialAccession:
                                          accession,
                                    ),
                                  ),
                                );
                              },
                              icon:
                                  const Icon(
                                Icons
                                    .assignment_return_outlined,
                              ),
                              label:
                                  const Text(
                                'Return This Book',
                              ),
                              style:
                                  FilledButton
                                      .styleFrom(
                                backgroundColor:
                                    const Color(
                                        0xFF5E8FA6),
                                foregroundColor:
                                    Colors.white,
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


class _BookDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _BookDetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color:
                  Color(0xFF888888),
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }
}


// =====================================================
// BOOK SCANNER PAGE
// =====================================================

class BookScannerPage extends StatefulWidget {
  const BookScannerPage({super.key});

  @override
  State<BookScannerPage> createState() =>
      _BookScannerPageState();
}

class _BookScannerPageState
    extends State<BookScannerPage> {
  final MobileScannerController scannerController =
      MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool hasScanned = false;

  final TextEditingController manualCodeController =
      TextEditingController();

  @override
  void dispose() {
    scannerController.dispose();
    manualCodeController.dispose();
    super.dispose();
  }

  void handleDetection(
    BarcodeCapture capture,
  ) {
    if (hasScanned ||
        capture.barcodes.isEmpty) {
      return;
    }

    final value =
        capture.barcodes.first.rawValue;

    if (value == null ||
        value.trim().isEmpty) {
      return;
    }

    hasScanned = true;

    Navigator.pop(
      context,
      value.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF111416),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF111416),
        foregroundColor: Colors.white,
        surfaceTintColor:
            const Color(0xFF111416),
        title: const Text(
          'Scan Book',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Flash',
            onPressed: () {
              scannerController.toggleTorch();
            },
            icon: const Icon(
              Icons.flash_on_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Switch camera',
            onPressed: () {
              scannerController.switchCamera();
            },
            icon: const Icon(
              Icons.cameraswitch_outlined,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: handleDetection,
          ),

          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(
                      alpha: 0.52,
                    ),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(
                      alpha: 0.58,
                    ),
                  ],
                  stops: const [
                    0,
                    0.28,
                    0.72,
                    1,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 34),

                  const Text(
                    'Point the camera at the book barcode',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Keep the code inside the frame until it scans.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFD6D6D6),
                      fontSize: 12,
                    ),
                  ),

                  const Spacer(),

                  Container(
                    width: 275,
                    height: 185,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),

                  const Spacer(),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'The scanned value will be filled automatically.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Testing on emulator?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                Color(0xFF202020),
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'Enter the book code manually.',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Color(0xFF777777),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller:
                              manualCodeController,
                          textCapitalization:
                              TextCapitalization
                                  .characters,
                          decoration:
                              InputDecoration(
                            hintText:
                                'e.g. ACC005',
                            prefixIcon:
                                const Icon(
                              Icons
                                  .keyboard_outlined,
                            ),
                            filled: true,
                            fillColor:
                                const Color(
                                    0xFFFAF9F6),
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width:
                              double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              final code =
                                  manualCodeController
                                      .text
                                      .trim()
                                      .toUpperCase();

                              if (code.isEmpty) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Enter a code first',
                                    ),
                                  ),
                                );

                                return;
                              }

                              Navigator.pop(
                                context,
                                code,
                              );
                            },
                            style:
                                FilledButton
                                    .styleFrom(
                              backgroundColor:
                                  const Color(
                                      0xFF5E8FA6),
                              foregroundColor:
                                  Colors.white,
                            ),
                            child: const Text(
                              'Use This Code',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// =====================================================
// ACTIVE LOANS PAGE
// =====================================================

class ActiveLoansPage extends StatefulWidget {
  const ActiveLoansPage({super.key});

  @override
  State<ActiveLoansPage> createState() =>
      _ActiveLoansPageState();
}

class _ActiveLoansPageState
    extends State<ActiveLoansPage> {
  bool isLoading = true;
  String errorMessage = '';
  List<dynamic> loans = [];
  String searchText = '';

  @override
  void initState() {
    super.initState();
    loadActiveLoans();
  }

  Future<void> loadActiveLoans() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              '$apiBaseUrl/loans/active',
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
          loans = data['loans'] ?? [];
          errorMessage = '';
        });
      } else {
        setState(() {
          loans = [];
          errorMessage =
              data['message'] ??
              'Could not load active loans.';
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        loans = [];
        errorMessage =
            'Could not connect to ReadSpace server.\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<dynamic> get filteredLoans {
    final term =
        searchText.trim().toLowerCase();

    if (term.isEmpty) {
      return loans;
    }

    return loans.where((loan) {
      final studentName =
          (loan['students']?['name'] ?? '')
              .toString()
              .toLowerCase();

      final studentId =
          (loan['students']?['student_id'] ?? '')
              .toString()
              .toLowerCase();

      final bookTitle =
          (loan['book_copies']?['books']?['title'] ?? '')
              .toString()
              .toLowerCase();

      final accession =
          (loan['book_copies']?['accession_number'] ?? '')
              .toString()
              .toLowerCase();

      final librarian =
          (loan['librarians']?['name'] ?? '')
              .toString()
              .toLowerCase();

      return studentName.contains(term) ||
          studentId.contains(term) ||
          bookTitle.contains(term) ||
          accession.contains(term) ||
          librarian.contains(term);
    }).toList();
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

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 48,
          horizontal: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFDCEAF1),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                size: 32,
                color: Color(0xFF315F75),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No active loans',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202020),
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Issued books will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLoanCard(dynamic loan) {
    final student = loan['students'];
    final copy = loan['book_copies'];
    final book = copy?['books'];
    final librarian = loan['librarians'];

    final title =
        book?['title']?.toString() ??
        'Unknown Book';

    final author =
        book?['author']?.toString() ?? '-';

    final accession =
        copy?['accession_number']
                ?.toString() ??
            '-';

    final studentName =
        student?['name']?.toString() ??
        'Unknown Student';

    final studentId =
        student?['student_id']
                ?.toString() ??
            '-';

    final librarianName =
        librarian?['name']?.toString() ??
        '-';

    final dueDate =
        formatDate(loan['due_date']);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8E4DC),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFDCEAF1),
                  borderRadius:
                      BorderRadius.circular(13),
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
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(0xFF202020),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      author,
                      style: const TextStyle(
                        fontSize: 12,
                        color:
                            Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFECE8),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: const Text(
                  'ISSUED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing: .7,
                    color:
                        Color(0xFFA94B3F),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F6),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _LoanInfoRow(
                  label: 'Student',
                  value:
                      '$studentName  •  $studentId',
                ),

                const SizedBox(height: 10),

                _LoanInfoRow(
                  label: 'Accession',
                  value: accession,
                ),

                const SizedBox(height: 10),

                _LoanInfoRow(
                  label: 'Due Date',
                  value: dueDate,
                ),

                const SizedBox(height: 10),

                _LoanInfoRow(
                  label: 'Issued By',
                  value: librarianName,
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
    final visibleLoans = filteredLoans;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF8F6F1),
        surfaceTintColor:
            const Color(0xFFF8F6F1),
        title: const Text(
          'Active Loans',
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
                    : loadActiveLoans,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadActiveLoans,
          child: ListView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              28,
            ),
            children: [
              Container(
                padding:
                    const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFDCEAF1),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                                14),
                      ),
                      child: const Icon(
                        Icons
                            .assignment_outlined,
                        color:
                            Color(0xFF315F75),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Currently Issued',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Color(0xFF607D8B),
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            isLoading
                                ? 'Loading...'
                                : '${loans.length} active loan${loans.length == 1 ? '' : 's'}',
                            style:
                                const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.w700,
                              color:
                                  Color(0xFF234E62),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText:
                      'Search book, student or accession...',
                  prefixIcon: const Icon(
                    Icons.search,
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
                          Color(0xFFE8E4DC),
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
              else if (errorMessage.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.all(
                          18),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(0xFFFFECE8),
                    borderRadius:
                        BorderRadius.circular(
                            16),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color:
                                Color(0xFFA94B3F),
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Could not load loans',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                              color:
                                  Color(0xFF8A3D35),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 9),

                      Text(
                        errorMessage,
                        style: const TextStyle(
                          fontSize: 12,
                          color:
                              Color(0xFF8A3D35),
                        ),
                      ),

                      const SizedBox(height: 14),

                      FilledButton(
                        onPressed:
                            loadActiveLoans,
                        child:
                            const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (loans.isEmpty)
                buildEmptyState()
              else if (visibleLoans.isEmpty)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 40,
                  ),
                  child: Center(
                    child: Text(
                      'No matching active loans found.',
                      style: TextStyle(
                        color:
                            Color(0xFF777777),
                      ),
                    ),
                  ),
                )
              else
                ...visibleLoans.map(
                  buildLoanCard,
                ),
            ],
          ),
        ),
      ),
    );
  }
}


class _LoanInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _LoanInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color:
                  Color(0xFF888888),
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }
}


// =====================================================
// ACTION CARD
// =====================================================

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE8E4DC),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEAF1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF315F75),
                ),
              ),

              const SizedBox(height: 15),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}