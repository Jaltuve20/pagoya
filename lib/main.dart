import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const PagoYaApp());
}

class PagoYaApp extends StatelessWidget {
  const PagoYaApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PAGOYA',
        home: WebShell(),
      );
}

class WebShell extends StatefulWidget {
  const WebShell({super.key});

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  static const _base = 'https://pagoya.local/';

  // Botón "atrás" de Android: cierra capas abiertas o retrocede de pantalla.
  static const _volver = r'''(function(){
 var t=document.getElementById('tuto'); if(t&&t.classList.contains('open')){cerrarTuto();return 'ok';}
 var b=document.getElementById('bio'); if(b&&b.classList.contains('open')){cerrarBio(false);return 'ok';}
 var s=document.getElementById('sheet'); if(s&&s.classList.contains('open')){cerrarSheet();return 'ok';}
 var a=document.querySelector('.screen.active');
 if(!a||a.id==='screen-1'||a.id==='screen-1.6') return 'exit';
 var k=a.querySelector('.back'); if(k){k.click();return 'ok';}
 goToScreen(1.6); return 'ok';
})()''';

  late final WebViewController _c;
  bool _dark = false;
  bool _listo = false;

  Color get _bg => _dark ? const Color(0xFF0B1220) : Colors.white;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('Tema', onMessageReceived: (m) {
        final d = m.message == 'dark';
        if (d != _dark) {
          setState(() => _dark = d);
          _barra();
        }
      })
      ..addJavaScriptChannel('Descarga', onMessageReceived: (m) => _guardarQR(m.message))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (!_listo && mounted) setState(() => _listo = true);
        },
        onNavigationRequest: (r) => r.url.startsWith(_base) || r.url == 'about:blank'
            ? NavigationDecision.navigate
            : NavigationDecision.prevent,
      ));
    _cargar();
    _barra();
  }

  Future<void> _cargar() async {
    final html = await rootBundle.loadString('assets/www/index.html');
    await _c.loadHtmlString(html, baseUrl: _base);
  }

  void _barra() {
    final icons = _dark ? Brightness.light : Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      systemNavigationBarColor: _bg,
      systemNavigationBarIconBrightness: icons,
    ));
  }

  Future<void> _guardarQR(String msg) async {
    try {
      final j = jsonDecode(msg) as Map<String, dynamic>;
      final bytes = base64Decode((j['d'] as String).split(',').last);
      final nombre = (j['n'] as String).replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/$nombre');
      await f.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(f.path)], text: 'Mi QR de PAGOYA');
    } catch (_) {}
  }

  Future<void> _atras() async {
    final r = await _c.runJavaScriptReturningResult(_volver);
    if (r.toString().contains('exit')) SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _atras();
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Stack(children: [
            WebViewWidget(controller: _c),
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _listo ? 0 : 1,
                duration: const Duration(milliseconds: 350),
                child: Container(
                  color: _bg,
                  alignment: Alignment.center,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset('assets/icon/logo.png', width: 112, height: 112),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
