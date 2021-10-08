import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'dart:developer';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../main.dart';
import '../../utils/shit.dart' as utils;
import '../section.dart';
import 'Thread.dart';

class MultiThread extends StatefulWidget {
  MultiThread({Key? key, required this.url, required this.title, required this.fapMode}) : super(key: key);

  final String url;
  final String title;
  bool fapMode;

  @override
  _MultiThreadState createState() => _MultiThreadState();
}

class _MultiThreadState extends State<MultiThread> {
  bool loaded = false;
  String sectionTitle = "";
  String custom = "";
  List<ThreadMeta> threads = [];
  List<PostMeta> posts = [];
  List<PageInfo> pages = [];
  late ScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = new ScrollController();
    load();
  }

  void load() async{
    print('load');
    http.Response responce = widget.fapMode ? await http.get(
        Uri.parse(custom == '' ? widget.url : custom),
        headers: {'Cookie': 'fap_mode=on'}
    ) : await http.Client().get(Uri.parse(custom == '' ? widget.url : custom));
    if(responce.statusCode == 200){
      setState(() {
        loaded = false;
      });
      threads.clear();
      posts.clear();
      pages.clear();
      var document = parse(responce.body);
      sectionTitle = document.getElementsByClassName('Title').first.text;

      document.getElementById('DeleteForm')!.getElementsByTagName('div').forEach((element) {
        element.attributes.forEach((key, value) {
          if(key == 'id' && value.startsWith('Thread') && value.endsWith('Table')){
            //Здесь пост
            bool f = false;
            String ffullImage = "";
            String fpreviewImage = "";
            int fpreviewHeight = 0;
            String ffileMame = "";
            String ftitle = "";
            String fpostContent = "";
            int fpostID = 0;
            String fsender = "";
            String fmail = "";
            String threadURL = "";
            int threadID = 0;

            element.querySelector('.FileDetails a')?.attributes.forEach((key, value) {
              if(key == 'href') ffullImage = value;
            });
            if(element.querySelector(".FileDetails a") != null) ffileMame = element.querySelector(".FileDetails a")!.text;
            element.querySelector('a img')?.attributes.forEach((key, value) {
              if(key == 'data-original') fpreviewImage = value;
              if(key == 'style'){
                RegExp regExp = new RegExp(r"width: .* height: (.+)px;", caseSensitive: false, multiLine: false);
                Iterable<Match> matches = regExp.allMatches(value);
                fpreviewHeight = int.parse(matches.elementAt(0).group(1).toString());
              }
            });
            ftitle = element.getElementsByClassName('UserDetails')[0].getElementsByClassName('Subject')[0].text;
            if(element.getElementsByClassName('UserDetails')[0].getElementsByClassName('UserName')[0].getElementsByTagName('a').length > 0){
              element.getElementsByClassName('UserDetails')[0].getElementsByClassName('UserName')[0].getElementsByTagName('a')[0].attributes.forEach((key, value) {
                if(value.startsWith('/cdn-cgi')) fmail = "CloudFlare";
                if(value.startsWith('mailto:')) fmail = value.replaceAll('mailto:', 'replace');
              });
            }

            element.getElementsByClassName('UserDetails')[0].getElementsByTagName('a').forEach((element) {
              bool ok = false;
              element.attributes.forEach((key, value) {
                if(key == 'class' && value == 'AltLink') ok = true;
                if(key == 'href' && element.text == 'Reply') threadURL = value;
              });
              element.attributes.forEach((key, value) {
                if(ok && key == 'href' && value.startsWith('https://u18chan.com/board/')) fpostID = int.parse(element.text);
              });
            });
            element.getElementsByTagName('span').forEach((element) {
              element.attributes.forEach((key, value) {
                if(key == 'name' && value == 'post_${fpostID}_message_div') fpostContent = element.text;
              });
            });

            fsender = element.getElementsByClassName('UserDetails')[0].getElementsByClassName('UserName')[0].text;
            threadID = int.parse(value.replaceAll('Thread', '').replaceAll('Table', ''));
            List<TagMeta> tags = [];
            if(element.getElementsByClassName('thread_tag_box_wrapper').length > 0){
              element.getElementsByClassName('thread_tag_box_wrapper')[0].getElementsByClassName('TagBoxCount').forEach((element) {
                RegExp regExp = new RegExp(r"(.*) \((.*)\)", caseSensitive: false, multiLine: false);
                Iterable<Match> matches = regExp.allMatches(element.text);
                tags.add(TagMeta(name: matches.elementAt(0).group(1).toString(), count: int.parse(matches.elementAt(0).group(2).toString())));
              });
            }

            posts.add(
                PostMeta(
                    previewImage: fpreviewImage,
                    fullImage: ffullImage,
                    title: ftitle,
                    postID: fpostID,
                    content: fpostContent,
                    sender: fsender,
                    mail: fmail,
                    first: true,
                    threadURL: threadURL,
                    hasSpoiler: false,
                    file: [],
                    timestamp: element.getElementsByClassName('UserDetails')[0].text.split("\n")[4],
                    index: posts.length,
                    previewImageHeight: fpreviewHeight,
                    tags: tags,
                  replies: {}
                )
            );

            document.getElementById('thread_${threadID}_replies')!.getElementsByClassName('ReplyBoxTable').forEach((element) {
              String previewImage = '';
              String fullImage = '';
              String mail = "";
              String title = element.getElementsByClassName('UserDetails')[0].getElementsByClassName('Subject')[0].text;
              String sender = element.getElementsByClassName('UserDetails')[0].getElementsByClassName('UserName')[0].text;
              if(element.getElementsByClassName('UserDetails')[0].getElementsByClassName('UserName')[0].getElementsByTagName('a').length > 0){
                element.getElementsByClassName('UserDetails')[0].getElementsByClassName('UserName')[0].getElementsByTagName('a')[0].attributes.forEach((key, value) {
                  if(value.startsWith('/cdn-cgi')) mail = "CloudFlare";
                  if(value.startsWith('mailto:')) mail = value.replaceAll('mailto:', 'replace');
                });
              }
              int postID = 0;
              element.getElementsByClassName('ReplyBox')[0].attributes.forEach((key, value) {
                if(key == 'id' && value.startsWith('replybox_')) postID = int.parse(value.replaceAll('replybox_', ''));
              });
              String content = "";
              bool hasSpoiler = false;
              int previewHeight = 0;
              if(element.getElementsByClassName('ReplyContentOuterImage').length > 0 && element.getElementsByClassName('ReplyContentOuterImage')[0].getElementsByTagName('img').length > 0){
                element.getElementsByClassName('ReplyContentOuterImage')[0].getElementsByTagName('img').first.attributes.forEach((key, value) {
                  if(key.toString() == 'data-original') previewImage = value.toString();
                  if(previewImage == '' && key.toString() == 'src') hasSpoiler = true;
                });
                element.getElementsByClassName('ReplyContentOuterImage')[0].getElementsByTagName('img').first.attributes.forEach((key, value) {
                  if(previewImage != '' && key == 'style'){
                    RegExp regExp = new RegExp(r"width: .* height: (.+)px;", caseSensitive: false, multiLine: false);
                    Iterable<Match> matches = regExp.allMatches(value);
                    previewHeight = int.parse(matches.elementAt(0).group(1).toString());
                  }
                });
                element.getElementsByClassName('ReplyContentOuterImage')[0].getElementsByClassName('FileDetails')[0].getElementsByTagName('a')[0].attributes.forEach((key, value) {
                  if(key == 'href') fullImage = value;
                });
              }

              List<String> file = [];
              Map<int, PostMeta> replies = {};
              if(element.getElementsByClassName('ReplyContentOuter').length > 0) {
                element.getElementsByClassName('ReplyContentOuter')[0].getElementsByTagName('span').forEach((element) {
                  element.attributes.forEach((key, value) {
                    if(key == 'name' && value == 'post_${postID}_message_div'){
                      content = element.text;
                      element.getElementsByTagName('a').forEach((element) {
                        element.attributes.forEach((key, value) {
                          if(key == 'onmouseover' && value.startsWith('ShowPostPreviewBubble')){
                            String html = Uri.decodeFull(value.replaceAll('ShowPostPreviewBubble(this, rawurldecode("', '').replaceAll('"));', ''));
                            var doc = parse(html.replaceAll('<br />', "\n").replaceAll('<br/>', "\n").replaceAll('<br>', "\n"));
                            String rtitle = doc.getElementsByClassName('UserDetails')[0].getElementsByClassName('Subject')[0].text;
                            String rsender = doc.getElementsByClassName('UserDetails')[0].getElementsByClassName('UserName')[0].text;
                            doc.getElementsByClassName('UserDetails')[0].remove();
                            String rcontent = '';
                            String rpreviewImage = '';
                            int rpreviewHeight = 0;
                            List<String> rfile = [];
                            if(doc.getElementsByClassName('FileDetails').length < 0){
                              rcontent = doc.documentElement!.getElementsByTagName('body')[0].text.replaceAll(new RegExp(r"^(?:[\t ]*(?:\r?\n|\r))+", caseSensitive: false, multiLine: false), '');
                            } else {
                              if(doc.getElementsByTagName('img').length > 0) {
                                doc.getElementsByTagName('img').first.attributes.forEach((key, value) {
                                  if(key.toString() == 'src') rpreviewImage = value.toString();
                                });
                                doc.getElementsByTagName('img').first.attributes.forEach((key, value) {
                                  if(rpreviewImage != '' && key == 'style'){
                                    RegExp regExp = new RegExp(r"width: .* height: (.+)px;", caseSensitive: false, multiLine: false);
                                    Iterable<Match> matches = regExp.allMatches(value);
                                    rpreviewHeight = int.parse(matches.elementAt(0).group(1).toString());
                                  }
                                });
                                doc.getElementsByClassName('FileDetails')[0].remove();
                                doc.getElementsByTagName('script')[0].remove();
                                rcontent = doc.documentElement!.getElementsByTagName('body')[0].text.replaceAll(new RegExp(r"^(?:[\t ]*(?:\r?\n|\r))+", caseSensitive: false, multiLine: false), '');
                              } else {
                                if(doc.getElementsByTagName('object').length > 0) {
                                  rfile.add(doc.getElementsByClassName('FileDetails')[0].text.replaceAll("\n", '').replaceAll('File: ', ''));
                                  String ytURL = '';
                                  doc.getElementsByTagName('object')[0].getElementsByTagName('param').forEach((element) {
                                    element.attributes.forEach((key, value) {
                                      if(key == 'value' && value.contains('youtube.com')){
                                        RegExp regExp = new RegExp(r"^https?://.*(?:youtu.be/|v/|u/\\w/|embed/|watch?v=)([^#&?]*).*$", caseSensitive: true, multiLine: false);
                                        Iterable<Match> matches = regExp.allMatches(value);
                                        rfile.add('youtube');
                                        rfile.add(matches.elementAt(0).group(1).toString());
                                        doc.getElementsByClassName('FileDetails')[0].remove();
                                        doc.getElementsByTagName('script')[0].remove();
                                        doc.getElementsByTagName('object')[0].remove();
                                        rcontent = doc.documentElement!.getElementsByTagName('body')[0].text.replaceAll(new RegExp(r"^(?:[\t ]*(?:\r?\n|\r))+", caseSensitive: false, multiLine: false), '');
                                      }
                                    });
                                  });
                                  if(rfile.length == 0) rcontent = doc.documentElement!.getElementsByTagName('body')[0].text.replaceAll(new RegExp(r"^(?:[\t ]*(?:\r?\n|\r))+", caseSensitive: false, multiLine: false), '');
                                } else rcontent = doc.documentElement!.getElementsByTagName('body')[0].text.replaceAll(new RegExp(r"^(?:[\t ]*(?:\r?\n|\r))+", caseSensitive: false, multiLine: false), '');
                                //rcontent = doc.documentElement!.getElementsByTagName('body')[0].text.replaceAll(new RegExp(r"^\d*\n*|\n*\d*$", caseSensitive: false, multiLine: false), '');
                              }
                            }
                            replies.addAll({int.parse(element.text.replaceAll('>>', '')): PostMeta(
                                previewImage: rpreviewImage,
                                previewImageHeight: rpreviewHeight,
                                fullImage: '',
                                title: rtitle,
                                postID: 0,
                                content: rcontent,
                                sender: rsender,
                                mail: '',
                                hasSpoiler: false,
                                timestamp: '',
                                file: rfile,
                                tags: [],
                                replies: {},
                                index: replies.length,
                                first: false,
                                threadURL: ''
                            )});
                          }
                        });
                      });
                    }
                  });
                });
                if(element.getElementsByClassName('ReplyContentOuter')[0].getElementsByClassName('FileDetails').length > 0){
                  file.add(element.getElementsByClassName('ReplyContentOuter')[0].getElementsByClassName('FileDetails')[0].text.replaceAll("\n", '').replaceAll('File: ', ''));
                  if(element.getElementsByClassName('ReplyContentOuter')[0].getElementsByTagName('embed').length > 0){
                    element.getElementsByClassName('ReplyContentOuter')[0].getElementsByTagName('embed')[0].attributes.forEach((key, value) {
                      if(key == 'src' && value.contains('youtube.com')){
                        RegExp regExp = new RegExp(r"^https?://.*(?:youtu.be/|v/|u/\\w/|embed/|watch?v=)([^#&?]*).*$", caseSensitive: true, multiLine: false);
                        Iterable<Match> matches = regExp.allMatches(value);
                        file.add('youtube');
                        file.add(matches.elementAt(0).group(1).toString());
                      }
                    });
                  }
                }
              }

              List<TagMeta> tags = [];
              if(element.getElementsByClassName('tagSection')[0].getElementsByClassName('TagBox').length > 0){
                element.getElementsByClassName('tagSection')[0].getElementsByClassName('TagBox').forEach((element) {
                  if(element.text != 'Add Tag') tags.add(TagMeta(name: element.text, count: 0));
                });
              }

              posts.add(
                PostMeta(
                  previewImage: previewImage,
                  fullImage: fullImage,
                  title: title,
                  postID: postID,
                  content: content,
                  sender: sender,
                  mail: mail,
                  first: false,
                  threadURL: threadURL,
                  hasSpoiler: hasSpoiler,
                  file: file,
                  timestamp: element.getElementsByClassName('UserDetails')[0].text.split("\n")[4],
                  index: posts.length,
                  tags: tags,
                  previewImageHeight: previewHeight,
                  replies: replies
                )
              );
            });

            threads.add(
              ThreadMeta(threadID: threadID, threadURL: threadURL)
            );
          }
        });
      });

      document.getElementsByClassName('PagingTable').first.getElementsByTagName('a').forEach((element) {
        String text = "";
        String url = "";
        element.attributes.forEach((key, value) {
          if(key == 'href'){
            url = value.toString();
            text = element.text;
          }
        });
        int page = int.parse(text);
        if(page == 1 && pages.length == 0) pages.add(PageInfo(text: '0', url: '', active: false));
        if(page > 0 && pages.length > 0 && int.parse(pages[pages.length-1].text) != page-1) pages.add(PageInfo(text: (page-1).toString(), url: '', active: false));
        pages.add(PageInfo(text: text, url: url, active: true));
      });

      setState(() {
        loaded = true;
      });
      await Future.delayed(const Duration(milliseconds: 300));
      SchedulerBinding.instance?.addPostFrameCallback((_) {
        controller.animateTo(0, duration: const Duration(milliseconds: 100), curve: Curves.fastOutSlowIn);
      });
      print('done');
    } else {
      log(responce.statusCode.toString());
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget first(BuildContext context, PostMeta pm){
    MyAppTheme theme = Provider.of(context);
    List<Widget> tags = [];
    pm.tags.forEach((element) {
      tags.add(Container(
        margin: EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white24)
        ),
        child: Padding(padding: EdgeInsets.symmetric(vertical: 2, horizontal:4),child: Row(children: [Text('${element.name} ', style: TextStyle(fontSize: 10, color: Colors.white)), Text(element.count.toString(), style: TextStyle(fontSize: 10, color: theme.newsBlockTitleSub))],)),
      ));
    });

    return ClipRRect(
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
    child: pm.previewImage != '' ? Padding(padding: EdgeInsets.only(top: pm.index == 0 ? 0 : 3.5), child: CachedNetworkImage(
      imageUrl: pm.previewImage.endsWith('gif') ? pm.fullImage : pm.previewImage,
      imageBuilder: (context, imageProvider) {
        return Container(
            decoration: BoxDecoration(
              color: Colors.red,
              image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover
              ),
            ),
            child: Container(
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7)),
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(child: Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image(
                              image: imageProvider
                          )
                      ),
                    )),
                    Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 3.5),
                                  width: 14.0,
                                  height: 14.0,
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.red),
                                      shape: BoxShape.circle
                                  ),
                                  child: Center(child: Text(pm.sender[0], style: TextStyle(fontSize: 9))),
                                ),
                                Flexible(flex: 2, child: Text(pm.sender, style: TextStyle(fontSize: 12))),
                                // Text(" by ", style: TextStyle(color: theme.newsBlockTitleSub)),
                                // Text(widget.news[index].author, style: TextStyle(fontWeight: FontWeight.w700)),
                                pm.mail == 'CloudFlare' ? Padding(padding: EdgeInsets.only(left: 3), child: Icon(Icons.cloud_off, size: 12)) : SizedBox.shrink()
                              ],
                            ),
                            pm.title != '' ? Padding(padding: EdgeInsets.only(top: 7), child: Text(pm.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))) : Padding(padding: EdgeInsets.only(top: 7)),
                            pm.content != '' ? Padding(padding: EdgeInsets.only(bottom: 7), child: Text(pm.content, style: TextStyle(fontSize: 12))) : SizedBox.shrink(),
                            pm.tags.length > 0 ? Padding(padding: EdgeInsets.only(top: 7), child: Align(alignment: Alignment.centerLeft, child: SingleChildScrollView(child: Row(
                              children: tags,
                            ),scrollDirection: Axis.horizontal))) : SizedBox.shrink(),
                            Padding(padding: EdgeInsets.only(top: 7),
                                child: Row(children: [TextButton(
                                  style: ButtonStyle(
                                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(18.0),
                                              side: BorderSide(color: Colors.red)
                                          )
                                      )
                                  ),
                                  onPressed: (){
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => ThreadView(url: pm.threadURL, title: pm.title, fapMode: widget.fapMode)));
                                  },
                                  child: Padding(padding: EdgeInsets.symmetric(horizontal: 7), child: Text('View thread', style: TextStyle(color: Colors.white))),
                                )],)
                            ),
                          ],
                        )
                    )
                  ],
                ),
              ),
            )
        );
      },
      placeholder: (context, url) => Center(child: CircularProgressIndicator(color: Colors.red)),
      errorWidget: (context, url, error) {
        return Container(
            decoration: BoxDecoration(
              color: getColor(pm.index),
            ),
            child: Container(
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7)),
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 3.5),
                          width: 14.0,
                          height: 14.0,
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.red),
                              shape: BoxShape.circle
                          ),
                          child: Center(child: Text(pm.sender[0], style: TextStyle(fontSize: 9))),
                        ),
                        Flexible(flex: 2, child: Text(pm.sender, style: TextStyle(fontSize: 12))),
                        // Text(" by ", style: TextStyle(color: theme.newsBlockTitleSub)),
                        // Text(widget.news[index].author, style: TextStyle(fontWeight: FontWeight.w700)),
                        pm.mail == 'CloudFlare' ? Padding(padding: EdgeInsets.only(left: 3), child: Icon(Icons.cloud_off, size: 12)) : SizedBox.shrink()
                      ],
                    ),
                    pm.title != '' ? Padding(padding: EdgeInsets.only(top: 7), child: Text(pm.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))) : SizedBox.shrink(),
                    pm.content != '' ? Padding(padding: EdgeInsets.only(top: 7), child: Text(pm.content, style: TextStyle(fontSize: 12))) : SizedBox.shrink(),
                    pm.tags.length > 0 ? Padding(padding: EdgeInsets.only(top: 7), child: SingleChildScrollView(child: Row(children: tags),scrollDirection: Axis.horizontal)) : SizedBox.shrink(),
                    Padding(padding: EdgeInsets.only(top: 7),
                        child: Row(children: [TextButton(
                          style: ButtonStyle(
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                      side: BorderSide(color: Colors.red)
                                  )
                              )
                          ),
                          onPressed: (){
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ThreadView(url: pm.threadURL, title: pm.title, fapMode: widget.fapMode)));
                          },
                          child: Padding(padding: EdgeInsets.symmetric(horizontal: 7), child: Text('View thread', style: TextStyle(color: Colors.white))),
                        )],)
                    ),
                  ],
                )
              ),
            )
        );
      },
    )) : Padding(padding: EdgeInsets.only(bottom: 3.6), child: Container(
        decoration: BoxDecoration(
          color: getColor(pm.index),
        ),
        child: Container(
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.7)),
          child: Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 3.5),
                        width: 14.0,
                        height: 14.0,
                        decoration: BoxDecoration(
                            border: Border.all(color: getColor(pm.index)),
                            shape: BoxShape.circle
                        ),
                        child: Center(child: Text(pm.sender[0], style: TextStyle(fontSize: 9))),
                      ),
                      Flexible(flex: 2, child: Text(pm.sender, style: TextStyle(fontSize: 12))),
                      // Text(" by ", style: TextStyle(color: theme.newsBlockTitleSub)),
                      // Text(widget.news[index].author, style: TextStyle(fontWeight: FontWeight.w700)),
                      pm.mail == 'CloudFlare' ? Padding(padding: EdgeInsets.only(left: 3), child: Icon(Icons.cloud_off, size: 12)) : SizedBox.shrink()
                    ],
                  ),
                  pm.title != '' ? Padding(padding: EdgeInsets.only(top: 7), child: SelectableText(pm.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))) : SizedBox.shrink(),
                  pm.content != '' ? Padding(padding: EdgeInsets.only(top: 7), child: SelectableText(pm.content, style: TextStyle(fontSize: 12))) : SizedBox.shrink(),
                  pm.tags.length > 0 ? Padding(padding: EdgeInsets.only(top: 7), child: Align(alignment: Alignment.centerLeft, child: SingleChildScrollView(child: Row(children: tags),scrollDirection: Axis.horizontal))) : SizedBox.shrink(),
                  Padding(padding: EdgeInsets.only(top: 7),
                      child: Row(children: [TextButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                    side: BorderSide(color: getColor(pm.index))
                                )
                            )
                        ),
                        onPressed: (){
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ThreadView(url: pm.threadURL, title: pm.title, fapMode: widget.fapMode)));
                        },
                        child: Padding(padding: EdgeInsets.symmetric(horizontal: 7), child: Text('View thread', style: TextStyle(color: Colors.white))),
                      )],)
                  ),
                ],
              )
          ),
        )
    )));
  }

  @override
  Widget build(BuildContext context) {
    MyAppTheme theme = Provider.of(context);
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: const Color(0xaa000000),
          elevation: 0,
          actions: [
            Padding(padding: EdgeInsets.only(right: 12), child: GestureDetector(
              onTap: (){
                load();
                //print(Uri.decodeFull("%0A%09%09%3Cdiv%20class%3D%22UserDetails%22%3E%0A%09%09%09%3Cinput%20type%3D%22checkbox%22%20name%3D%22post_1990410%22%2F%3E%20%0A%09%09%09%3Cspan%20class%3D%22Subject%22%3E.%20%3C%2Fspan%3E%0A%09%09%09%3Cspan%20class%3D%22UserName%22%3E%3Ca%20href%3D%27mailto%3A.%27%3EChatin%3C%2Fa%3E%20%3C%2Fspan%3E%20%3Cspan%20class%3D%22CapCodeCustom%22%20style%3D%27color%3Apurple%27%3E%23%20MOD%20%23%3C%2Fspan%3E%20%0A%09%09%09%0A%09%09%09%092021%2F08%2F06%2021%3A46%3A44%20%20%0A%09%09%09%09No.%3Ca%20class%3D%22AltLink%22%20href%3D%22https%3A%2F%2Fu18chan.com%2Fboard%2Fu18chan%2Fgc%2Ftopic%2F1902637%231990410%22%3E1990410%3C%2Fa%3E%20%0A%09%09%09%09%0A%09%09%09%09%20%0A%09%09%09%09%09%09%3Ca%20class%3D%22AltLink%22%20href%3D%22javascript%3AEditPost%281990410%2C%20%27Chatin%27%2C%20%27.%27%2C%20%27.%27%2C%20%27%26gt%3B%26gt%3B1982952%5Cn%5Cn%5Bcolor%3Dred%5D%26quot%3BPlease%20refrain%20from%20using%20anonymising%20proxies.%20If%20we%20discover%20you%20are%20using%20one%2C%20your%20proxy%20will%20probably%20be%20banned.%26quot%3B%5B%2Fcolor%5D%5Cn%5CnFrom%20the%20rules%20page%20for%20the%20site.%20Try%20reading%20them.%20Oh%20look%20two%20new%20VPNs%20to%20ban.%27%2C%200%2C%20%27%27%2C%20%27%27%29%3B%22%20title%3D%22Edit%20Post%22%3E%3Cimg%20src%3D%22https%3A%2F%2Fu18chan.com%2Fthemes%2Fdefault%2Fimages%2Ficons%2Fedit_post.png%22%2F%3E%3C%2Fa%3E%20%0A%09%09%09%09%09%09%0A%09%09%09%09%0A%09%09%3C%2Fdiv%3E%0A%09%3Ca%20href%3D%27https%3A%2F%2Fu18chan.com%2Fboard%2Fu18chan%2Fgc%2Ftopic%2F1902637%231982952%27%20class%3D%27PostLink%27%20onclick%3D%27HighlightPost%281982952%29%3B%27%20%0A%09%09%09%09%09%09%09%3E%0A%09%09%09%09%09%09%09%09%20%26gt%3B%26gt%3B1982952%0A%09%09%09%09%09%09%09%20%20%3C%2Fa%3E%3Cbr%20%2F%3E%3Cbr%20%2F%3E%3Cspan%20style%3D%22color%3A%20red%3B%22%3E%26quot%3BPlease%20refrain%20from%20using%20anonymising%20proxies.%20If%20we%20discover%20you%20are%20using%20one%2C%20your%20proxy%20will%20probably%20be%20banned.%26quot%3B%3C%2Fspan%3E%3Cbr%20%2F%3E%3Cbr%20%2F%3EFrom%20the%20rules%20page%20for%20the%20site.%20Try%20reading%20them.%20Oh%20look%20two%20new%20VPNs%20to%20ban.%3Cbr%2F%3E"));
                // print("%0A%09%09%3Cdiv%20class%3D%22UserDetails%22%3E%0A%09%09%09%3Cinput%20type%3D%22checkbox%22%20name%3D%22post_1990410%22%2F%3E%20%0A%09%09%09%3Cspan%20class%3D%22Subject%22%3E.%20%3C%2Fspan%3E%0A%09%09%09%3Cspan%20class%3D%22UserName%22%3E%3Ca%20href%3D%27mailto%3A.%27%3EChatin%3C%2Fa%3E%20%3C%2Fspan%3E%20%3Cspan%20class%3D%22CapCodeCustom%22%20style%3D%27color%3Apurple%27%3E%23%20MOD%20%23%3C%2Fspan%3E%20%0A%09%09%09%0A%09%09%09%092021%2F08%2F06%2021%3A46%3A44%20%20%0A%09%09%09%09No.%3Ca%20class%3D%22AltLink%22%20href%3D%22https%3A%2F%2Fu18chan.com%2Fboard%2Fu18chan%2Fgc%2Ftopic%2F1902637%231990410%22%3E1990410%3C%2Fa%3E%20%0A%09%09%09%09%0A%09%09%09%09%20%0A%09%09%09%09%09%09%3Ca%20class%3D%22AltLink%22%20href%3D%22javascript%3AEditPost%281990410%2C%20%27Chatin%27%2C%20%27.%27%2C%20%27.%27%2C%20%27%26gt%3B%26gt%3B1982952%5Cn%5Cn%5Bcolor%3Dred%5D%26quot%3BPlease%20refrain%20from%20using%20anonymising%20proxies.%20If%20we%20discover%20you%20are%20using%20one%2C%20your%20proxy%20will%20probably%20be%20banned.%26quot%3B%5B%2Fcolor%5D%5Cn%5CnFrom%20the%20rules%20page%20for%20the%20site.%20Try%20reading%20them.%20Oh%20look%20two%20new%20VPNs%20to%20ban.%27%2C%200%2C%20%27%27%2C%20%27%27%29%3B%22%20title%3D%22Edit%20Post%22%3E%3Cimg%20src%3D%22https%3A%2F%2Fu18chan.com%2Fthemes%2Fdefault%2Fimages%2Ficons%2Fedit_post.png%22%2F%3E%3C%2Fa%3E%20%0A%09%09%09%09%09%09%0A%09%09%09%09%0A%09%09%3C%2Fdiv%3E%0A%09%3Ca%20href%3D%27https%3A%2F%2Fu18chan.com%2Fboard%2Fu18chan%2Fgc%2Ftopic%2F1902637%231982952%27%20class%3D%27PostLink%27%20onclick%3D%27HighlightPost%281982952%29%3B%27%20%0A%09%09%09%09%09%09%09%3E%0A%09%09%09%09%09%09%09%09%20%26gt%3B%26gt%3B1982952%0A%09%09%09%09%09%09%09%20%20%3C%2Fa%3E%3Cbr%20%2F%3E%3Cbr%20%2F%3E%3Cspan%20style%3D%22color%3A%20red%3B%22%3E%26quot%3BPlease%20refrain%20from%20using%20anonymising%20proxies.%20If%20we%20discover%20you%20are%20using%20one%2C%20your%20proxy%20will%20probably%20be%20banned.%26quot%3B%3C%2Fspan%3E%3Cbr%20%2F%3E%3Cbr%20%2F%3EFrom%20the%20rules%20page%20for%20the%20site.%20Try%20reading%20them.%20Oh%20look%20two%20new%20VPNs%20to%20ban.%3Cbr%2F%3E"
                //   .replaceAll('%3C', '<').replaceAll('%20', ' ').replaceAll('%3D', '=').replaceAll('%22', '"')
                // );
              },
              child: Icon(Icons.star_border),
            ))
          ]
        ),
        body: loaded ? Padding(padding: EdgeInsets.symmetric(horizontal: 3.5),child: Scrollbar(
          child: ListView.builder(
            shrinkWrap: true,
            controller: controller,
            itemBuilder: (context, index) {
              return posts.length+1 == index+1 ? SizedBox(height: 140, child: Container(
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
                            if(pages[index].active) {
                              setState(() {
                                custom = pages[index].url;
                              });
                              load();
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Container(
                                color: pages[index].active ? theme.pagesButtons : const Color(0x77f44336),
                                child: AspectRatio(
                                    aspectRatio: 1,
                                    child: Center(
                                        child: Text(pages[index].text)
                                    )
                                )
                            ),
                          )
                      );
                    },
                    itemCount: pages.length,
                  )
              ),) : posts[index].first ? first(context, posts[index]) : Post(pm: posts[index], posts: posts);
            },
            itemCount: posts.length+1,
          ),
        )): Center(
          child: CircularProgressIndicator(color: Colors.red, semanticsLabel: 'Loading'),
        )
    );
  }
}

