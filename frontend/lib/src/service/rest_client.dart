import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

abstract class RestClient {
  RestClient(this.client);

  @protected
  final http.Client client;

  @protected
  final Map<String, String> headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Access-Control-Allow-Origin': '*'
  };
}
