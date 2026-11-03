// =============================================================================
// modules/portfolio/presentation/cubit/portfolio_cubit.dart
// -----------------------------------------------------------------------------
// CUBIT DA TELA "PORTFÓLIO E EXPERIÊNCIAS" (edição do próprio perfil).
// Guarda as duas listas e executa as ações. Cada ação devolve a mensagem de
// erro, ou `null` se deu certo, e já atualiza a lista na tela.
// =============================================================================

import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/experience.dart';
import '../../domain/entities/portfolio_item.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../../domain/usecases/portfolio_usecases.dart';

class PortfolioState extends Equatable {
  final List<PortfolioItem> items;
  final List<Experience> experiences;
  final bool isLoading;

  /// Executando uma ação (enviando foto, salvando...)?
  final bool isBusy;
  final String? errorMessage;

  const PortfolioState({
    this.items = const [],
    this.experiences = const [],
    this.isLoading = true,
    this.isBusy = false,
    this.errorMessage,
  });

  PortfolioState copyWith({
    List<PortfolioItem>? items,
    List<Experience>? experiences,
    bool? isLoading,
    bool? isBusy,
    String? errorMessage,
  }) {
    return PortfolioState(
      items: items ?? this.items,
      experiences: experiences ?? this.experiences,
      isLoading: isLoading ?? this.isLoading,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [items, experiences, isLoading, isBusy, errorMessage];
}

@injectable
class PortfolioCubit extends Cubit<PortfolioState> {
  final PortfolioRepository _repository;
  final AddPortfolioPhotoUseCase _addPhoto;
  final AddPortfolioVideoUseCase _addVideo;
  final SaveExperienceUseCase _saveExperience;

  late String _userId;

  PortfolioCubit(this._repository, this._addPhoto, this._addVideo, this._saveExperience)
      : super(const PortfolioState());

  Future<void> load(String userId) async {
    _userId = userId;
    emit(state.copyWith(isLoading: true));
    // As duas consultas começam JUNTAS (mais rápido que uma após a outra).
    final itemsFuture = _repository.getItems(userId);
    final experiencesFuture = _repository.getExperiences(userId);
    final itemsResult = await itemsFuture;
    final experiencesResult = await experiencesFuture;
    if (isClosed) return;

    // Primeira mensagem de erro (se alguma das consultas falhou).
    final error = itemsResult.fold<String?>((failure) => failure.message, (_) => null) ??
        experiencesResult.fold<String?>((failure) => failure.message, (_) => null);

    emit(PortfolioState(
      items: itemsResult.getOrElse((_) => const []),
      experiences: experiencesResult.getOrElse((_) => const []),
      isLoading: false,
      errorMessage: error,
    ));
  }

  Future<String?> addPhoto(Uint8List bytes, String title, String description) async {
    emit(state.copyWith(isBusy: true));
    final result = await _addPhoto(
      AddPhotoParams(userId: _userId, bytes: bytes, title: title, description: description),
    );
    return _finish(result.map((item) => state.copyWith(items: [item, ...state.items])));
  }

  Future<String?> addVideo(String url, String title, String description) async {
    emit(state.copyWith(isBusy: true));
    final result = await _addVideo(
      AddVideoParams(userId: _userId, url: url, title: title, description: description),
    );
    return _finish(result.map((item) => state.copyWith(items: [item, ...state.items])));
  }

  Future<String?> deleteItem(PortfolioItem item) async {
    emit(state.copyWith(isBusy: true));
    final result = await _repository.deleteItem(item);
    return _finish(
      result.map((_) => state.copyWith(items: state.items.where((i) => i.id != item.id).toList())),
    );
  }

  Future<String?> saveExperience(Experience experience) async {
    emit(state.copyWith(isBusy: true));
    final result = await _saveExperience(
      SaveExperienceParams(userId: _userId, experience: experience),
    );
    if (isClosed) return null;
    final error = result.fold<String?>((failure) => failure.message, (_) => null);
    if (error != null) {
      emit(state.copyWith(isBusy: false));
      return error;
    }
    // Recarrega para manter a ordem certa (trabalhos atuais primeiro).
    await load(_userId);
    return null;
  }

  Future<String?> deleteExperience(String experienceId) async {
    emit(state.copyWith(isBusy: true));
    final result = await _repository.deleteExperience(experienceId);
    return _finish(
      result.map(
        (_) => state.copyWith(
          experiences: state.experiences.where((e) => e.id != experienceId).toList(),
        ),
      ),
    );
  }

  /// Aplica o novo estado (sucesso) ou devolve a mensagem de erro.
  String? _finish(Either<Failure, PortfolioState> result) {
    if (isClosed) return null;
    return result.fold<String?>(
      (failure) {
        emit(state.copyWith(isBusy: false));
        return failure.message;
      },
      (newState) {
        emit(newState.copyWith(isBusy: false));
        return null;
      },
    );
  }
}
