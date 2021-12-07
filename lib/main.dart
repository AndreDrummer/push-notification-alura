import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:meetups/http/web.dart';
import 'package:meetups/models/device.dart';
import 'package:meetups/screens/events_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final navigatiorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    criticalAlert: false,
    announcement: false,
    provisional: false,
    carPlay: false,
    badge: true,
    alert: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint('Permissão garantida!');
    startPushNotificationHandler(messaging);
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    debugPrint('Permissão provisória!');
    startPushNotificationHandler(messaging);
  } else {
    debugPrint('Permissão negada!');
  }

  runApp(App());
}

Future<void> startPushNotificationHandler(FirebaseMessaging messaging) async {
  String? token = await messaging.getToken(
      vapidKey:
          'BOptq9FbWip1gwV6l3xAK5JEdm-mVPCs1FGwQWcTfu0U_UUHYY6XR6Hi54xoUDBDVonmr9zpwgleTEV6E7JzPOs');
  debugPrint('Token $token');
  _setPushToken(token);

  FirebaseMessaging.onMessage.listen(
    (RemoteMessage message) {
      debugPrint('Dados da mensagem: ${message.data}');
      if (message.notification != null) {
        debugPrint('Dados da notiicaçao: ${message.notification!.title}');
      }
    },
  );

  // Background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Checando de o aplicativo foi aberto pela notificação -> Terminated
  var notification = await FirebaseMessaging.instance.getInitialMessage();
  if (notification != null && notification.data['message'].length > 0) {
    debugPrint('${notification.data['message']}');
    ScaffoldMessenger.of(navigatiorKey.currentContext!).showSnackBar(SnackBar(
        content: Text('Olha eu aqui ${notification.data['message']}')));
  }
}

// Background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('BACKGROUND MESSAGE: ${message.notification?.body}');
}

void _setPushToken(String? token) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  String? brand;
  String? model;
  String? prefsToken = prefs.getString('pushToken');
  bool? prefSent = prefs.getBool('tokenSent');

  if (prefsToken != token || prefSent == false) {
    debugPrint('Enviando para o servidor $token');

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      debugPrint('Rodando no ${androidInfo.model}');
      brand = androidInfo.brand;
      model = androidInfo.model;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      debugPrint('Rodando no ${iosInfo.model}');
      brand = 'Apple';
      model = iosInfo.utsname.machine;
    }
    Device device = Device(brand: brand, model: model, token: token);
    sendDevice(device).then((response) {
      prefs.setString('pushToken', token!);
      prefs.setBool('tokenSent', true);
    });
  }
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dev meetups',
      home: EventsScreen(),
      navigatorKey: navigatiorKey,
    );
  }
}
