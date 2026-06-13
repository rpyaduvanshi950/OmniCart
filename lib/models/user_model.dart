import 'package:equatable/equatable.dart';

class DeliveryAddress {
  final String label;
  final String name;
  final String phone;
  final String address;
  final String city;
  final String pincode;

  const DeliveryAddress({
    this.label = '',
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.pincode,
  });

  Map<String, dynamic> toMap() => {
        'label': label,
        'name': name,
        'phone': phone,
        'address': address,
        'city': city,
        'pincode': pincode,
      };

  factory DeliveryAddress.fromMap(dynamic raw) {
    if (raw is String) {
      // backward-compat: old format was a plain string
      return DeliveryAddress(name: '', phone: '', address: raw, city: '', pincode: '');
    }
    final m = Map<String, dynamic>.from(raw as Map);
    return DeliveryAddress(
      label: m['label'] ?? '',
      name: m['name'] ?? '',
      phone: m['phone'] ?? '',
      address: m['address'] ?? '',
      city: m['city'] ?? '',
      pincode: m['pincode'] ?? '',
    );
  }

  String get displayLine {
    final parts = [if (name.isNotEmpty) name, address, if (city.isNotEmpty) city, if (pincode.isNotEmpty) pincode].join(', ');
    return parts;
  }

  DeliveryAddress copyWith({
    String? label,
    String? name,
    String? phone,
    String? address,
    String? city,
    String? pincode,
  }) =>
      DeliveryAddress(
        label: label ?? this.label,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        city: city ?? this.city,
        pincode: pincode ?? this.pincode,
      );
}

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final List<DeliveryAddress> savedAddresses;
  final bool isAdmin;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.savedAddresses = const [],
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'phoneNumber': phoneNumber,
        'savedAddresses': savedAddresses.map((a) => a.toMap()).toList(),
        'isAdmin': isAdmin,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] ?? '',
        email: map['email'] ?? '',
        displayName: map['displayName'] ?? '',
        photoUrl: map['photoUrl'],
        phoneNumber: map['phoneNumber'],
        savedAddresses: (map['savedAddresses'] as List?)
                ?.map((e) => DeliveryAddress.fromMap(e))
                .toList() ??
            [],
        isAdmin: map['isAdmin'] ?? false,
      );

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    List<DeliveryAddress>? savedAddresses,
  }) =>
      UserModel(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        savedAddresses: savedAddresses ?? this.savedAddresses,
        isAdmin: isAdmin,
      );

  @override
  List<Object?> get props => [uid];
}
