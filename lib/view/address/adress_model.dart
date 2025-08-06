// address_model.dart
class AddressDetails {
  final String? id;
  final String? name;
  final String? flatRoomArea;
  final String? landmark;
  final String? otherInstructions;
  final String? addressType;
  final double? latitude;
  final double? longitude;

  AddressDetails({
    this.id,
    this.name,
    this.flatRoomArea,
    this.landmark,
    this.otherInstructions,
    this.addressType,
    this.latitude,
    this.longitude,
  });

  factory AddressDetails.fromMap(Map<String, dynamic> map) {
    return AddressDetails(
      id: map['_id'] as String?,
      name: map['Name'] as String?,
      flatRoomArea: map['road'] as String?,
      landmark: map['Landmark'] as String?,
      otherInstructions: map['directions'] as String?,
      addressType: map['type'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'Name': name,
      'road': flatRoomArea,
      'Landmark': landmark,
      'directions': otherInstructions,
      'type': addressType,
      'latitude': latitude,
      'longitude': longitude,
    };
    if (id != null) {
      data['_id'] = id;
    }
    return data;
  }

  AddressDetails copyWith({
    String? id,
    String? name,
    String? flatRoomArea,
    String? landmark,
    String? otherInstructions,
    String? addressType,
    double? latitude,
    double? longitude,
  }) {
    return AddressDetails(
      id: id ?? this.id,
      name: name ?? this.name,
      flatRoomArea: flatRoomArea ?? this.flatRoomArea,
      landmark: landmark ?? this.landmark,
      otherInstructions: otherInstructions ?? this.otherInstructions,
      addressType: addressType ?? this.addressType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}