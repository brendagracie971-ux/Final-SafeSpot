import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  // ✅ CREATE USER (FIXED: uses UID instead of random doc)
  Future<void> createUser({
    required String uid,
    required String fullName,
    required String phoneNumber,
    required String gender,
    required String bloodGroup,
  }) async {
    await users.doc(uid).set({
      'uid': uid,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'profileImage': "",
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 🔄 UPDATE USER PROFILE
  Future<void> updateUser({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await users.doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 📌 ADD EMERGENCY CONTACT
  Future<void> addContact({
    required String userId,
    required String name,
    required String phone,
  }) async {
    await users.doc(userId).collection('emergencyContacts').add({
      'name': name,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 📌 GET USER DATA (useful for profile + home)
  Future<DocumentSnapshot> getUser(String uid) async {
    return await users.doc(uid).get();
  }

  // 📌 GET CONTACTS (VERY IMPORTANT for SOS)
  Stream<QuerySnapshot> getContacts(String uid) {
    return users
        .doc(uid)
        .collection('emergencyContacts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 🚨 DELETE CONTACT
  Future<void> deleteContact({
    required String userId,
    required String contactId,
  }) async {
    await users
        .doc(userId)
        .collection('emergencyContacts')
        .doc(contactId)
        .delete();
  }
}