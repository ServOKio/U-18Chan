import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:developer';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:u_18chan/pages/sub/Thread.dart';

import '../main.dart';

Color getColor(int index){
  List<Color> c = [
    const Color(0xffea4b49),
    const Color(0xfff88749),
    const Color(0xfff8be46),
    const Color(0xff89c54d),
    const Color(0xff48bff9),
    const Color(0xff5b93fd),
    const Color(0xff9c6efb)
  ];
  return c[index % c.length];
}

class Section extends StatefulWidget {
  Section({Key? key, required this.path, required this.fapMode}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String path;
  bool fapMode;

  @override
  _SectionState createState() => _SectionState();
}

class _SectionState extends State<Section> {
  String custom = "";
  bool loaded = false;
  String sectionTitle = "";
  List<BlockInfo> blocks = [];
  List<PageInfo> pages = [];
  late ScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = new ScrollController();
    load();
  }

  void load() async{
    final responce = await http.Client().get(Uri.parse(custom == '' ? 'https://u18chan.com'+widget.path : custom));
    if(responce.statusCode == 200){
      setState(() {
        loaded = false;
      });
      blocks.clear();
      pages.clear();
      var document = parse(responce.body);
      sectionTitle = document.getElementsByClassName('Title').first.text;
      document.getElementsByClassName('item').forEach((element) {
        String title = element.getElementsByClassName('Subject').first.text;
        String link = "";
        element.getElementsByClassName('thumbnail_link').first.attributes.forEach((key, value) {
          if(key.toString() == 'href') link = value.toString();
        });
        String thumbnail = "";
        element.getElementsByTagName('img').first.attributes.forEach((key, value) {
          if(key.toString() == 'src') thumbnail = value.toString();
        });
        blocks.add(BlockInfo(title: title, thumbnail: thumbnail, link: link));
      });
      document.getElementsByClassName('ReplyBox').first.getElementsByTagName('a').forEach((element) {
        String text = "";
        String url = "";
        element.attributes.forEach((key, value) {
          if(key == 'href'){
            url = value.toString();
            text = element.text;
          }
        });
        pages.add(PageInfo(text: text, url: url, active: true));
      });
      setState(() {
        loaded = true;
      });
      await Future.delayed(const Duration(milliseconds: 300));
      SchedulerBinding.instance?.addPostFrameCallback((_) {
        controller.animateTo(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn);
      });
    } else {
      log(responce.statusCode.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    MyAppTheme theme = Provider.of(context);
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      endDrawer: Theme(
          data: Theme.of(context).copyWith(canvasColor: const Color(0x55000000)),
          child: Drawer(
              child: Container(
                  child: Stack(
                      children: [
                        Column(
                          children: <Widget>[
                            Container(child: Center(child: Text(sectionTitle, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)))),
                            // ListTile(
                            //   title: Text('Reload section'),
                            //   leading: Icon(Icons.wifi_protected_setup),
                            //   subtitle: Text('Get and parse the page again'),
                            //   onTap: (){
                            //     load();
                            //   },
                            // ),
                            Expanded(child: Container(
                                padding: EdgeInsets.all(7),
                                child: GridView.builder(
                              gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 8,
                                  crossAxisSpacing: 7,
                                  mainAxisSpacing: 7),
                              itemBuilder: (context, index) {
                                return RawMaterialButton(
                                    onPressed: () {
                                      setState(() {
                                        custom = pages[index].url;
                                      });
                                      load();
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: Container(
                                        color: theme.pagesButtons,
                                        child: AspectRatio(
                                            aspectRatio: 1,
                                            child: Center(
                                                child: pages[index].text == ' Next ' ? Icon(Icons.arrow_forward_ios) : pages[index].text == ' Previous ' ? Icon(Icons.arrow_back_ios) : Text(pages[index].text)
                                            )
                                        )
                                      ),
                                    )
                                );
                              },
                              itemCount: pages.length,
                            ))
                            ),
                            Padding(padding: EdgeInsets.all(7),child: Column(children: [
                              Text('All content posted is responsibility of its respective poster and neither the site nor its staff shall be held responsible or liable in any way shape or form.', style: TextStyle(fontSize: 10)),
                              Text('Please be aware that this kind of fetish artwork is NOT copyrightable in the hosting country and there for its copyright may not be upheld.', style: TextStyle(fontSize: 10)),
                              Text('We are NOT obligated to remove content under the Digital Millennium Copyright Act.', style: TextStyle(fontSize: 10))
                            ])),
                            Padding(padding: EdgeInsets.only(left: 7, right: 7, bottom: 7), child: Text('Contact us by by phone toll-free! 1-844-FOX-BUTT (369-2888)', style: TextStyle(fontSize: 10)))
                          ]
                        )
                      ]

                  )
              )
          )
      ),
      body: Container(
        padding: EdgeInsets.all(7),
        child: GridView.builder(
          controller: controller,
          gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7
          ),
          itemBuilder: (context, index) {
            return RawMaterialButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ThreadView(url: blocks[index].link, title: blocks[index].title, fapMode: widget.fapMode)));
                },
                child: Container(
                    child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                            borderRadius:
                            BorderRadius.circular(3),
                            child: Stack(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: blocks[index].thumbnail,
                                  imageBuilder: (context, imageProvider) {
                                    return Container(
                                      decoration:
                                      BoxDecoration(
                                        image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.cover
                                        ),
                                      ),
                                    );
                                  },
                                  placeholder: (context, url) =>
                                      Center(child: CircularProgressIndicator(color: getColor(index))),
                                  errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                                ),
                                _buildGradient(),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Padding(padding: EdgeInsets.all(7), child: Text(
                                      blocks[index].title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),)
                                  ],
                                ),
                              ],
                            )
                        )
                    )
                )
            );
          },
          itemCount: blocks.length,
        ),
      ),
    );
  }
}

Widget _buildGradient() {
  return Positioned.fill(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withOpacity(1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.6, 0.95],
        ),
      ),
    ),
  );
}

class BlockInfo {
  final String title;
  final String thumbnail;
  final String link;

  BlockInfo({
    required this.title,
    required this.thumbnail,
    required this.link
  });
}

class PageInfo {
  final String text;
  final String url;
  final bool active;

  PageInfo({
    required this.text,
    required this.url,
    required this.active
  });
}