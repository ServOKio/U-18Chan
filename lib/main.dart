import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:u_18chan/pages/chat.dart';
import 'package:u_18chan/pages/main.dart';
import 'package:u_18chan/pages/section.dart';

import 'dart:developer';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:u_18chan/pages/sub/MultiThreads.dart';
import 'package:u_18chan/pages/sub/News.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  runApp(MyApp());
}

class MyAppTheme {

  bool isDark = true;

  MyAppTheme({required this.isDark});

  Color newsBlock = Color(0xff333333);
  Color themeMainColor = Colors.red;
  Color themeTimeStamp = Colors.grey;
  Color newsBlockTitleSub = Color(0xffD5D5D5);
  Color link = Color(0xffBBDDEE);
  Color pagesButtons = Colors.red;
  Color pagesButtonsPressed = const Color(0x77f44336);

  void init(){
    newsBlock = isDark ? Color(0xff333333) : Color(0xff5C72CB);
    themeMainColor = isDark ? Colors.red : Color(0xff93d0ea);
    themeTimeStamp = isDark ? Colors.grey : Colors.white70;
    newsBlockTitleSub = Color(0xffD5D5D5);
    link = Color(0xffBBDDEE);
    pagesButtons = isDark ? Colors.red : Color(0xff445fca);
    pagesButtonsPressed = isDark ? const Color(0x77f44336) : Color(0xff667ddb);
  }

  /// Default constructor

  ThemeData get themeData {
    /// Create a TextTheme and ColorScheme, that we can use to generate ThemeData
    TextTheme txtTheme = (ThemeData.dark()).textTheme;
    Color txtColor = Colors.red;
    ColorScheme colorScheme = ColorScheme(
      // Decide how you want to apply your own custom them, to the MaterialApp
        brightness: Brightness.dark,
        primary: Colors.red,
        primaryVariant: Colors.purple,
        secondary: const Color(0xffBBDDEE),
        secondaryVariant: Colors.purple,
        background: const Color(0xff1A1A1A),
        surface: isDark ? const Color(0xFF222222) : const Color(0xFF31469b),
        onBackground: txtColor,
        onSurface: Colors.white,
        onError: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        error: Colors.red.shade400
    );

    /// Now that we have ColorScheme and TextTheme, we can create the ThemeData
    ThemeData t = ThemeData.from(
        textTheme: txtTheme,
        colorScheme: colorScheme
    ).copyWith(
        primaryColor: isDark ? const Color(0xFF222222) : const Color(0xFF31469b),
        scaffoldBackgroundColor: isDark ? const Color(0xFF1C1C1C) : const Color(0xFF788BD6),
        buttonColor: Colors.purple,
        highlightColor: const Color(0xFF3D3D3D),
        toggleableActiveColor: Colors.purple
    );

    /// Return the themeData which MaterialApp can now use
    return t;
  }
}

ValueNotifier<bool> _notifier = ValueNotifier(false);

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  void i() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool th = (prefs.getBool('isLight') ?? false);
    print(th);
    _notifier.value = th;
  }

  @override
  Widget build(BuildContext context) {
    i();
    return ValueListenableBuilder<bool>(
        valueListenable: _notifier,
        builder: (_, mode, __) {
          MyAppTheme appTheme = MyAppTheme(isDark: !mode);
          appTheme.init();
          return Provider.value(
              value: appTheme,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'U-18Chan',
                theme: appTheme.themeData,
                home: Main(),
              )
          );
        }
    );
  }
}

class Main extends StatefulWidget {
  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  Widget bodyWidget = MainPage(news: [], fag: '', rules: '');
  bool loaded = false;
  List<MenuItem> menuItems = [];
  bool fapmode = false;

  List<ArticleMeta> news = [];
  String fag = "";
  String rules = "";

  List<String> threadsPaths = [
    '/fur/', '/c/', '/gfur/', '/gc/', '/i/', '/rs/', '/a/', '/cute/',
    '/p/', '/f/', '/cub/', '/gore/',
    '/d/', '/mu/', '/w/', '/v/', '/k/', '/lo/', '/tech/', '/lit/',
    '/jc/' //wtf
  ];
  List<String> custom = [
    '/chat/', '/fapmode/', '/r/', '/guide/', '/vlkyra/'
  ];

