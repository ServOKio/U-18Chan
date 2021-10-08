import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class FAQ extends StatelessWidget{
  FAQ({Key? key, required this.fag}) : super(key: key);
  final String fag;

  @override
  Widget build(BuildContext context){
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
              "FAQ"
          ),
        ),
        body: SingleChildScrollView(
          child: Html(
            data: fag,
          ),
        )
    );
  }
}