class Post extends StatefulWidget {
  Post({Key? key, required this.pm, required this.posts}) : super(key: key);

  final PostMeta pm;
  final List<PostMeta> posts;

  @override
  _PostState createState() => new _PostState();
}

class _PostState extends State<Post> {
  bool fullImage = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MyAppTheme theme = Provider.of(context);
    List<Widget> tags = [];
    widget.pm.tags.forEach((element) {
      tags.add(Container(
        margin: EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white10)
        ),
        child: Padding(padding: EdgeInsets.symmetric(vertical: 2, horizontal:4),child: Row(children: [Text('${element.name} ', style: TextStyle(fontSize: 10, color: Colors.white)), element.count != 0 ? Text(element.count.toString(), style: TextStyle(fontSize: 10, color: theme.newsBlockTitleSub)): SizedBox.shrink()])),
      ));
    });

    return Container(
      padding: !widget.posts[widget.pm.index-1].first ? EdgeInsets.symmetric(
          vertical: 3.5,
          horizontal: 7
      ) : EdgeInsets.only(
        bottom: 3.5,
        left: 7,
        right: 7,
        top: 7
      ),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Container(
            padding: EdgeInsets.all(12),
            color: theme.newsBlock,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 3),
                      width: 14.0,
                      height: 14.0,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.red),
                          shape: BoxShape.circle
                      ),
                      child: Center(child: Text(widget.pm.sender[0], style: TextStyle(fontSize: 10))),
                    ),
                    widget.pm.title != '' ? Flexible(child: SelectableText(widget.pm.title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12))) : SizedBox.shrink(),
                    widget.pm.title != '' ? Icon(Icons.arrow_right, color: theme.newsBlockTitleSub) : SizedBox.shrink(),
                    Flexible(child: Text(widget.pm.sender, style: TextStyle(fontSize: 12, color: widget.pm.mail == '' ? theme.newsBlockTitleSub : theme.link))),
                    widget.pm.mail == 'CloudFlare' ? Padding(padding: EdgeInsets.only(left: 3), child: Icon(Icons.cloud_off, size: 12, color: theme.link)) : SizedBox.shrink()
                    // Text(" by ", style: TextStyle(color: theme.newsBlockTitleSub)),
                    // Text(widget.news[index].author, style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                widget.pm.tags.length > 0 ? Padding(padding: EdgeInsets.only(top: 10), child: Align(alignment: Alignment.centerLeft, child: SingleChildScrollView(child: Row(children: tags), scrollDirection: Axis.horizontal),)) : SizedBox.shrink(),
                widget.pm.content != '' ? Padding(padding: EdgeInsets.only(top: 10), child: Row(children: [
                  Flexible(child:
                    Html(
                      style: {
                        "body": Style(
                          margin: EdgeInsets.all(0),
                        )
                      },
                      data: findShit(widget.pm.content),
                      customRender: {
                        "post": (RenderContext context, Widget child) {
                          return Padding(padding: EdgeInsets.symmetric(vertical: 7),
                              child:
                              // Row(children: [
                              //   Text(context.tree.element!.text, style: TextStyle(color: theme.link)),
                              //   Icon(Icons.subdirectory_arrow_left, size: 14)]
                              // )
                              Container(
                                  padding: EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    color: Colors.black26,
                                  ),
                                  child: Column(children: [
                                    Row(
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(right: 3.5),
                                          width: 14.0,
                                          height: 14.0,
                                          decoration: BoxDecoration(
                                              border: Border.all(color: getColor(widget.pm.replies[int.parse(context.tree.element!.text)]!.index)),
                                              shape: BoxShape.circle
                                          ),
                                          child: Center(child: Text(widget.pm.replies[int.parse(context.tree.element!.text)]!.sender[0], style: TextStyle(fontSize: 9))),
                                        ),
                                        Flexible(flex: 2, child: Text(widget.pm.replies[int.parse(context.tree.element!.text)]!.sender, style: TextStyle(fontSize: 12))),
                                        // Text(" by ", style: TextStyle(color: theme.newsBlockTitleSub)),
                                        // Text(widget.news[index].author, style: TextStyle(fontWeight: FontWeight.w700)),
                                        widget.pm.replies[int.parse(context.tree.element!.text)]!.mail == 'CloudFlare' ? Padding(padding: EdgeInsets.only(left: 3), child: Icon(Icons.cloud_off, size: 12)) : SizedBox.shrink()
                                      ],
                                    ),
                                    widget.pm.replies[int.parse(context.tree.element!.text)]!.title != '' ? Padding(padding: EdgeInsets.only(top: 7), child: Align(alignment: Alignment.centerLeft, child: SelectableText(widget.pm.replies[int.parse(context.tree.element!.text)]!.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))) : SizedBox.shrink(),
                                    isNull(widget.pm.replies[int.parse(context.tree.element!.text)]!.content) ? Padding(padding: EdgeInsets.only(top: 7), child: Align(alignment: Alignment.centerLeft, child: SelectableText(widget.pm.replies[int.parse(context.tree.element!.text)]!.content, style: TextStyle(fontSize: 12, color: theme.newsBlockTitleSub)))) : SizedBox.shrink(),
                                    widget.pm.replies[int.parse(context.tree.element!.text)]!.previewImage != '' ? Padding(padding: EdgeInsets.only(top: 10), child: CachedNetworkImage(
                                      imageUrl: widget.pm.replies[int.parse(context.tree.element!.text)]!.previewImage,
                                      imageBuilder: (context, imageProvider) {
                                        return Row(
                                            children: [
                                              ClipRRect(
                                                  borderRadius: BorderRadius.circular(3),
                                                  child: Stack(
                                                    children: [
                                                      Image(image: imageProvider),
                                                      widget.pm.previewImage.endsWith('gif') ? Stack(
                                                        children: <Widget>[
                                                          Positioned(
                                                            left: 1.0,
                                                            top: 2.0,
                                                            child: Icon(Icons.gif, color: Colors.black54, size: 31),
                                                          ),
                                                          Icon(Icons.gif, color: Colors.white, size: 31),
                                                        ],
                                                      ) : SizedBox.shrink()
                                                    ],
                                                  )
                                              )
                                            ]
                                        );
                                      },
                                      placeholder: (context, url) => Container(height: widget.pm.previewImageHeight.toDouble(), child: Center(child: CircularProgressIndicator(color: Colors.red, strokeWidth: 3))),
                                      errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                                    )) : SizedBox.shrink(),
                                    widget.pm.replies[int.parse(context.tree.element!.text)]!.file.length > 0 ? ClipPath(
                                        clipper: ShapeBorderClipper(
                                          shape: BeveledRectangleBorder(
                                              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15))),
                                        ),
                                        child: Container(
                                          margin: EdgeInsets.only(top: 10),
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                              border: Border.all(color: Colors.blueAccent)
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(widget.pm.replies[int.parse(context.tree.element!.text)]!.file[0] == 'Embedded Video' ? Icons.video_label : Icons.file_copy),
                                                  Padding(padding: EdgeInsets.only(left: 10), child: Text(widget.pm.replies[int.parse(context.tree.element!.text)]!.file[0]))
                                                ],
                                              ),
                                              widget.pm.replies[int.parse(context.tree.element!.text)]!.file.length > 1 && widget.pm.replies[int.parse(context.tree.element!.text)]!.file[1] == 'youtube' ? Padding(padding: EdgeInsets.only(top: 10), child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(3),
                                                  child: CachedNetworkImage(
                                                    imageUrl: 'https://i.ytimg.com/vi/${widget.pm.replies[int.parse(context.tree.element!.text)]!.file[2]}/maxresdefault.jpg',
                                                    imageBuilder: (context, imageProvider) {
                                                      return Image(image: imageProvider);
                                                    },
                                                    progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress, color: Colors.red),
                                                    errorWidget: (context, url, error) => SizedBox.shrink(),
                                                  )
                                              )) : SizedBox.shrink()
                                            ],
                                          ),
                                        )
                                    ) : SizedBox.shrink(),
                                    Padding(padding: EdgeInsets.only(top: 7), child: Align(alignment: Alignment.bottomRight, child: Icon(Icons.subdirectory_arrow_left, size: 13, color: theme.newsBlockTitleSub))),
                                  ])
                              )
                          );
                        },
                      },
                      tagsList: Html.tags..addAll(["post"]),
                    )
                    //SelectableText(widget.pm.content)
                  )
                ])) : SizedBox.shrink(),
                //Padding(padding: EdgeInsets.only(top: 10))
                widget.pm.file.length > 0 ? ClipPath(
                    clipper: ShapeBorderClipper(
                      shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15))),
                    ),
                    child: Container(
                      margin: EdgeInsets.only(top: 10),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.blueAccent)
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(widget.pm.file[0] == 'Embedded Video' ? Icons.video_label : Icons.file_copy),
                              Padding(padding: EdgeInsets.only(left: 10), child: Text(widget.pm.file[0]))
                            ],
                          ),
                          widget.pm.file.length > 1 && widget.pm.file[1] == 'youtube' ? Padding(padding: EdgeInsets.only(top: 10), child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: CachedNetworkImage(
                                imageUrl: 'https://img.youtube.com/vi/${widget.pm.file[2]}/hqdefault.jpg',
                                imageBuilder: (context, imageProvider) {
                                  return Image(image: imageProvider);
                                },
                                progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress, color: Colors.red),
                                errorWidget: (context, url, error) => SizedBox.shrink(),
                              )
                          )) : SizedBox.shrink()
                        ],
                      ),
                    )
                ) : SizedBox.shrink(),
                widget.pm.previewImage != '' ? !fullImage ? Padding(padding: EdgeInsets.only(top: 10), child: CachedNetworkImage(
                  imageUrl: widget.pm.previewImage,
                  imageBuilder: (context, imageProvider) {
                    return Row(
                        children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Stack(
                                children: [
                                  GestureDetector(
                                      onLongPress: (){
                                        downloadImage(context, widget.pm.fullImage);
                                      },
                                      onTap: () {
                                        setState(() {
                                          fullImage = !fullImage;
                                        });
                                      },
                                      child: Image(image: imageProvider)
                                  ),
                                  widget.pm.previewImage.endsWith('gif') ? Stack(
                                    children: <Widget>[
                                      Positioned(
                                        left: 1.0,
                                        top: 2.0,
                                        child: Icon(Icons.gif, color: Colors.black54, size: 31),
                                      ),
                                      Icon(Icons.gif, color: Colors.white, size: 31),
                                    ],
                                  ) : SizedBox.shrink()
                                ],
                              )
                          )
                        ]
                    );
                  },
                  placeholder: (context, url) => Container(height: widget.pm.previewImageHeight.toDouble(), child: Center(child: CircularProgressIndicator(color: Colors.red, strokeWidth: 3))),
                  errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                )) : Padding(padding: EdgeInsets.only(top: 10), child: CachedNetworkImage(
                  imageUrl: widget.pm.fullImage,
                  imageBuilder: (context, imageProvider) {
                    return GestureDetector(
                        onLongPress: (){
                          downloadImage(context, widget.pm.fullImage);
                        },
                        onTap: () {
                          setState(() {
                            fullImage = !fullImage;
                          });
                        },
                        child: Image(image: imageProvider)
                    );
                  },
                  progressIndicatorBuilder: (context, url, downloadProgress) => CachedNetworkImage(
                    imageUrl: widget.pm.previewImage,
                    imageBuilder: (context, imageProvider) {
                      return Row(
                          children: [
                            ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Stack(
                                  children: [
                                    GestureDetector(
                                        onLongPress: (){
                                          downloadImage(context, widget.pm.fullImage);
                                        },
                                        onTap: () {
                                          setState(() {
                                            fullImage = !fullImage;
                                          });
                                        },
                                        child: Image(image: imageProvider)
                                    ),
                                    Padding(padding: EdgeInsets.only(top: 10, left: 10), child: CircularProgressIndicator(value: downloadProgress.progress, color: Colors.red, strokeWidth: 3)),
                                    widget.pm.previewImage.endsWith('gif') ? Stack(
                                      children: <Widget>[
                                        Positioned(
                                          left: 1.0,
                                          top: 2.0,
                                          child: Icon(Icons.gif, color: Colors.black54, size: 31),
                                        ),
                                        Icon(Icons.gif, color: Colors.white, size: 31),
                                      ],
                                    ) : SizedBox.shrink()
                                  ],
                                )
                            )
                          ]
                      );
                    },
                    progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress, color: Colors.red),
                    errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                  ),
                  errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                )) : SizedBox.shrink(),

                widget.pm.hasSpoiler && widget.pm.previewImage == '' ? !fullImage ? Padding(padding: EdgeInsets.only(top: 10), child: GestureDetector(
                    onTap: () {
                      setState(() {
                        fullImage = !fullImage;
                      });
                    },
                    onLongPress: (){
                      downloadImage(context, widget.pm.fullImage);
                    },
                    child: Container(decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent)
                    ),height: 100, child: Center(child: Text('Click to open spoiler')))
                )) : Padding(padding: EdgeInsets.only(top: 10), child: CachedNetworkImage(
                  imageUrl: widget.pm.fullImage,
                  imageBuilder: (context, imageProvider) {
                    return GestureDetector(
                        onTap: () {
                          setState(() {
                            fullImage = !fullImage;
                          });
                        },
                        onLongPress: (){
                          downloadImage(context, widget.pm.fullImage);
                        },
                        child: Image(image: imageProvider)
                    );
                  },
                  progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress, color: Colors.red),
                  errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                )) : SizedBox.shrink(),
                Padding(padding: EdgeInsets.only(top: 9), child: Align(alignment: Alignment.centerLeft, child:  Text(widget.pm.timestamp, style: TextStyle(fontWeight: FontWeight.w300, color: Colors.grey, fontSize: 10))))
              ]
            )
          )
      )
    );
  }
}

