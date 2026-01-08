import 'package:bamboo_app/src/domain/entities/e_user.dart';
import 'package:bamboo_app/utils/default_user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class UserLoggedEvent {}

class UserLoggedInEvent extends UserLoggedEvent {
  final EntitiesUser user;

  UserLoggedInEvent({required this.user});
}

class UserLoggedOutEvent extends UserLoggedEvent {}

class UserLoggedState {
  final bool isLogged;
  final EntitiesUser user;

  const UserLoggedState({required this.isLogged, required this.user});

  UserLoggedState copyWith({
    bool? isLogged,
    EntitiesUser? user,
  }) {
    return UserLoggedState(
      isLogged: isLogged ?? this.isLogged,
      user: user ?? this.user,
    );
  }
}

class UserLoggedStateBloc extends Bloc<UserLoggedEvent, UserLoggedState> {
  UserLoggedStateBloc()
      : super(UserLoggedState(isLogged: false, user: defaultUser)) {
    on<UserLoggedInEvent>((event, emit) {
      defaultUser = event.user;
      emit(UserLoggedState(isLogged: true, user: event.user));
    });

    on<UserLoggedOutEvent>((event, emit) {
      defaultUser = EntitiesUser(id: '', email: '', name: '');
      emit(UserLoggedState(isLogged: false, user: defaultUser));
    });
  }
}
