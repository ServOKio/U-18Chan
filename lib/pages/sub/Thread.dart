import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_html/flutter_html.dart';
import 'dart:developer';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'package:ext_storage/ext_storage.dart';
import 'package:dio/dio.dart';
import 'package:device_info/device_info.dart';

import '../../main.dart';
import '../section.dart';
import 'MultiThreads.dart';

class ThreadView extends StatefulWidget {
  ThreadView({Key? key, required this.url, required this.title, required this.fapMode}) : super(key: key);

  final String url;
  final String title;
  final bool fapMode;

  @override
  _ThreadViewState createState() => _ThreadViewState();
}

class _ThreadViewState extends State<ThreadView> {
  bool loaded = false;
  String sectionTitle = "";
  bool error = false;
  List<PostMeta> posts = [];
  late ScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = new ScrollController();
    load();
  }

  void load() async{
    print('load');
    this.setState(() {
      error = false;
    });

    http.Response responce = widget.fapMode ? await http.get(
        Uri.parse(widget.url),
        headers: {'Cookie': 'fap_mode=on'}
    ) : await http.Client().get(Uri.parse(widget.url));

    if(responce.statusCode == 200){
      setState(() {
        loaded = false;
      });
      posts.clear();
      var document = parse(responce.body);
      sectionTitle = document.getElementsByClassName('Title').first.text;

      //First
      String ffullImage = "";
      String fpreviewImage = "";
      String ffileMame = "";
      String ftitle = "";
      String fpostContent = "";
      int fpostID = 0;
      String fsender = "";
      String fmail = "";
      int fpreviewHeight = 0;

      document.getElementById('FirstPost')?.querySelector('.FileDetails a')?.attributes.forEach((key, value) {
        if(key == 'href') ffullImage = value;
      });
      if(document.getElementById('FirstPost') != null && document.getElementById('FirstPost')!.querySelector(".FileDetails a") != null) ffileMame = document.getElementById('FirstPost')!.querySelector(".FileDetails a")!.text;
      document.getElementById('FirstPost')?.querySelector('a img')?.attributes.forEach((key, value) {
        if(key == 'data-original') fpreviewImage = value;
        if(key == 'style'){
          RegExp regExp = new RegExp(r"width: .* height: (.+)px;", caseSensitive: false, multiLine: false);
          Iterable<Match> matches = regExp.allMatches(value);
          fpreviewHeight = int.parse(matches.elementAt(0).group(1).toString());
        }
      });
      ftitle = document.getElementById('FirstPost')!.getElementsByClassName('UserDetails')[0].getElementsByClassName('Subject')[0].text;
      //fpostID = int.parse(document.getElementById('FirstPost')!.getElementsByClassName('UserDetails')[0].getElementsByTagName('a')[0].text);
      if(document.getElementsByClassName('PostDetails')[0].getElementsByClassName('UserName')[0].getElementsByTagName('a').length > 0){
        print('has mail');
        document.getElementsByClassName('PostDetails')[0].getElementsByClassName('UserName')[0].getElementsByTagName('a')[0].attributes.forEach((key, value) {
          if(value.startsWith('/cdn-cgi')) fmail = "CloudFlare";
          if(value.startsWith('mailto:')) fmail = value.replaceAll('mailto:', 'replace');
        });
      }
      document.getElementsByClassName('UserDetails')[0].getElementsByTagName('a').forEach((element) {
        element.attributes.forEach((key, value) {
          if(value.startsWith('javascript:QuotePost')) fpostID = int.parse(element.text);
        });
      });

      List<String> ffile = [];
      document.getElementById('FirstPost')!.getElementsByClassName('PostDetails')[0].getElementsByTagName('span').forEach((element) {
        element.attributes.forEach((key, value) {
          if(key == 'name' && value == 'post_${fpostID}_message_div') fpostContent = element.text;
          if(value == 'UserName') fsender = element.text;
        });
      });
      String ftimestamp = document.getElementById('FirstPost')!.getElementsByClassName('UserDetails')[0].text.split("\n")[4];
      if(document.getElementById('FirstPost')!.getElementsByClassName('FileDetails').length > 0 && fpreviewImage == ''){
        ffile.add(document.getElementById('FirstPost')!.getElementsByClassName('FileDetails')[0].text.replaceAll("\n", '').replaceAll('File: ', ''));
        if(document.getElementById('FirstPost')!.getElementsByTagName('embed').length > 0){
          document.getElementById('FirstPost')!.getElementsByTagName('embed')[0].attributes.forEach((key, value) {
            if(key == 'src' && value.contains('youtube.com')){
              RegExp regExp = new RegExp(r"^https?://.*(?:youtu.be/|v/|u/\\w/|embed/|watch?v=)([^#&?]*).*$", caseSensitive: true, multiLine: false);
              Iterable<Match> matches = regExp.allMatches(value);
              ffile.add('youtube');
              ffile.add(matches.elementAt(0).group(1).toString());
            }
          });
        }
      }

      List<TagMeta> ftags = [];
      if(document.getElementById('FirstPost')!.getElementsByClassName('thread_tag_box_wrapper').length > 0){
        document.getElementById('FirstPost')!.getElementsByClassName('thread_tag_box_wrapper')[0].getElementsByClassName('TagBoxCount').forEach((element) {
          RegExp regExp = new RegExp(r"(.*) \((.*)\)", caseSensitive: false, multiLine: false);
          Iterable<Match> matches = regExp.allMatches(element.text);
          ftags.add(TagMeta(name: matches.elementAt(0).group(1).toString(), count: int.parse(matches.elementAt(0).group(2).toString())));
        });
      }

      posts.add(
        PostMeta(
          fullImage: ffullImage,
          previewImage: fpreviewImage,
          title: ftitle,
          postID: fpostID,
          content: fpostContent,
          sender: fsender,
          mail: fmail,
          hasSpoiler: false,
          timestamp: ftimestamp,
          index: 0,
          file: ffile,
          tags: ftags,
          previewImageHeight: fpreviewHeight,
          replies: {}
        )
      );
      posts.add(
        PostMeta(
          fullImage: ffullImage,
          previewImage: fpreviewImage,
          title: ftitle,
          postID: fpostID,
          content: fpostContent,
          sender: fsender,
          mail: fmail,
          hasSpoiler: false,
          timestamp: ftimestamp,
          index: 0,
          file: ffile,
          tags: ftags,
          previewImageHeight: fpreviewHeight,
          replies: {}
        )
      );

      document.getElementsByClassName('ReplyBoxTable').forEach((element) {
        String previewImage = '';
        String fullImage = '';
        String mail = "";
        String title = element.getElementsByClassName('UserDetails')[0].getElementsByClassName('Subject')[0].text;
        List<String> file = [];
        String sender = element.getElementsByClassName('UserDetails')[0].getElementsByClassName('UserName')[0].text;
        if(element.getElementsByClassName('UserDetails')[0].getElementsByClassName('UserName')[0].getElementsByTagName('a').length > 0){
          element.getElementsByClassName('UserDetails')[0].getElementsByClassName('UserName')[0].getElementsByTagName('a')[0].attributes.forEach((key, value) {
              if(value.startsWith('/cdn-cgi')) mail = "CloudFlare";
              if(value.startsWith('mailto:')) mail = value.replaceAll('mailto:', 'replace');
          });
        }
        int postID = 0;
        element.getElementsByClassName('UserDetails')[0].getElementsByTagName('a').forEach((element) {
          element.attributes.forEach((key, value) {
            if(value.startsWith('javascript:QuotePost')) postID = int.parse(element.text);
          });
        });
        String content = "";
        bool hasSpoiler = false;
        int previewHeight = 0;
        if(element.getElementsByClassName('ReplyContentOuterImage').length > 0){
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
        Map<int, PostMeta> replies = {};
        if(element.getElementsByClassName('ReplyContent').length > 0) element.getElementsByClassName('ReplyContent')[0].getElementsByTagName('span').forEach((element) {
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
                        replies: replies,
                        index: replies.length
                    )});
                  }
                });
              });
            }
          });
        });

        if(element.getElementsByClassName('ReplyContentOuter').length > 0 && element.getElementsByClassName('ReplyContentOuter')[0].getElementsByClassName('FileDetails').length > 0){
          file.add(element.getElementsByClassName('ReplyContentOuter')[0].getElementsByClassName('FileDetails')[0].text.replaceAll("\n", '').replaceAll('File: ', ''));
          if(element.getElementsByClassName('ReplyContentOuter')[0].getElementsByTagName('embed').length > 0){
            element.getElementsByClassName('ReplyContentOuter')[0].getElementsByTagName('embed')[0].attributes.forEach((key, value) {
              if(key == 'src' && value.contains('youtube.com')){
                print('youtube 355345');
                RegExp regExp = new RegExp(r"^https?://.*(?:youtu.be/|v/|u/\\w/|embed/|watch?v=)([^#&?]*).*$", caseSensitive: true, multiLine: false);
                Iterable<Match> matches = regExp.allMatches(value);
                file.add('youtube');
                file.add(matches.elementAt(0).group(1).toString());
              }
            });
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
            fullImage: fullImage,
            previewImage: previewImage,
            title: title == '' ? '' : title,
            postID: postID,
            content: content,
            sender: sender,
            mail: mail,
            hasSpoiler: hasSpoiler,
            timestamp: element.getElementsByClassName('UserDetails')[0].text.split("\n")[4],
            index: posts.length,
            file: file,
            tags: tags,
            previewImageHeight: previewHeight,
            replies: replies
          )
        );
      });

      setState(() {
        loaded = true;
      });
      print('done');
      print('l: ${posts.length}');
    } else {
      setState(() {
        error = true;
      });
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
            border: Border.all(color: Colors.white10)
        ),
        child: Padding(padding: EdgeInsets.symmetric(vertical: 2, horizontal:6),child: Row(children: [Text('${element.name} ', style: TextStyle(fontSize: 10, color: Colors.white)), Text(element.count.toString(), style: TextStyle(fontSize: 10, color: theme.newsBlockTitleSub))])),
      ));
    });

    return pm.previewImage != '' ? CachedNetworkImage(
      imageUrl: pm.previewImage.endsWith('gif') ? pm.fullImage : pm.previewImage,
      imageBuilder: (context, imageProvider) {
        return Container(
          decoration: BoxDecoration(
            backgroundBlendMode: BlendMode.colorBurn,
            color: theme.themeMainColor,
            image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover
            ),
          ),
          child: Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: 5.0,
                sigmaY: 5.0,
              ),
              child:Padding(
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
                                      border: Border.all(color: theme.themeMainColor),
                                      shape: BoxShape.circle
                                  ),
                                  child: Center(child: Text(pm.sender[0], style: TextStyle(fontSize: 9))),
                                ),
                                Flexible(flex: 2, child: Text(pm.sender, style: TextStyle(fontSize: 12))),
                                pm.mail == 'CloudFlare' ? Padding(padding: EdgeInsets.only(left: 3), child: Icon(Icons.cloud_off, size: 12)) : SizedBox.shrink()
                              ],
                            ),
                            Padding(padding: EdgeInsets.only(top: 7), child: Text(pm.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),),
                            Padding(padding: EdgeInsets.only(bottom: 7), child: Text(pm.content, style: TextStyle(fontSize: 12))),
                            pm.tags.length > 0 ? Padding(padding: EdgeInsets.only(top: 7), child: Align(alignment: Alignment.centerLeft, child: SingleChildScrollView(child: Row(children: tags), scrollDirection: Axis.horizontal))) : SizedBox.shrink()
                          ],
                        )
                    )
                  ],
                ),
              ),
            ),
          )
        );
      },
      placeholder: (context, url) => Center(child: CircularProgressIndicator(color: theme.themeMainColor)),
      errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
    )  : Container(
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
                  pm.title != '' ? Padding(padding: EdgeInsets.only(top: 7), child: SelectableText(pm.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),) : SizedBox.shrink(),
                  Padding(padding: EdgeInsets.only(top: 7),
                      child: SelectableText(pm.content, style: TextStyle(fontSize: 12))
                  )
                ],
              )
          ),
        )
    );
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
          Padding(padding: EdgeInsets.only(right: 14), child: GestureDetector(
            onTap: (){
              SchedulerBinding.instance?.addPostFrameCallback((_) {
                controller.animateTo(0, duration: const Duration(milliseconds: 100), curve: Curves.fastOutSlowIn);
              });
            },
            child: Icon(Icons.arrow_upward),
          )),
          Padding(padding: EdgeInsets.only(right: 14), child: GestureDetector(
            onTap: (){
              SchedulerBinding.instance?.addPostFrameCallback((_) {
                controller.animateTo(controller.position.maxScrollExtent, duration: const Duration(milliseconds: 100), curve: Curves.fastOutSlowIn);
              });
            },
            child: Icon(Icons.arrow_downward),
          )),
          // Padding(padding: EdgeInsets.only(right: 14), child: GestureDetector(
          //   onTap: (){
          //     load();
          //   },
          //   child: Icon(Icons.star_border),
          // ))
        ],
      ),
      body: error ? SafeArea(child: Padding(padding: EdgeInsets.all(30), child: Column(
        children: [
          Padding(padding: EdgeInsets.only(bottom: 12), child: Icon(Icons.error_outline)),
          Text("Error loading the thread", style: TextStyle(color: theme.newsBlockTitleSub)),
        ],
      ))) : loaded ? Scrollbar(
        child: ListView.builder(
          controller: controller,
          itemBuilder: (context, index) {
            return index == 0 ? first(context, posts[index]) : Post(pm: posts[index]);
          },
          itemCount: posts.length,
        ),
      ) : SafeArea(child: Padding(padding: EdgeInsets.all(30), child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(padding: EdgeInsets.only(bottom: 12), child: CircularProgressIndicator(color: theme.themeMainColor)),
          Text("Some themes require more time to download and process. Even if the circle has stopped spinning, the page still continues to load.", style: TextStyle(color: theme.newsBlockTitleSub)),
        ],
      )))
    );
  }
}

