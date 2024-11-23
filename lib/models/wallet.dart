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

  Wallet({
    required this.name,
    required this.number,
    required this.expiry,
  });
}

@HiveType(typeId: 2)
class Loyalty {
  @HiveField(0)
  final String loyalty_name;

  @HiveField(1)
  final String loyalty_number;

  Loyalty({
    required this.loyalty_name,
    required this.loyalty_number,
  });
}

@HiveType(typeId: 3)
class Identity {
  @HiveField(0)
  final String Identity_name;

  @HiveField(1)
  final String Identity_number;

  Identity({
    required this.Identity_name,
    required this.Identity_number,
  });
}
