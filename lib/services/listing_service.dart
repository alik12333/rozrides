import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/listing_model.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create new listing
  // Create new listing
  Future<String> createListing({
    required String ownerId,
    required String ownerName,
    required String ownerPhone,
    required String carName,
    required String brand,
    required String model,
    required int year,
    required double pricePerDay,
    required String engineSize,
    required int mileage,
    required String fuelType,
    required String transmission,
    required String description,
    required bool withDriver,
    required bool hasInsurance,
    required List<File> images,
    String? city,
    String? area,
  }) async {
    try {
      print('📝 Creating listing...');

      // Create document reference to get ID
      final docRef = _firestore.collection('listings').doc();
      final listingId = docRef.id;

      print('📋 Listing ID: $listingId');
      print('📸 Total images to upload: ${images.length}');

      // Upload ALL images
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        print('📤 Uploading image ${i + 1}/${images.length}...');
        final url = await _uploadImage(listingId, images[i], i);
        imageUrls.add(url);
        print('✅ Image ${i + 1} uploaded: $url');
      }

      print('✅ All ${imageUrls.length} images uploaded successfully');

      // Create listing data
      final listingData = {
        'ownerId': ownerId,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,
        'carName': carName,
        'brand': brand,
        'model': model,
        'year': year,
        'pricePerDay': pricePerDay,
        'engineSize': engineSize,
        'mileage': mileage,
        'fuelType': fuelType,
        'transmission': transmission,
        'description': description,
        'withDriver': withDriver,
        'hasInsurance': hasInsurance,
        'images': imageUrls,
        'status': 'approved', // Auto-approve for now
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'city': city,
        'area': area,
      };

      await docRef.set(listingData);
      print('✅ Listing created successfully: $listingId');

      return listingId;
    } catch (e) {
      print('❌ Error creating listing: $e');
      throw Exception('Failed to create listing: $e');
    }
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(String listingId, File image, int index) async {
    final ref = _storage.ref().child('listings/$listingId/image_$index.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

// Get user's listings
  Future<List<ListingModel>> getUserListings(String userId) async {
    try {
      print('📋 ListingService: Fetching listings for userId: $userId');

      final querySnapshot = await _firestore
          .collection('listings')
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      print('📋 ListingService: Found ${querySnapshot.docs.length} listings');

      final listings = querySnapshot.docs
          .map((doc) {
        print('📋 Document ID: ${doc.id}');
        print('📋 Document data: ${doc.data()}');
        return ListingModel.fromMap(doc.data(), doc.id);
      })
          .toList();

      print('📋 ListingService: Returning ${listings.length} parsed listings');
      return listings;
    } catch (e) {
      print('❌ ListingService: Error fetching user listings: $e');
      return [];
    }
  }

// Get all approved listings
  Future<List<ListingModel>> getAllListings() async {
    try {
      print('🏡 ListingService: Fetching all approved listings');

      final querySnapshot = await _firestore
          .collection('listings')
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      print('🏡 ListingService: Found ${querySnapshot.docs.length} approved listings');

      final listings = querySnapshot.docs
          .map((doc) {
        print('🏡 Document ID: ${doc.id}');
        return ListingModel.fromMap(doc.data(), doc.id);
      })
          .toList();

      print('🏡 ListingService: Returning ${listings.length} parsed listings');
      return listings;
    } catch (e) {
      print('❌ ListingService: Error fetching all listings: $e');
      return [];
    }
  }

  // Delete listing
  Future<void> deleteListing(String listingId) async {
    try {
      // Delete images from storage
      final listRef = _storage.ref().child('listings/$listingId');
      final listResult = await listRef.listAll();

      for (var item in listResult.items) {
        await item.delete();
      }

      // Delete document
      await _firestore.collection('listings').doc(listingId).delete();
      print('✅ Listing deleted: $listingId');
    } catch (e) {
      print('❌ Error deleting listing: $e');
      throw Exception('Failed to delete listing: $e');
    }
  }

  // Update listing status
  Future<void> updateListingStatus(String listingId, String status) async {
    await _firestore.collection('listings').doc(listingId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}