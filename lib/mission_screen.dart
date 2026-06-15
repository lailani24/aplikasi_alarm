import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'alarm_service.dart';

class MissionScreen extends StatefulWidget {
  final int targetMisi;
  final int alarmId; // Dibutuhkan untuk stop alarm package
  final bool launchedFromLockScreen; // Apakah dari lock screen

  const MissionScreen({
    super.key,
    required this.targetMisi,
    required this.alarmId,
    this.launchedFromLockScreen = false,
  });

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  final TextEditingController _jawabanController = TextEditingController();

  List<String> _poolKataKerja = [];
  String _kunciJawaban = "";
  String _hurufAcakTampilan = "";
  int _misiSelesai = 0;
  bool _isLoading = true;
  bool _isMisiSelesaiSemua = false;

  @override
  void initState() {
    super.initState();
    _ambilDataKataDariFirebase();
  }

  @override
  void dispose() {
    _jawabanController.dispose();
    super.dispose();
  }

  Future<void> _ambilDataKataDariFirebase() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('words_collection')
          .get();

      if (snapshot.docs.isNotEmpty) {
        List<String> listKata = snapshot.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['word']
                .toString()
                .toUpperCase())
            .toList();

        setState(() {
          _poolKataKerja = listKata;
          _isLoading = false;
        });
        _buatMisiBaru();
      } else {
        _gunakanKataCadanganLokal();
      }
    } catch (e) {
      _gunakanKataCadanganLokal();
    }
  }

  void _gunakanKataCadanganLokal() {
    setState(() {
      _poolKataKerja = ["BACA", "MAKAN", "MINUM", "BELAJAR", "TULIS", "MANDI"];
      _isLoading = false;
    });
    _buatMisiBaru();
  }

  void _buatMisiBaru() {
    if (_poolKataKerja.isEmpty) return;

    final random = Random();
    String kataTerpilih =
        _poolKataKerja[random.nextInt(_poolKataKerja.length)];
    List<String> hurufList = kataTerpilih.split('');

    int penunjukLoop = 0;
    while (hurufList.join('') == kataTerpilih &&
        hurufList.length > 1 &&
        penunjukLoop < 10) {
      hurufList.shuffle(random);
      penunjukLoop++;
    }

    setState(() {
      _kunciJawaban = kataTerpilih;
      _hurufAcakTampilan = hurufList.join('   ');
      _jawabanController.clear();
    });
  }

  void _cekJawaban() {
    if (_isMisiSelesaiSemua) return;

    String inputUser = _jawabanController.text.trim().toUpperCase();

    if (inputUser == _kunciJawaban) {
      final misiBaruSelesai = _misiSelesai + 1;
      setState(() {
        _misiSelesai = misiBaruSelesai;
      });

      if (misiBaruSelesai >= widget.targetMisi) {
        _isMisiSelesaiSemua = true;

        // ✅ Matikan alarm sepenuhnya: suara + getaran + package alarm
        AlarmService().stopAlarm(alarmId: widget.alarmId);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFFFFF2DF),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text("YEAYYY! 🎉",
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text(
                "Hebat! $misiBaruSelesai Misi selesai. Alarm berhasil dimatikan."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // tutup dialog
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  "Dismiss",
                  style: TextStyle(
                      color: Color(0xFFE07A5F),
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              )
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFFFFF2DF),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text("BERHASIL! 🌟",
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text(
                "Jawaban benar! Bersiap untuk misi ke-${misiBaruSelesai + 1}."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _buatMisiBaru();
                },
                child: const Text("Lanjut Misi",
                    style: TextStyle(
                        color: Color(0xFFE07A5F),
                        fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFFFF2DF),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text("YAHHH 😢",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
              "Jawaban kamu salah! Ayo coba teliti lagi susunan hurufnya."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Coba Lagi",
                style: TextStyle(
                    color: Color(0xFFB4A7D6), fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Tidak bisa kembali tanpa selesaikan misi
      child: Scaffold(
        backgroundColor: const Color(0xFFFBE7C6),
        appBar: AppBar(
          title: Text(
            _isLoading
                ? "Loading..."
                : "Misi: ${_misiSelesai + 1} / ${widget.targetMisi}",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFFB4A7D6),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(color: Color(0xFFE07A5F)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      "Urutkan Hurufnya Buat Matiin Alarm!",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 30, horizontal: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE07A5F),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 5))
                        ],
                      ),
                      child: Text(
                        _hurufAcakTampilan,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 4),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _jawabanController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(12)),
                        ),
                        hintText: "Ketik Jawabanmu Disini...",
                        fillColor: Colors.white,
                        filled: true,
                        suffix: Text(
                          "Dev: $_kunciJawaban",
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 10),
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB4A7D6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _cekJawaban,
                        child: const Text("Cek Jawaban",
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}