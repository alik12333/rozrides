import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;

  // Vehicle Details
  final String carName;
  final String model;
  final int year;
  final double pricePerDay;
  final String engineSize;

  // Service Options
  final bool withDriver;
  final bool hasInsurance;

  // Images
  final List<String> images;

  // Status
  final String status; // draft, pending, approved, rejected, inactive
  final DateTime createdAt;
  final DateTime updatedAt;

  // Location
  final String? city;
  final String? area;

  ListingModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.carName,
    required this.model,
    required this.year,
    required this.pricePerDay,
    required this.engineSize,
    required this.withDriver,
    required this.hasInsurance,
    required this.images,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.city,
    this.area,
  });

  factory ListingModel.fromMap(Map<String, dynamic> map, String id) {
    return ListingModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerPhone: map['ownerPhone'] ?? '',
      carName: map['carName'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? 2020,
      pricePerDay: (map['pricePerDay'] ?? 0).toDouble(),
      engineSize: map['engineSize'] ?? '',
      withDriver: map['withDriver'] ?? false,
      hasInsurance: map['hasInsurance'] ?? false,
      images: List<String>.from(map['images'] ?? []),
      status: map['status'] ?? 'draft',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      city: map['city'],
      area: map['area'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'carName': carName,
      'model': model,
      'year': year,
      'pricePerDay': pricePerDay,
      'engineSize': engineSize,
      'withDriver': withDriver,
      'hasInsurance': hasInsurance,
      'images': images,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'city': city,
      'area': area,
    };
  }
}