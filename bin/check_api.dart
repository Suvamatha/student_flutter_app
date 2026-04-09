import 'dart:mirrors';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  var pluginClass = reflectClass(FlutterLocalNotificationsPlugin);
  for (var dec in pluginClass.declarations.values) {
    if (dec is MethodMirror && !dec.isPrivate) {
       var params = dec.parameters.map((p) => '${p.isNamed ? "named " : ""}${p.type.reflectedType} ${MirrorSystem.getName(p.simpleName)}').join(', ');
       print('${MirrorSystem.getName(dec.simpleName)}($params)');
    }
  }
}
