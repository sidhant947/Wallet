import 'package:hive/hive.dart';

Future<Box<Map>> openBox() async {
  return await Hive.openBox<Map>('dataBox');
}
