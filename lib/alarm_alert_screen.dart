import 'package:aplikasi_alarm/alarm_service.dart';
import 'package:flutter/material.dart';
import 'mission_screen.dart';

class AlarmAlertScreen extends StatefulWidget {
  final String selectedSound;
  final int targetMisi;
  final int alarmId; // ID alarm dari package alarm

  const AlarmAlertScreen({
    super.key,
    required this.selectedSound,
    this.targetMisi = 3,
    required this.alarmId,
  });

  @override
  State<AlarmAlertScreen> createState() => _AlarmAlertScreenState();
}

class _AlarmAlertScreenState extends State<AlarmAlertScreen> {
  // Suara sudah diputar oleh package alarm secara otomatis.
  // Getaran sudah dimulai oleh HomeScreen sebelum navigasi ke sini.
  // Tidak perlu melakukan apa-apa di initState untuk suara.

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Cegah user menutup screen alarm dengan tombol back
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF2DF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFE07A5F),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  "Ayo bangun!!!",
                  style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Selesaikan ${widget.targetMisi} misi untuk mematikan alarm",
                style: const TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB4A7D6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MissionScreen(
                        targetMisi: widget.targetMisi,
                        alarmId: widget.alarmId,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Mulai Misi",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}