import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class Rules extends StatelessWidget{
  Rules({Key? key, required this.rules}) : super(key: key);
  final String rules;

  @override
  Widget build(BuildContext context){
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
              "Rules"
          ),
        ),
        body: SingleChildScrollView(
          child: Html(
            customRender: {
              "br": (RenderContext context, Widget child) {
                return Text('fsdfsd');
              },
            },
            data: rules,
          ),
        )
    );
  }
}