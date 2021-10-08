class Shit{

  bool isNull(String text){
    return text.replaceAll('\n', '').replaceAll(' ', '').replaceAll('	', '').length > 0;
  }
}