List<int> openedPosts = [];

class Post extends StatefulWidget {
  Post({Key? key, required this.pm}) : super(key: key);

  final PostMeta pm;

  @override
  _PostState createState() => new _PostState();
}

class _PostState extends State<Post> {
  bool fullImage = false;

  @override
  void initState() {
    super.initState();
    fullImage = openedPosts.contains(widget.pm.postID);
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 3),
                      width: 14.0,
                      height: 14.0,
                      decoration: BoxDecoration(
                          border: Border.all(color: theme.themeMainColor),
                          shape: BoxShape.circle
                      ),
                      child: Center(child: Text(widget.pm.sender[0], style: TextStyle(fontSize: 10))),
                    ),
                    widget.pm.title != '' ? Flexible(child: Text(widget.pm.title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12))) : SizedBox.shrink(),
                    widget.pm.title != '' ? Icon(Icons.arrow_right, color: theme.newsBlockTitleSub) : SizedBox.shrink(),
                    Flexible(child: Text(widget.pm.sender, style: TextStyle(fontSize: 12, color: widget.pm.mail == '' ? theme.newsBlockTitleSub : theme.link))),
                    widget.pm.mail == 'CloudFlare' ? Padding(padding: EdgeInsets.only(left: 3), child: Icon(Icons.cloud_off, size: 12, color: theme.link)) : SizedBox.shrink()
                    // Text(" by ", style: TextStyle(color: theme.newsBlockTitleSub)),
                    // Text(widget.news[index].author, style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                widget.pm.tags.length > 0 ? Padding(padding: EdgeInsets.only(top: 10), child: Align(alignment: Alignment.centerLeft, child: SingleChildScrollView(child: Row(children: tags), scrollDirection: Axis.horizontal),)) : SizedBox.shrink(),
                widget.pm.content  != '' ? Padding(padding: EdgeInsets.only(top: 10), child: Row(children: [
                  Flexible(child: Html(
                    style: {
                      "body": Style(
                        margin: EdgeInsets.all(0),
                      )
                    },
                    data: findShit(widget.pm.content),
                    customRender: {
                      "post": (RenderContext context, Widget child) {
                        return widget.pm.replies[int.parse(context.tree.element!.text)] != null ? Padding(padding: EdgeInsets.symmetric(vertical: 7),
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
                                placeholder: (context, url) => Container(height: widget.pm.previewImageHeight.toDouble(), child: Center(child: CircularProgressIndicator(color: theme.themeMainColor, strokeWidth: 3))),
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
                                              progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress, color: theme.themeMainColor),
                                              errorWidget: (context, url, error) => SizedBox.shrink(),
                                            )
                                        )) : SizedBox.shrink()
                                      ],
                                    ),
                                  )
                              ) : SizedBox.shrink(),
                              Padding(padding: EdgeInsets.only(top: 7), child: Align(alignment: Alignment.bottomRight, child: Icon(Icons.subdirectory_arrow_left, size: 13, color: theme.newsBlockTitleSub)))
                            ])
                          )
                        ) : Text(context.tree.element!.text);
                      },
                    },
                    tagsList: Html.tags..addAll(["post"]),
                  ))
                ])): Padding(padding: EdgeInsets.only(top: 10)),
                widget.pm.file.length > 0 ? Padding(padding: EdgeInsets.only(top: 10), child: ClipPath(
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
                                progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress, color: theme.themeMainColor),
                                errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                              )
                          )) : SizedBox.shrink()
                        ],
                      ),
                    )
                )) : SizedBox.shrink(),
                widget.pm.previewImage != '' ? !fullImage ? Padding(padding: EdgeInsets.only(top: 10), child: CachedNetworkImage(
                  imageUrl: widget.pm.previewImage,
                  imageBuilder: (context, imageProvider) {
                    return ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Stack(
                          children: [
                            GestureDetector(
                                onLongPress: (){
                                  downloadImage(context, widget.pm.fullImage);
                                },
                                onTap: () {
                                  openedPosts.add(widget.pm.postID);
                                  setState(() {
                                    fullImage = true;
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
                    );
                  },
                  placeholder: (context, url) => CircularProgressIndicator(color: theme.themeMainColor, strokeWidth: 3),
                  errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                )) : Padding(padding: EdgeInsets.only(top: 10), child: CachedNetworkImage(
                  imageUrl: widget.pm.fullImage,
                  imageBuilder: (context, imageProvider) {
                    return GestureDetector(
                        onLongPress: (){
                          downloadImage(context, widget.pm.fullImage);
                        },
                        onTap: () {
                          openedPosts.remove(widget.pm.postID);
                          setState(() {
                            fullImage = false;
                          });
                        },
                        child: Image(image: imageProvider)
                    );
                  },
                  progressIndicatorBuilder: (context, url, downloadProgress) => CachedNetworkImage(
                    imageUrl: widget.pm.previewImage,
                    imageBuilder: (context, imageProvider) {
                      return ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Stack(
                            children: [
                              GestureDetector(
                                  onLongPress: (){
                                    downloadImage(context, widget.pm.fullImage);
                                  },
                                  onTap: () {
                                    openedPosts.add(widget.pm.postID);
                                    setState(() {
                                      fullImage = true;
                                    });
                                  },
                                  child: Image(image: imageProvider)
                              ),
                              Padding(padding: EdgeInsets.only(top: 10, left: 10), child: CircularProgressIndicator(value: downloadProgress.progress, color: theme.themeMainColor, strokeWidth: 3)),
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
                      );
                    },
                    progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress, color: theme.themeMainColor),
                    errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                  ),
                  errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                )) : SizedBox.shrink(),
                widget.pm.hasSpoiler && widget.pm.previewImage == '' ? !fullImage ? Padding(padding: EdgeInsets.only(top: 10), child: GestureDetector(
                    onLongPress: (){
                      downloadImage(context, widget.pm.fullImage);
                    },
                    onTap: () {
                      openedPosts.add(widget.pm.postID);
                      setState(() {
                        fullImage = true;
                      });
                    },
                    child: Container(decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent)
                    ),height: 100, child: Center(child: Text('Click to open spoiler')))
                )) : Padding(padding: EdgeInsets.only(top: 10), child: CachedNetworkImage(
                  imageUrl: widget.pm.fullImage,
                  imageBuilder: (context, imageProvider) {
                    return Image(image: imageProvider);
                  },
                  progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress, color: theme.themeMainColor),
                  errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                )) : SizedBox.shrink(),
                Row(children: [Padding(padding: EdgeInsets.only(top: 9), child: Text(widget.pm.timestamp, style: TextStyle(fontWeight: FontWeight.w300, color: theme.themeTimeStamp, fontSize: 10)))])
              ],
            ),
          )
      ),
    );
  }
}

