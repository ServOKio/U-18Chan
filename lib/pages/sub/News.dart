import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import '../../main.dart';

class News extends StatefulWidget {
  News({Key? key, required this.news}) : super(key: key);

  final List<ArticleMeta> news;

  @override
  _NewsState createState() => new _NewsState();
}

class _NewsState extends State<News> {

  late ScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = new ScrollController();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MyAppTheme theme = Provider.of(context);
    return new Scaffold(
      appBar: AppBar(
        title: Text('News')
      ),
      body: Container(
        margin: EdgeInsets.symmetric(
            vertical: 3.5
        ),
        child: Scrollbar(
          child: new ListView.builder(
            controller: controller,
            itemBuilder: (context, index) {
              return Container(
                padding: EdgeInsets.symmetric(
                    vertical: 3.5,
                    horizontal: 7
                ),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      color: theme.newsBlock,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 7),
                                width: 21.0,
                                height: 21.0,
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.red),
                                    shape: BoxShape.circle
                                ),
                                child: Center(child: Text(widget.news[index].author[0])),
                              ),
                              Flexible(flex: 2, child: Text(widget.news[index].title, style: TextStyle(fontWeight: FontWeight.w700))),
                              Flexible(child: Text(" by ", style: TextStyle(color: theme.newsBlockTitleSub))),
                              Flexible(flex: 2, child: Text(widget.news[index].author, style: TextStyle(fontWeight: FontWeight.w700))),
                              // Text(" by ", style: TextStyle(color: theme.newsBlockTitleSub)),
                              // Text(widget.news[index].author, style: TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          Padding(padding: EdgeInsets.symmetric(vertical: 7), child: Html(
                            style: {
                              "body": Style(
                                margin: EdgeInsets.all(0),
                              )
                            },
                            data: widget.news[index].html,
                          )),
                          Row(children: [Text('${widget.news[index].date.day}/${widget.news[index].date.month}/${widget.news[index].date.year}', style: TextStyle(fontWeight: FontWeight.w300, color: Colors.grey, fontSize: 12, letterSpacing: 1))],)
                        ],
                      ),
                    )
                ),
              );
            },
            itemCount: widget.news.length,
          ),
        ),
      ),
    );
  }
}

class ArticleMeta {
  final String title;
  final String author;
  final DateTime date;
  final String html;

  ArticleMeta({
    required this.title,
    required this.author,
    required this.date,
    required this.html
  });
}