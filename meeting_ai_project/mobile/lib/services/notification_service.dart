import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    // Android için güvenli ikon
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // --- 🔥 AKILLI ZAMANLAYICI (17:00) ---
  Future<void> scheduleDailyStatusCheck(List<dynamic> allTasks) async {
    // Çakışmayı önlemek için eskileri temizle
    await flutterLocalNotificationsPlugin.cancelAll();
    
    final now = DateTime.now();
    int notificationCounter = 0;

    print("📅 GÜNLÜK BİLDİRİMLER PLANLANIYOR...");
    print("📱 TELEFON SAATİ: ${DateTime.now().toString()}");

    // ---------------------------------------------------------
    // ⚙️ SAAT AYARI (TEST İÇİN BURAYI DEĞİŞTİR)
    // 1 dakika sonrası için test
    int targetHour = now.hour;   
    int targetMinute = now.minute + 1; // <--- 1 DAKİKA SONRASI İÇİN TEST
    // ---------------------------------------------------------

    // Hedeflenen zamanı oluştur
    var scheduledDate = DateTime(now.year, now.month, now.day, targetHour, targetMinute);

    // 🔥 KRİTİK MANTIK: EĞER SAAT GEÇTİYSE YARINA KUR
    // Örn: Saat 17:05 ve biz 17:00'a kurmaya çalışıyorsak, sistem bunu yarına atar.
    if (scheduledDate.isBefore(now)) {
      print("⚠️ Saat $targetHour:$targetMinute geçmiş! Alarm yarına ($targetHour:$targetMinute) kuruluyor.");
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    } else {
      print("✅ Saat henüz gelmedi. Alarm bugüne ($targetHour:$targetMinute) kuruluyor.");
    }

    for (var task in allTasks) {
      if (task['due_date'] == null) continue;

      try {
        DateTime taskDate = DateTime.parse(task['due_date']);
        String title = task['description'] ?? "Görev";
        final difference = taskDate.difference(now).inDays;

        // Gelecek 10 gün kontrolü
        if (difference >= 0 && difference <= 10) {
          
          String messageBody = "📌 $difference gün kaldı. Unutma!";
          if (difference == 0) messageBody = "⏳ BUGÜN SON GÜN!";

          // Bildirimler üst üste binmesin diye 5'er saniye arayla diz
          var individualTime = scheduledDate.add(Duration(seconds: notificationCounter * 5));

          await flutterLocalNotificationsPlugin.zonedSchedule(
            task['id'], 
            'Smart AI Hatırlatıcı: $title',
            messageBody,
            tz.TZDateTime.from(individualTime, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'smart_daily_ai', // Kanal ID (Değiştirdim taze olsun)
                'Günlük Rapor',
                channelDescription: 'Her gün belirlenen saatte gelen rapor',
                importance: Importance.max,
                priority: Priority.high,
                enableVibration: true,
                playSound: true,
                styleInformation: BigTextStyleInformation(''),
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          
          print("✅ PLANLANDI: $title -> $individualTime");
          notificationCounter++;
        }
      } catch (e) {
        print("Hata: $e");
      }
    }
  }

  // Show immediate notification for testing
  Future<void> showImmediateNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'smart_daily_ai',
      'Günlük Rapor',
      channelDescription: 'Her gün belirlenen saatte gelen rapor',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Test Bildirimi',
      'Bu bir test bildirimidir! Sistem çalışıyor.',
      platformChannelSpecifics,
    );
  }
}