// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WalletAdapter extends TypeAdapter<Wallet> {
  @override
  final int typeId = 1;

  @override
  Wallet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Wallet(
      name: fields[0] as String,
      number: fields[1] as String,
      expiry: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Wallet obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.number)
      ..writeByte(2)
      ..write(obj.expiry);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LoyaltyAdapter extends TypeAdapter<Loyalty> {
  @override
  final int typeId = 2;

  @override
  Loyalty read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Loyalty(
      loyalty_name: fields[0] as String,
      loyalty_number: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Loyalty obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.loyalty_name)
      ..writeByte(1)
      ..write(obj.loyalty_number);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoyaltyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class IdentityAdapter extends TypeAdapter<Identity> {
  @override
  final int typeId = 3;

  @override
  Identity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Identity(
      Identity_name: fields[0] as String,
      Identity_number: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Identity obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.Identity_name)
      ..writeByte(1)
      ..write(obj.Identity_number);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdentityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
