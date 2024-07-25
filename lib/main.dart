
import 'package:highlighttext/auth.dart';
import 'package:universal_html/html.dart';
import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ory_client/ory_client.dart';
Future main() async {
  // load the env file

  final baseUrl = 'http://localhost:3005';

  // create the dio client for http requests
  final options = BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10000),
    receiveTimeout: const Duration(seconds: 5000),
    headers: {
      "Accept": "application/json",
    },
    validateStatus: (status) {
      // here we prevent the request from throwing an error when the status code is less than 500 (internal server error)
      return status! < 500;
    },
  );
  final dio = DioForBrowser(options);
  final adapter = BrowserHttpClientAdapter();
  // enable cookies support
  // we need this so we can send HTTP requests to the server with the cookies stored in the browser
  adapter.withCredentials = true;
  dio.httpClientAdapter = adapter;

  final auth = AuthService(dio);

  if (!(await auth.isAuthenticated())) {
    _launchURL(baseUrl);
    return;
  }

  runApp(MyApp(dio: dio, auth: auth));
}

void _launchURL(String url) async {
  window.open("$url/self-service/login/browser", '_self');
}

class MyApp extends StatelessWidget {
  final Dio dio;
  final AuthService auth;

  const MyApp({Key? key, required this.dio, required this.auth})
      : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Ory ❤ Flutter Web', auth: auth),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title, required this.auth})
      : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  final AuthService auth;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Session Information:${widget.auth.identity.toString()}'),
            TextButton(
                onPressed: widget.auth.logout, child: const Text('Logout')),
          ],
        ),
      ),
    );
  }
}