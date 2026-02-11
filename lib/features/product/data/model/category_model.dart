import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;

  const CategoryModel({required this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(id: map['id'], name: map['name']);
  }

  @override
  List<Object?> get props => [id, name];
}
