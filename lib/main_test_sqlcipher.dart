import 'package:flutter/material.dart';
import 'test_sqlcipher_page.dart';

void main() {
  runApp(const SQLCipherTestApp());
}

class SQLCipherTestApp extends StatelessWidget {
  const SQLCipherTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQLCipher 加密测试',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: TestSQLCipherPage(),
    );
  }
}
