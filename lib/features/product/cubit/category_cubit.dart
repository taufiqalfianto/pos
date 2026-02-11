import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../data/model/category_model.dart';
import '../repository/category_repository.dart';

// States
abstract class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<CategoryModel> categories;
  const CategoryLoaded(this.categories);
  @override
  List<Object?> get props => [categories];
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository _repository;

  CategoryCubit(this._repository) : super(CategoryInitial());

  Future<void> loadCategories() async {
    emit(CategoryLoading());
    try {
      final categories = await _repository.getCategories();
      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError('Gagal memuat kategori: $e'));
    }
  }

  Future<void> addCategory(String name) async {
    try {
      final category = CategoryModel(id: const Uuid().v4(), name: name);
      await _repository.addCategory(category);
      loadCategories();
    } catch (e) {
      emit(CategoryError('Gagal menambah kategori: $e'));
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
      loadCategories();
    } catch (e) {
      emit(CategoryError('Gagal menghapus kategori: $e'));
    }
  }
}