String findShit(String content){
  return content.replaceAllMapped(RegExp(r'\n>>([0-9]+)\n'), (match){
    return "<post>${match.group(1)}</post>"; //${match.group(0)}
  });
}

void downloadImage(BuildContext context, String url, ){
  SchedulerBinding.instance?.addPostFrameCallback((_) async{
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
          backgroundColor: Colors.black,
          content: const Text('Downloading an image...', style: TextStyle(color: Colors.white))
      ),
    );

    void f() async{
      var httpClient = new HttpClient();
      String dir = '/storage/emulated/0/U-18Chan';
      final myDir = Directory(dir);
      var isThere = await myDir.exists();
      if(!isThere) await myDir.create();
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      File file = new File('$dir/${url.split('/').last}');
      await file.writeAsBytes(bytes);
      scaffold.showSnackBar(
        SnackBar(
            backgroundColor: Colors.black,
            content: const Text('Done', style: TextStyle(color: Colors.white))
        ),
      );
    }

    if (await Permission.storage.isGranted){
      f();
    } else {
      if (await Permission.storage.isPermanentlyDenied) {
        openAppSettings();
      } else {
        print('ref');
        if (await Permission.storage.request().isGranted) {
          f();
        }
      }
    }
  });
}

bool isNull(String text){
  return text.replaceAll('\n', '').replaceAll(' ', '').replaceAll('	', '').length > 0;
}

class PostMeta {
  final String previewImage;
  final String fullImage;
  final String title;
  final int postID;
  final String content;
  final String sender;
  final String mail;
  final bool first;
  final String threadURL;
  final bool hasSpoiler;
  final List<String> file;
  final List<TagMeta> tags;
  final String timestamp;
  final int index;
  final int previewImageHeight;
  final Map<int, PostMeta> replies;

  PostMeta({
    required this.previewImage,
    required this.previewImageHeight,
    required this.fullImage,
    required this.title,
    required this.postID,
    required this.content,
    required this.sender,
    required this.mail,
    required this.first,
    required this.threadURL,
    required this.hasSpoiler,
    required this.file,
    required this.tags,
    required this.timestamp,
    required this.index,
    required this.replies,
  });
}

class ThreadMeta {
  final int threadID;
  final String threadURL;

  ThreadMeta({
    required this.threadID,
    required this.threadURL
  });
}

class TagMeta {
  final String name;
  final int count;

  TagMeta({
    required this.name,
    required this.count
  });
}