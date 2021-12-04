import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:meetups/models/device.dart';
import 'package:meetups/models/event.dart';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://192.168.100.13:8080/api';

Future<List<Event>> getAllEvents() async {
  final response = await http.get(Uri.parse('$baseUrl/events'));

  if (response.statusCode == 200) {
    final List<dynamic> decodedJson = jsonDecode(response.body);
    return decodedJson.map((dynamic json) => Event.fromJson(json)).toList();
  } else {
    throw Exception('Falha ao carregar os eventos');
  }
}

Future<http.Response> sendDevice(Device device) async {
  final response = await http.post(
    Uri.parse('$baseUrl/devices'),
    headers: <String, String>{
      'Content-type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(
      <String, String>{
        'token': device.token ?? '',
        'modelo': device.model ?? '',
        'marca': device.brand ?? '',
      },
    ),
  );

  debugPrint(response.body);

  return response;
}
