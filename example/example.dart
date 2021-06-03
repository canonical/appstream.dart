import 'package:appstream/appstream.dart';

void main() async {
  var pool = AppstreamPool();
  await pool.load();
  for (var component in pool.components) {
    print(component);
  }
}
