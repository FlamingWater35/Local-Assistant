import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:hive_ce/hive.dart';

class PreferredBackendAdapter extends TypeAdapter<PreferredBackend> {
  @override
  final int typeId = 10;

  @override
  PreferredBackend read(BinaryReader reader) {
    final index = reader.readInt();
    return PreferredBackend.values[index];
  }

  @override
  void write(BinaryWriter writer, PreferredBackend obj) {
    writer.writeInt(obj.index);
  }
}
