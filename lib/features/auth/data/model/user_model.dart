import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String username;
  final String password;
  final String imagePath;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    this.imagePath = '',
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? password,
    String? imagePath,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'image_path': imagePath,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      imagePath: map['image_path'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, username, password, imagePath];
}