  void loadMenu() async{
    print('LOAD ALL !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    final responce = await http.Client().get(Uri.parse('https://u18chan.com/'));
    if(responce.statusCode == 200){
      setState(() {
        loaded = false;
      });
      menuItems.clear();
      var document = parse(responce.body);
      //Menu parse

      document.getElementsByClassName('board_nav').first.getElementsByTagName('a').forEach((element) {
        //Haha... EASY
        String title = "";
        String path = "";
        element.attributes.forEach((key, value) {
          if(key == 'href') path = value;
        });
        title = element.text;
        // 0 - section
        // 1 - thread
        // 2 - custom
        menuItems.add(MenuItem(title: title, sub: path != '#', path: path, type: threadsPaths.contains(path) ? 1 : custom.contains(path) ? 2 : 0));
      });

      print('Menu done (${menuItems.length} items)');

      //Tab0
      String title = '';
      String author = 'Unc';
      DateTime date = DateTime.now();
      String html = "";
      document.getElementById('Tab0')?.getElementsByTagName('div').forEach((element) {
        element.attributes.forEach((key, value) {
          if(key == 'class' && value.toString() == 'NewsTitleStrip') {
            RegExp regExp = new RegExp(r"(.*) by (.*) - (.*) @ .*", caseSensitive: false, multiLine: false);
            Iterable<Match> matches = regExp.allMatches(element.text);
            title = matches.elementAt(0).group(1).toString();
            author = matches.elementAt(0).group(2).toString();
          } else if(key == 'class' && value.toString() == 'NewsContent') {
            html = element.innerHtml;
          }
        });
        if(title != '' && author != '' && html != '') {
          news.add(ArticleMeta(
              title: title,
              author: author,
              date: date,
              html: html.replaceAll('<br>', '<br/>')
          ));
          title = '';
          //author = '';
          html = '';
        }
      });

      //Tab1
      fag = document.getElementById('Tab1')!.getElementsByClassName('NewsContent')[0].innerHtml.replaceAll('<br>', '<br><br/>');
      //Tab2
      rules = document.getElementById('Tab2')!.getElementsByClassName('NewsContent')[0].innerHtml.replaceAll('<br>', '<br><br/>');

      bodyWidget = MainPage(news: news, fag: fag, rules: rules);
      setState(() {
        loaded = true;
      });
    } else {
      log(responce.statusCode.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    loadMenu();
  }

  Future<void> setBo(bool val) async {
    final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    final SharedPreferences prefs = await _prefs;
    prefs.setBool('isLight', val);
    print(prefs.getBool('isLight'));
  }

  @override
  Widget build(BuildContext context) {
    //Test init

    List<Widget> menu = List.generate(menuItems.length, (i) {
      return !menuItems[i].sub ? Container(
        height: 40,
        padding: EdgeInsets.only(left: 10),
        child: Row(children: [Text(menuItems[i].title, style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1, fontSize: 18))],),
      ) : Container(
          height: 30,
          child: RawMaterialButton(
              onPressed: () {
                setState(() {
                  if(menuItems[i].type == 0) {
                    bodyWidget = Section(path: menuItems[i].path, fapMode: fapmode);
                  }
                  if(menuItems[i].type == 1) Navigator.push(context, MaterialPageRoute(builder: (context) => MultiThread(url: 'https://u18chan.com'+menuItems[i].path, title: menuItems[i].title, fapMode: fapmode)));
                  if(menuItems[i].type == 2) {
                    if(menuItems[i].path == '/chat/'){
                      bodyWidget = Chat();
                    } else bodyWidget = Center(child: Text('late'));
                  }
                });
              },
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 30),
                    child: Text(menuItems[i].title, style: TextStyle(fontSize: 16)),
                  )
                ],
              )
          )
      );
    });
    menu.insert(0, Container(
      padding: EdgeInsets.only(right: 14),
      height: 120,
      decoration: BoxDecoration(
        // color: Colors.red,
          image: DecorationImage(
              alignment: Alignment.centerLeft,
              scale: 2.5,
              image: AssetImage(!_notifier.value ? "assets/Valkyria02.png" : "assets/Rainbowdash.png"),
              fit: BoxFit.scaleDown
          )
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            "U-18Chan",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: !_notifier.value ? 28 : 38
            ),
          ),
          Text(
            "Being rammed by larger ships since 1914.",
            style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: !_notifier.value ? 6.7 : 9.2
            ),
          )
        ],
      ),
    ));
    menu.insert(menu.length, Container(
      margin: EdgeInsets.only(top: 14, left: 14),
        child: Row(
          children: [Text('Fap Mode'), Switch(
            value: fapmode,
            onChanged: (value) {
              setState(() {
                fapmode = value;
              });
            },
            activeTrackColor: Colors.lightGreenAccent,
            activeColor: Colors.green,
          )],
        )
    ));
    menu.insert(menu.length, Container(
        margin: EdgeInsets.only(left: 14, bottom: 14),
        child: Row(
          children: [Text('Theme '+(_notifier.value ? 'Sky' : 'Dark')), Switch(
            value: _notifier.value,
            onChanged: (value) {
              setBo(value);
              setState(() {
                _notifier.value = value;
              });
            },
            activeTrackColor: Colors.lightBlueAccent,
            activeColor: Colors.blue,
          )],
        )
    ));

    return Scaffold(
      body: bodyWidget,
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //
      //   },
      //   tooltip: 'Increment',
      //   child: Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
        drawer: Theme(
        data: Theme.of(context).copyWith(canvasColor: !_notifier.value ? const Color(0xbb000000) : const Color(0xbb788BD6)),
        child: Drawer(
          child: Container(
            child: ListView(
              // Important: Remove any padding from the ListView.
              children: menu
            ),
          ),
          )
        )
    );
  }
}

class MenuItem {
  final String title;
  final bool sub;
  final String path;
  final int type;

  MenuItem({
    required this.title,
    required this.sub,
    required this.path,
    required this.type
  });
}
