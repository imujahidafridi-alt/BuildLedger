import 'package:flutter/foundation.dart';

/// Immutable model representing the registered contractor or business entity.
/// Injected into PDF report headers, supplier statements, and invoices.
@immutable
class ContractorProfile {
  final String name;
  final String taxId;
  final String phone;
  final String email;
  final String address;

  const ContractorProfile({
    this.name = '',
    this.taxId = '',
    this.phone = '',
    this.email = '',
    this.address = '',
  });

  /// Default baseline profile for new installations
  factory ContractorProfile.empty() => const ContractorProfile();

  bool get isConfigured => name.trim().isNotEmpty;

  ContractorProfile copyWith({
    String? name,
    String? taxId,
    String? phone,
    String? email,
    String? address,
  }) {
    return ContractorProfile(
      name: name ?? this.name,
      taxId: taxId ?? this.taxId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'taxId': taxId,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }

  factory ContractorProfile.fromMap(Map<String, dynamic> map) {
    return ContractorProfile(
      name: map['name'] as String? ?? '',
      taxId: map['taxId'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContractorProfile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          taxId == other.taxId &&
          phone == other.phone &&
          email == other.email &&
          address == other.address;

  @override
  int get hashCode =>
      name.hashCode ^
      taxId.hashCode ^
      phone.hashCode ^
      email.hashCode ^
      address.hashCode;
}
