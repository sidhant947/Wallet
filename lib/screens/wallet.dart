import 'package:hive/hive.dart';

part 'wallet.g.dart';

@HiveType(typeId: 1)
class Wallet {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String number;

  @HiveField(2)
  final String expiry;

  @HiveField(3)
  final String cvv;

  Wallet({
    required this.name,
    required this.number,
    required this.expiry,
    required this.cvv,
  });
}
