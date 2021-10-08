import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert' as convert;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:u_18chan/pages/section.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../main.dart';

class Chat extends StatefulWidget {

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  bool loaded = false;
  List<Member> members = [];
  List<Widget> mem = [];
  final _random = new Random();
  int next(int min, int max) => min + _random.nextInt(max - min);


  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async{
    final response = await http.Client().get(Uri.parse('https://discord.com/api/guilds/280435323983364097/widget.json'));
    if(response.statusCode == 200){
      Map<String, dynamic> main = convert.jsonDecode(response.body);
      if (main['members'] != null) {
        main['members'].forEach((alb) {
          members.add(Member(id: int.parse(alb['id']), username: alb['username'], discriminator: alb['discriminator'], status: alb['status'], avatarUrl: alb['avatar_url']));
        });
      }
      members.forEach((element) {
        double size = next(30, 60).toDouble();
        mem.add(Positioned(left: next(0, MediaQuery.of(context).size.width.round()).toDouble(), top: next(0, MediaQuery.of(context).size.height.round()).toDouble(),child: CachedNetworkImage(
          imageUrl: element.avatarUrl,
          imageBuilder: (context, imageProvider) {
            return Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover
                ),
                shape: BoxShape.circle,
              ),
            );
          },
          placeholder: (context, url) => Container(width: 50, height: 50, decoration:
          BoxDecoration(color: getColor(element.id),
            shape: BoxShape.circle
          )),
          errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
        )));
      });
      setState(() {
        loaded = true;
      });

    } else {

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
      body: Stack(
        children: [
          Stack(children: loaded ? mem : []),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xbb000000)
              )
            ),
          ),
          Positioned.fill(
              child: Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ClipRRect(
                      //   borderRadius: BorderRadius.circular(18),
                      //   child: Container(
                      //     padding: EdgeInsets.all(10),
                      //     color: Color(0xffff0000),
                      //     child: Container(
                      //       height: 100,
                      //       width: 100,
                      //       decoration: BoxDecoration(
                      //         shape: BoxShape.circle,
                      //         color: Colors.white,
                      //       ),
                      //       padding: EdgeInsets.all(10),
                      //       child: SvgPicture.asset('assets/discord-white.svg', color: Colors.black),
                      //     ),
                      //   ),
                      // ),
                      Container(
                        height: 100,
                        width: 100,
                        child: SvgPicture.asset('assets/discord-white.svg', color: Colors.white),
                      ),
                      Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Column(children: [
                        Text('Join to our discord server', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Adult only ', style: TextStyle(color: theme.newsBlockTitleSub)),
                            Icon(Icons.warning, size: 16),
                            Text(' click on logo to join', style: TextStyle(color: theme.newsBlockTitleSub)),
                          ],
                        )
                      ])),
                    ],
                  )
              )
          )
        ],
      )
    );
  }
}

class Member {
  final int id;
  final String username;
  final String discriminator;
  final String status;
  final String avatarUrl;

  Member({
    required this.id,
    required this.username,
    required this.discriminator,
    required this.status,
    required this.avatarUrl
  });
}