void downloadImage(BuildContext context, String url, ) async{
  final scaffold = ScaffoldMessenger.of(context);
  scaffold.showSnackBar(SnackBar(
      backgroundColor: Colors.black,
      content: const Text('Downloading an image...', style: TextStyle(color: Colors.white))
  ));

  void f() async{
    try{
      //var httpClient = new HttpClient();
      var path = await ExtStorage.getExternalStorageDirectory();
      String dir = '$path/U-18Chan';
      final myDir = Directory(dir);
      var isThere = await myDir.exists();
      if(!isThere) await myDir.create();
      print(isThere.toString());
      //var request = await httpClient.getUrl(Uri.parse(url));
      //var response = await request.close();
      //var bytes = await consolidateHttpClientResponseBytes(response);
      //File file = new File('$dir/${url.split('/').last}');
      await Dio().download(url, '$dir/${url.split('/').last}',
          options: Options(
            headers: {"user-agent": "Mozilla/5.0 (compatible; U-18ChanApp/1.0; + https://servokio.ru/apps)"},
          ),
          onReceiveProgress: (receivedBytes, totalBytes) {
            // setState(() {
            //   downloading = true;
            //   progress =
            //       ((receivedBytes / totalBytes) * 100).toStringAsFixed(0) + "%";
            // });
      });
      //await file.writeAsBytes(bytes);
      scaffold.showSnackBar(
        SnackBar(
            backgroundColor: Colors.black,
            content: const Text('Done', style: TextStyle(color: Colors.white))
        ),
      );
    } catch(e, stack){
      print(e.toString());
      Widget okButton = TextButton(
        child: Text("OK"),
        onPressed: () => Navigator.pop(context, 'OK')
      );

      // set up the AlertDialog
      AlertDialog alert = AlertDialog(
        title: Text("An error occurred while downloading the image"),
        content: Text(e.toString()),
        actions: [
          okButton,
        ],
      );

      // show the dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
    }
  }
  DeviceInfoPlugin deviceInfo = new DeviceInfoPlugin();
  AndroidDeviceInfo build = await deviceInfo.androidInfo;

  if (await Permission.storage.isGranted && (build.version.release == "11" ? await Permission.manageExternalStorage.isGranted : true)){
    print('Has perms');
    f();
  } else {
    if (await Permission.storage.isPermanentlyDenied || (build.version.release == "11" ? await Permission.manageExternalStorage.isPermanentlyDenied : false)) {
      openAppSettings();
    } else {
      print('ref');
      if (await Permission.storage.request().isGranted && (build.version.release == "11" ? await Permission.manageExternalStorage.request().isGranted : true)) {
        f();
      }
    }
  }
}

class PostMeta {
  final String previewImage;
  final String fullImage;
  final String title;
  final int postID;
  final String content;
  final String sender;
  final String mail;
  final bool hasSpoiler;
  final String timestamp;
  final List<String> file;
  final List<TagMeta> tags;
  final int previewImageHeight;
  final int index;
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
    required this.hasSpoiler,
    required this.timestamp,
    required this.file,
    required this.tags,
    required this.replies,
    required this.index
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