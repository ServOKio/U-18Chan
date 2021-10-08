import 'package:flutter/material.dart';
import 'package:u_18chan/pages/sub/FAQ.dart';
import 'package:u_18chan/pages/sub/News.dart';
import 'package:u_18chan/pages/sub/Rules.dart';

class MainPage extends StatefulWidget {
  MainPage({Key? key,
    required this.news,
    required this.fag,
    required this.rules
  }) : super(key: key);

  final List<ArticleMeta> news;
  final String fag;
  final String rules;

  @override
  _BrowserState createState() => _BrowserState();
}

class _BrowserState extends State<MainPage> with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState(){
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose(){
    super.dispose();
    tabController.dispose();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      bottomNavigationBar: Container(

        height: 50,
        child: TabBar(
          indicatorColor: Colors.white,
          //indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3.0,
          //unselectedLabelColor: Colors.grey,
          //labelColor: Colors.black,
          controller: tabController,
          //labelStyle: TextStyle(fontWeight: FontWeight.bold),
          tabs: <Tab>[
            Tab(
                text: "News"
            ),
            Tab(
                text: "FAQ"
            ),
            Tab(
                text: "Rules"
            )
          ],
        ),
      ),
      body: TabBarView(
          controller: tabController,
          children: <Widget>[
            News(news: widget.news),
            FAQ(fag: widget.fag),
            Rules(rules: widget.rules)
          ]
      ),
    );
  }
}