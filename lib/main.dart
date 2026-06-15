
import 'dart:async';
import 'package:aplikasi_alarm/alarm_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:alarm/alarm.dart';
import 'splash_screen.dart';
import 'alarm_alert_screen.dart';
import 'firebase_options.dart';

Future<void> isi100KataKerjaBahasaIndonesia() async {
  final CollectionReference wordsCollection =
      FirebaseFirestore.instance.collection('words_collection');

  List<String> daftarKataKerja = [
    "BACA", "BAWA", "BELI", "CARI", "CUCI", "DENGAR", "DUDUK", "FOKUS", "GILING", "HITUNG",
    "IKUT", "JUAL", "JAGA", "LIHAT", "MAKAN", "MINUM", "MASAK", "MAIN", "MANDI", "NAIK",
    "NYALA", "OBAT", "PAHAM", "PERGI", "PILIH", "PULANG", "RABA", "REKAM", "SALIN", "SAPA",
    "TAHU", "TARIK", "TULIS", "TUNGGU", "UKUR", "ULANG", "UJI", "VALIDASI", "YAKIN", "ZIKIR",
    "BANGUN", "BELAJAR", "BERJALAN", "BEKERJA", "BERNYANYI", "BERBICARA", "BERMAIN", "BERDIRI",
    "BERLARI", "LOMPAT", "MEMBACA", "MENULIS", "MENDENGAR", "MELIHAT", "MEMASAK", "MEMBELI",
    "MEMBAWA", "MENCARI", "MENCUCI", "MENJUAL", "MENJAGA", "MEMILIH", "MENUNGGU", "MENGHITUNG",
    "MEMAHAMI", "MENYALAKAN", "MENYALIN", "MENYAPA", "MENARIK", "MENGUKUR", "MENGULANG", "MENGUJI",
    "MEMBANTU", "MEMBUAT", "MEMBUKA", "MENUTUP", "MEMAKAI", "MEMBUANG", "MENGAMBIL", "MEMBERI",
    "MENERIMA", "MEMINJAM", "MENGIRIM", "MENYIMPAN", "MEMERIKSA", "MEMPERBAIKI", "MEMASUKKAN",
    "MENGELUARKAN", "MEMBERSIHKAN", "MENYAPU", "MENYELESAIKAN", "MEMIKIRKAN", "MEMUTUSKAN",
    "MENGINGAT", "MELAKUKAN", "MENUNJUKKAN", "MENGGUNAKAN", "MEMILIKI", "MENGHASILKAN",
    "MENGEMBANGKAN",
  ];

  try {
    var snapshot = await wordsCollection.limit(1).get();
    if (snapshot.docs.isEmpty) {
      print("Sedang memproses upload 100 kata kerja ke Firebase...");
      for (String kata in daftarKataKerja) {
        await wordsCollection.add({'word': kata.toUpperCase()});
      }
      print("100 Kata Kerja Berhasil Ditambahkan ke Firebase Console!");
    } else {
      print("Koleksi kata kerja sudah ada di Firestore.");
    }
  } catch (e) {
    print("Gagal memeriksa atau mengupload ke Firebase: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi package alarm (WAJIB sebelum set/listen alarm)
  await Alarm.init();

  await isi100KataKerjaBahasaIndonesia();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Inter'),
      home: const SplashScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedSound = 'sound1.mp3';
  bool isVibrate = true;
  int currentChallengeCount = 3;

  // Subscription ke stream alarm package
  StreamSubscription<AlarmSettings>? _alarmSubscription;

  // Guard: mencegah navigasi ganda ke AlarmAlertScreen
  bool _isHandlingAlarm = false;

  final CollectionReference _firestoreAlarms =
      FirebaseFirestore.instance.collection('alarms');

  @override
  void initState() {
    super.initState();
    _listenToAlarmRing();
  }

  @override
  void dispose() {
    _alarmSubscription?.cancel();
    super.dispose();
  }

  // ─── Listen ke package alarm: kapanpun alarm berbunyi, navigasi ke alert screen
  void _listenToAlarmRing() {
    // Cek apakah ada alarm yang sudah berbunyi saat app dibuka (cold start)
    _checkRingingOnStart();

    // Listen ke alarm yang masuk saat app sedang berjalan (foreground / background resume)
    _alarmSubscription = Alarm.ringStream.stream.listen((alarmSettings) {
      _handleAlarmTriggered(alarmSettings);
    });
  }

  Future<void> _checkRingingOnStart() async {
    // Kalau app dibuka karena alarm (full-screen intent), Alarm.getAlarms()
    // masih berisi alarm yang sedang berbunyi.
    final ringing = await Alarm.getAlarms(); // getAlarms() adalah Future
    if (ringing.isNotEmpty && !_isHandlingAlarm) {
      await Future.delayed(
          const Duration(milliseconds: 500)); // tunggu widget build
      if (mounted) {
        _handleAlarmTriggered(ringing.first);
      }
    }
  }

  Future<void> _handleAlarmTriggered(AlarmSettings alarmSettings) async {
    if (_isHandlingAlarm) return;
    if (!mounted) return;

    _isHandlingAlarm = true;

    // Ambil sound & jumlah misi dari SharedPreferences
    final soundFileName = await AlarmService.getSavedSound();
    final challengeCount = await AlarmService.getSavedChallengeCount();

    // Mulai getaran periodik (suara sudah diputar oleh package alarm)
    await AlarmService().startVibration();

    if (!mounted) {
      _isHandlingAlarm = false;
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmAlertScreen(
          selectedSound: soundFileName,
          targetMisi: challengeCount,
          alarmId: alarmSettings.id,
        ),
      ),
    );

    _isHandlingAlarm = false;
  }

  Stream<DateTime> _clockStream() {
    return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  }

  void _navigateToEditAlarm(
      {String? docId,
      String? initialTime,
      int? initialChallengeCount,
      String? initialSound}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAlarmScreen(
          initialTime: initialTime,
          isEdit: docId != null,
          initialChallengeCount: initialChallengeCount,
          initialSound: initialSound,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      try {
        if (docId != null) {
          await _firestoreAlarms.doc(docId).update(result);
        } else {
          await _firestoreAlarms.add(result);
        }
      } catch (e) {
        print("Gagal menyimpan data ke Firebase: $e");
      }
    }
  }

  void _showDeleteDialog(String docId, String timeString, int alarmId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF2DF),
        title: const Text("Hapus Alarm"),
        content: Text("Hapus alarm jam $timeString?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await AlarmService.cancelAlarm(alarmId);
                await _firestoreAlarms.doc(docId).delete();
                if (!mounted) return;
                Navigator.pop(context);
              } catch (e) {
                print("Gagal menghapus alarm: $e");
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  int _timeStringToAlarmId(String timeString) {
    // "HH : mm" → id unik
    final parts = timeString.replaceAll(' ', '').split(':');
    if (parts.length == 2) {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBE7C6),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 25),
            StreamBuilder<DateTime>(
              stream: _clockStream(),
              builder: (context, snapshot) {
                final now = snapshot.data ?? DateTime.now();
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE07A5F),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    DateFormat('HH:mm').format(now),
                    style: const TextStyle(
                      fontSize: 65,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 25),
            const Padding(
              padding: EdgeInsets.only(left: 25),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Your Alarm!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreAlarms.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text("Terjadi kesalahan mengambil data."));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                        child: Text("Belum ada alarm yang dibuat."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var alarmDoc = docs[index];
                      String docId = alarmDoc.id;
                      Map<String, dynamic> alarm =
                          alarmDoc.data() as Map<String, dynamic>;
                      String timeString = alarm["time"] ?? "00 : 00";
                      int alarmId = _timeStringToAlarmId(timeString);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB4A7D6),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 5),
                          title: Text(
                            timeString,
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Misi: ${alarm["challengeCount"] ?? 3} Kata Kerja",
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                "Suara: ${alarm["sound"] == 'sound2.mp3' ? 'Sound 2' : 'Sound 1'}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          onTap: () => _navigateToEditAlarm(
                            docId: docId,
                            initialTime: alarm["time"],
                            initialChallengeCount: alarm["challengeCount"],
                            initialSound: alarm["sound"],
                          ),
                          onLongPress: () =>
                              _showDeleteDialog(docId, timeString, alarmId),
                          trailing: Switch(
                            value: alarm["isActive"] ?? false,
                            thumbColor:
                                WidgetStateProperty.all(Colors.white),
                            trackColor: WidgetStateProperty.resolveWith(
                              (states) =>
                                  states.contains(WidgetState.selected)
                                      ? const Color(0xFFE07A5F)
                                      : Colors.black26,
                            ),
                            onChanged: (val) async {
                              await _firestoreAlarms
                                  .doc(docId)
                                  .update({"isActive": val});

                              if (val) {
                                // Aktifkan alarm
                                final parts =
                                    timeString.replaceAll(' ', '').split(':');
                                if (parts.length == 2) {
                                  final hour = int.parse(parts[0]);
                                  final minute = int.parse(parts[1]);
                                  final now = DateTime.now();
                                  var alarmDateTime = DateTime(
                                      now.year, now.month, now.day, hour, minute);
                                  if (alarmDateTime.isBefore(now)) {
                                    alarmDateTime = alarmDateTime
                                        .add(const Duration(days: 1));
                                  }
                                  final sound =
                                      alarm["sound"] ?? "sound1.mp3";
                                  final count =
                                      alarm["challengeCount"] ?? 3;

                                  await AlarmService.scheduleAlarm(
                                    id: alarmId,
                                    dateTime: alarmDateTime,
                                    soundFileName: sound,
                                    challengeCount: count,
                                  );
                                }
                              } else {
                                // Matikan alarm
                                await AlarmService.cancelAlarm(alarmId);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: FloatingActionButton(
                backgroundColor: const Color(0xFFE07A5F),
                shape: const CircleBorder(),
                onPressed: () => _navigateToEditAlarm(),
                child: const Icon(Icons.add, size: 35, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AddAlarmScreen
// ─────────────────────────────────────────────────────────────────────────────

class AddAlarmScreen extends StatefulWidget {
  final String? initialTime;
  final bool isEdit;
  final int? initialChallengeCount;
  final String? initialSound;

  const AddAlarmScreen({
    super.key,
    this.initialTime,
    this.isEdit = false,
    this.initialChallengeCount,
    this.initialSound,
  });

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  late TimeOfDay selectedTime;
  String selectedSound = 'sound1.mp3';
  bool isVibrate = true;
  String selectedRepeat = "Never";
  int selectedChallengeCount = 3;

  @override
  void initState() {
    super.initState();
    selectedChallengeCount = widget.initialChallengeCount ?? 3;
    selectedSound = widget.initialSound ?? 'sound1.mp3';
    if (widget.initialTime != null) {
      final parts = widget.initialTime!.replaceAll(' ', '').split(':');
      selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else {
      selectedTime = TimeOfDay.now();
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme:
                const ColorScheme.light(primary: Color(0xFFE07A5F)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime =
        "${selectedTime.hour.toString().padLeft(2, '0')} : ${selectedTime.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: const Color(0xFFFFF2DF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEdit ? "Edit Alarm" : "Add Alarm",
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE07A5F),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5)),
                ],
              ),
              child: Center(
                child: Column(
                  children: [
                    const Text("Set Alarm Time",
                        style:
                            TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 55,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                ListTile(
                  leading: const Icon(Icons.access_time_rounded,
                      color: Color(0xFFB4A7D6)),
                  title: const Text("Repeat",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(selectedRepeat),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: _showRepeatDialog,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.volume_up_rounded,
                      color: Color(0xFFB4A7D6)),
                  title: const Text("Sound",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      selectedSound == 'sound1.mp3' ? "Sound 1" : "Sound 2"),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: _showSoundDialog,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.vibration_rounded,
                      color: Color(0xFFB4A7D6)),
                  title: const Text("Vibrate",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Switch(
                    value: isVibrate,
                    activeColor: const Color(0xFFE07A5F),
                    onChanged: (val) => setState(() => isVibrate = val),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.extension_rounded,
                      color: Color(0xFFB4A7D6)),
                  title: const Text("Challenge",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "Word Scramble ($selectedChallengeCount Misi)"),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: _showChallengeDialog,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE07A5F),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  var alarmDateTime = DateTime(
                    now.year, now.month, now.day,
                    selectedTime.hour, selectedTime.minute,
                  );
                  if (alarmDateTime.isBefore(now)) {
                    alarmDateTime =
                        alarmDateTime.add(const Duration(days: 1));
                  }

                  int alarmId =
                      selectedTime.hour * 60 + selectedTime.minute;

                  // Jadwalkan alarm via package alarm
                  await AlarmService.scheduleAlarm(
                    id: alarmId,
                    dateTime: alarmDateTime,
                    soundFileName: selectedSound,
                    challengeCount: selectedChallengeCount,
                  );

                  if (!mounted) return;
                  Navigator.pop(context, {
                    "time": formattedTime,
                    "isActive": true,
                    "challengeCount": selectedChallengeCount,
                    "sound": selectedSound,
                  });
                },
                child: const Text(
                  "SAVE ALARM",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRepeatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF2DF),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text("Select Repeat",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text("Never"),
              value: 'Never',
              groupValue: selectedRepeat,
              activeColor: const Color(0xFFE07A5F),
              onChanged: (v) {
                setState(() => selectedRepeat = v!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text("Everyday"),
              value: 'Everyday',
              groupValue: selectedRepeat,
              activeColor: const Color(0xFFE07A5F),
              onChanged: (v) {
                setState(() => selectedRepeat = v!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF2DF),
        title: const Text("Select Sound"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text("Sound 1"),
              value: 'sound1.mp3',
              groupValue: selectedSound,
              activeColor: const Color(0xFFE07A5F),
              onChanged: (v) {
                setState(() => selectedSound = v!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text("Sound 2"),
              value: 'sound2.mp3',
              groupValue: selectedSound,
              activeColor: const Color(0xFFE07A5F),
              onChanged: (v) {
                setState(() => selectedSound = v!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChallengeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF2DF),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text("Jumlah Tantangan",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text("3 Misi"),
              value: 3,
              groupValue: selectedChallengeCount,
              activeColor: const Color(0xFFE07A5F),
              onChanged: (v) {
                setState(() => selectedChallengeCount = v!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<int>(
              title: const Text("5 Misi"),
              value: 5,
              groupValue: selectedChallengeCount,
              activeColor: const Color(0xFFE07A5F),
              onChanged: (v) {
                setState(() => selectedChallengeCount = v!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}