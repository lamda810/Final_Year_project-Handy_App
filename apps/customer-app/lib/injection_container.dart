import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'core/network/network_info.dart';

import 'data/datasources/remote/auth_remote_datasource.dart';
import 'data/datasources/remote/booking_remote_datasource.dart';
import 'data/datasources/remote/user_remote_datasource.dart';
import 'data/datasources/remote/notification_remote_datasource.dart';

import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/booking_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/repositories/notification_repository_impl.dart';

import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/booking_repository.dart';
import 'domain/repositories/user_repository.dart';
import 'domain/repositories/notification_repository.dart';
import 'domain/repositories/matching_repository.dart';

import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/booking/booking_bloc.dart';
import 'presentation/blocs/user/user_bloc.dart';
import 'presentation/blocs/notification/notification_bloc.dart';
import 'presentation/blocs/chatbot/chatbot_bloc.dart';
import 'data/repositories/matching_repository_impl.dart';

import 'package:dio/dio.dart';
import 'core/network/dio_client.dart';

import 'data/datasources/remote/auth_remote_datasource_impl.dart';
import 'data/datasources/remote/booking_remote_datasource_impl.dart';
import 'data/datasources/remote/user_remote_datasource_impl.dart';
import 'data/datasources/remote/notification_remote_datasource_impl.dart';

final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // External Dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  sl.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  sl.registerSingleton<Connectivity>(Connectivity());

  // Core
  sl.registerSingleton<NetworkInfo>(NetworkInfoImpl(sl<Connectivity>()));

  // Networking
  sl.registerLazySingleton<Dio>(() => Dio());
  sl.registerLazySingleton<DioClient>(
    () => DioClient(dio: sl<Dio>(), secureStorage: sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(dio: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(dio: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(dio: sl<DioClient>().dio),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      sharedPreferences: sl<SharedPreferences>(),
      secureStorage: sl<FlutterSecureStorage>(),
    ),
  );

  sl.registerLazySingleton<BookingRepository>(
    () =>
        BookingRepositoryImpl(remoteDataSource: sl<BookingRemoteDataSource>()),
  );

  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(remoteDataSource: sl<UserRemoteDataSource>()),
  );

  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      remoteDataSource: sl<NotificationRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<MatchingRepository>(
    () => MatchingRepositoryImpl(dio: sl<DioClient>().dio),
  );

  // BLoCs
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );

  sl.registerFactory<BookingBloc>(
    () => BookingBloc(bookingRepository: sl<BookingRepository>()),
  );

  sl.registerFactory<UserBloc>(
    () => UserBloc(userRepository: sl<UserRepository>()),
  );

  sl.registerFactory<NotificationBloc>(
    () =>
        NotificationBloc(notificationRepository: sl<NotificationRepository>()),
  );

  sl.registerFactory<ChatbotBloc>(
    () => ChatbotBloc(matchingRepository: sl<MatchingRepository>()),
  );
}
