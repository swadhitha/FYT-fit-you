import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/wardrobe_item_model.dart';
import '../models/body_profile_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User operations
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toFirestore());
    } on FirebaseException catch (e) {
      throw 'Failed to create user profile: ${e.message}';
    } catch (e) {
      throw 'Failed to create user profile: ${e.toString()}';
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } on FirebaseException catch (e) {
      throw 'Failed to get user profile: ${e.message}';
    } catch (e) {
      throw 'Failed to get user profile: ${e.toString()}';
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update(data);
    } on FirebaseException catch (e) {
      throw 'Failed to update user profile: ${e.message}';
    } catch (e) {
      throw 'Failed to update user profile: ${e.toString()}';
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      // Delete user document
      await _firestore.collection('users').doc(uid).delete();
      
      // Delete all wardrobe items
      QuerySnapshot wardrobeSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('wardrobe')
          .get();
      
      for (DocumentSnapshot doc in wardrobeSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete body profile
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('body_profile')
          .limit(1)
          .get()
          .then((snapshot) {
        for (DocumentSnapshot doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
      
      // Delete chat history
      QuerySnapshot chatSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('chat_history')
          .get();
      
      for (DocumentSnapshot doc in chatSnapshot.docs) {
        await doc.reference.delete();
      }
    } on FirebaseException catch (e) {
      throw 'Failed to delete user data: ${e.message}';
    } catch (e) {
      throw 'Failed to delete user data: ${e.toString()}';
    }
  }

  // Wardrobe operations
  Stream<List<WardrobeItem>> wardrobeStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('wardrobe')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WardrobeItem.fromFirestore(doc.data() as Map<String,dynamic>, doc.id))
            .toList());
  }

  Future<void> addWardrobeItem(WardrobeItem item) async {
    try {
      await _firestore
          .collection('users')
          .doc(item.userId)
          .collection('wardrobe')
          .doc(item.id)
          .set(item.toFirestore());
    } on FirebaseException catch (e) {
      throw 'Failed to add wardrobe item: ${e.message}';
    } catch (e) {
      throw 'Failed to add wardrobe item: ${e.toString()}';
    }
  }

  Future<void> updateWardrobeItem(WardrobeItem item) async {
    try {
      await _firestore
          .collection('users')
          .doc(item.userId)
          .collection('wardrobe')
          .doc(item.id)
          .update(item.toFirestore());
    } on FirebaseException catch (e) {
      throw 'Failed to update wardrobe item: ${e.message}';
    } catch (e) {
      throw 'Failed to update wardrobe item: ${e.toString()}';
    }
  }

  Future<void> deleteWardrobeItem(String uid, String itemId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('wardrobe')
          .doc(itemId)
          .delete();
    } on FirebaseException catch (e) {
      throw 'Failed to delete wardrobe item: ${e.message}';
    } catch (e) {
      throw 'Failed to delete wardrobe item: ${e.toString()}';
    }
  }

  Future<void> toggleFavorite(String uid, String itemId, bool isFavorite) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('wardrobe')
          .doc(itemId)
          .update({'isFavorite': isFavorite});
    } on FirebaseException catch (e) {
      throw 'Failed to update favorite status: ${e.message}';
    } catch (e) {
      throw 'Failed to update favorite status: ${e.toString()}';
    }
  }

  // Body profile operations
  Future<void> saveBodyProfile(String uid, BodyProfile profile) async {
    try {
      // Delete existing profile
      QuerySnapshot existingSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('body_profile')
          .limit(1)
          .get();
      
      for (DocumentSnapshot doc in existingSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Add new profile
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('body_profile')
          .add(profile.toFirestore());
    } on FirebaseException catch (e) {
      throw 'Failed to save body profile: ${e.message}';
    } catch (e) {
      throw 'Failed to save body profile: ${e.toString()}';
    }
  }

  Future<BodyProfile?> getBodyProfile(String uid) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('body_profile')
          .orderBy('analyzedAt', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return BodyProfile.fromFirestore(
          snapshot.docs.first.data() as Map<String,dynamic>, 
          snapshot.docs.first.id);
      }
      return null;
    } on FirebaseException catch (e) {
      throw 'Failed to get body profile: ${e.message}';
    } catch (e) {
      throw 'Failed to get body profile: ${e.toString()}';
    }
  }

  // Chat operations
  Future<void> saveChatMessage(String uid, Map<String, dynamic> message) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('chat_history')
          .add(message);
    } on FirebaseException catch (e) {
      throw 'Failed to save chat message: ${e.message}';
    } catch (e) {
      throw 'Failed to save chat message: ${e.toString()}';
    }
  }

  Stream<List<Map<String, dynamic>>> chatHistoryStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('chat_history')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList());
  }
}
