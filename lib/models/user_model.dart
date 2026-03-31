import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String bodyType;
  final String stylePreference;
  final String climate;
  final List<String> preferredColors;
  final DateTime createdAt;
  final bool onboardingComplete;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.bodyType,
    required this.stylePreference,
    required this.climate,
    required this.preferredColors,
    required this.createdAt,
    required this.onboardingComplete,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bodyType': bodyType,
      'stylePreference': stylePreference,
      'climate': climate,
      'preferredColors': preferredColors,
      'createdAt': createdAt.toIso8601String(),
      'onboardingComplete': onboardingComplete,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      bodyType: map['bodyType'] ?? '',
      stylePreference: map['stylePreference'] ?? '',
      climate: map['climate'] ?? '',
      preferredColors: List<String>.from(map['preferredColors'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      onboardingComplete: map['onboardingComplete'] ?? false,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? bodyType,
    String? stylePreference,
    String? climate,
    List<String>? preferredColors,
    DateTime? createdAt,
    bool? onboardingComplete,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bodyType: bodyType ?? this.bodyType,
      stylePreference: stylePreference ?? this.stylePreference,
      climate: climate ?? this.climate,
      preferredColors: preferredColors ?? this.preferredColors,
      createdAt: createdAt ?? this.createdAt,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }
}
