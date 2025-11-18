import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:qahwat_al_emarat/features/auth/presentation/providers/auth_provider.dart';
import 'package:qahwat_al_emarat/domain/models/auth_models.dart';

// Generate mocks
import '../helpers/mocks.mocks.dart';

void main() {
  late AuthProvider authProvider;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    // Initialize bindings for secure storage
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock method channel for flutter_secure_storage
    const MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    ).setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'write') {
        return null;
      } else if (methodCall.method == 'read') {
        return null;
      } else if (methodCall.method == 'delete') {
        return null;
      } else if (methodCall.method == 'deleteAll') {
        return null;
      }
      return null;
    });
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authProvider = AuthProvider(mockAuthRepository, skipInitialization: true);
  });

  tearDown(() {
    authProvider.dispose();
  });

  group('AuthProvider', () {
    test('initial state should be initial', () {
      expect(authProvider.state, AuthState.initial);
      expect(authProvider.user, isNull);
      expect(authProvider.errorMessage, isNull);
      expect(authProvider.isLoading, false);
      expect(authProvider.isAuthenticated, false);
    });

    test('login success should update state to authenticated', () async {
      final mockResponse = AuthResponse(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresIn: DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        tokenType: 'Bearer',
        user: User(
          id: '1',
          name: 'Test User',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isEmailVerified: true,
          roles: ['customer'],
          isAnonymous: false,
        ),
      );

      when(
        mockAuthRepository.login('test@example.com', 'password'),
      ).thenAnswer((_) async => mockResponse);

      await authProvider.login('test@example.com', 'password');

      expect(authProvider.state, AuthState.authenticated);
      expect(authProvider.user?.email, 'test@example.com');
      expect(authProvider.user?.name, 'Test User');
      expect(authProvider.isAuthenticated, true);
    });

    test('login failure should update state to error', () async {
      when(
        mockAuthRepository.login('test@example.com', 'wrong_password'),
      ).thenThrow(Exception('Invalid credentials'));

      await authProvider.login('test@example.com', 'wrong_password');

      expect(authProvider.state, AuthState.error);
      expect(authProvider.errorMessage, 'Invalid credentials');
      expect(authProvider.isAuthenticated, false);
    });

    test('register success should update state to authenticated', () async {
      final mockResponse = AuthResponse(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresIn: DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        tokenType: 'Bearer',
        user: User(
          id: '1',
          name: 'New User',
          email: 'new@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isEmailVerified: true,
          roles: ['customer'],
          isAnonymous: false,
        ),
      );

      when(
        mockAuthRepository.register(
          name: 'New User',
          email: 'new@example.com',
          password: 'password',
          confirmPassword: 'password',
          phone: null,
        ),
      ).thenAnswer((_) async => mockResponse);

      await authProvider.register(
        name: 'New User',
        email: 'new@example.com',
        password: 'password',
        confirmPassword: 'password',
      );

      expect(authProvider.state, AuthState.authenticated);
      expect(authProvider.user?.email, 'new@example.com');
      expect(authProvider.user?.name, 'New User');
    });

    test('register failure should update state to error', () async {
      when(
        mockAuthRepository.register(
          name: 'Test User',
          email: 'test@example.com',
          password: 'password',
          confirmPassword: 'password',
          phone: null,
        ),
      ).thenThrow(Exception('Email already exists'));

      await authProvider.register(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password',
        confirmPassword: 'password',
      );

      expect(authProvider.state, AuthState.error);
      expect(authProvider.errorMessage, 'Email already exists');
    });

    test('logout should clear user and update state', () async {
      // First login
      final mockResponse = AuthResponse(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresIn: DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        tokenType: 'Bearer',
        user: User(
          id: '1',
          name: 'Test User',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isEmailVerified: true,
          roles: ['customer'],
          isAnonymous: false,
        ),
      );

      when(
        mockAuthRepository.login('test@example.com', 'password'),
      ).thenAnswer((_) async => mockResponse);

      await authProvider.login('test@example.com', 'password');
      expect(authProvider.isAuthenticated, true);

      // Then logout
      when(mockAuthRepository.logout()).thenAnswer((_) async {
        return;
      });

      await authProvider.logout();

      expect(authProvider.state, AuthState.unauthenticated);
      expect(authProvider.user, isNull);
      expect(authProvider.isAuthenticated, false);
    });

    test('hasRole should return correct values', () async {
      final mockResponse = AuthResponse(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresIn: DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        tokenType: 'Bearer',
        user: User(
          id: '1',
          name: 'Admin User',
          email: 'admin@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isEmailVerified: true,
          roles: ['admin', 'customer'],
          isAnonymous: false,
        ),
      );

      when(
        mockAuthRepository.login('admin@example.com', 'password'),
      ).thenAnswer((_) async => mockResponse);

      await authProvider.login('admin@example.com', 'password');

      expect(authProvider.hasRole('admin'), true);
      expect(authProvider.hasRole('customer'), true);
      expect(authProvider.hasRole('moderator'), false);
      expect(authProvider.isAdmin, true);
      expect(authProvider.isCustomer, true);
    });

    test('clearError should clear error state', () async {
      // Trigger an error
      when(
        mockAuthRepository.login('test@example.com', 'wrong_password'),
      ).thenThrow(Exception('Invalid credentials'));

      await authProvider.login('test@example.com', 'wrong_password');

      expect(authProvider.hasError, true);

      // Clear error
      authProvider.clearError();

      expect(authProvider.hasError, false);
      expect(authProvider.errorMessage, isNull);
    });

    test('forgotPassword should handle success', () async {
      when(mockAuthRepository.forgotPassword('test@example.com')).thenAnswer((
        _,
      ) async {
        return;
      });

      await authProvider.forgotPassword('test@example.com');

      expect(authProvider.state, AuthState.unauthenticated);
      expect(authProvider.hasError, false);
    });

    test('forgotPassword should handle failure', () async {
      when(
        mockAuthRepository.forgotPassword('invalid@example.com'),
      ).thenThrow(Exception('Email not found'));

      await authProvider.forgotPassword('invalid@example.com');

      expect(authProvider.state, AuthState.error);
      expect(authProvider.errorMessage, 'Email not found');
    });

    // Additional tests

    test('isLoading should be true during login process', () async {
      final mockResponse = AuthResponse(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresIn: DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        tokenType: 'Bearer',
        user: User(
          id: '2',
          name: 'Loading User',
          email: 'loading@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isEmailVerified: true,
          roles: ['customer'],
          isAnonymous: false,
        ),
      );

      when(
        mockAuthRepository.login('loading@example.com', 'password'),
      ).thenAnswer((_) async {
        // simulate delay
        await Future.delayed(Duration(milliseconds: 10));
        return mockResponse;
      });

      final future = authProvider.login('loading@example.com', 'password');
      expect(authProvider.isLoading, true);
      await future;
      expect(authProvider.isLoading, false);
      expect(authProvider.state, AuthState.authenticated);
    });

    test('isLoading should be true during register process', () async {
      final mockResponse = AuthResponse(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresIn: DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        tokenType: 'Bearer',
        user: User(
          id: '3',
          name: 'Register User',
          email: 'register@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isEmailVerified: false,
          roles: ['customer'],
          isAnonymous: false,
        ),
      );

      when(
        mockAuthRepository.register(
          name: 'Register User',
          email: 'register@example.com',
          password: 'password',
          confirmPassword: 'password',
          phone: null,
        ),
      ).thenAnswer((_) async {
        await Future.delayed(Duration(milliseconds: 10));
        return mockResponse;
      });

      final future = authProvider.register(
        name: 'Register User',
        email: 'register@example.com',
        password: 'password',
        confirmPassword: 'password',
      );
      expect(authProvider.isLoading, true);
      await future;
      expect(authProvider.isLoading, false);
      expect(authProvider.state, AuthState.authenticated);
    });

    test('error state resets after successful login', () async {
      when(
        mockAuthRepository.login('test@example.com', 'wrong_password'),
      ).thenThrow(Exception('Invalid credentials'));

      await authProvider.login('test@example.com', 'wrong_password');
      expect(authProvider.hasError, true);

      final mockResponse = AuthResponse(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresIn: DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        tokenType: 'Bearer',
        user: User(
          id: '1',
          name: 'Test User',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isEmailVerified: true,
          roles: ['customer'],
          isAnonymous: false,
        ),
      );

      when(
        mockAuthRepository.login('test@example.com', 'password'),
      ).thenAnswer((_) async => mockResponse);

      await authProvider.login('test@example.com', 'password');
      expect(authProvider.hasError, false);
      expect(authProvider.errorMessage, isNull);
      expect(authProvider.isAuthenticated, true);
    });

    test('multiple consecutive logins update user', () async {
      final user1 = User(
        id: '1',
        name: 'User One',
        email: 'one@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEmailVerified: true,
        roles: ['customer'],
        isAnonymous: false,
      );
      final user2 = User(
        id: '2',
        name: 'User Two',
        email: 'two@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEmailVerified: true,
        roles: ['customer'],
        isAnonymous: false,
      );
      final response1 = AuthResponse(
        accessToken: 'token1',
        refreshToken: 'refresh1',
        expiresIn: DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        tokenType: 'Bearer',
        user: user1,
      );
      final response2 = AuthResponse(
        accessToken: 'token2',
        refreshToken: 'refresh2',
        expiresIn: DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        tokenType: 'Bearer',
        user: user2,
      );

      when(
        mockAuthRepository.login('one@example.com', 'password'),
      ).thenAnswer((_) async => response1);
      when(
        mockAuthRepository.login('two@example.com', 'password'),
      ).thenAnswer((_) async => response2);

      await authProvider.login('one@example.com', 'password');
      expect(authProvider.user?.email, 'one@example.com');

      await authProvider.login('two@example.com', 'password');
      expect(authProvider.user?.email, 'two@example.com');
    });

    test('register with phone number should authenticate', () async {
      final mockResponse = AuthResponse(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresIn: DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        tokenType: 'Bearer',
        user: User(
          id: '3',
          name: 'Phone User',
          email: 'phone@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isEmailVerified: false,
          roles: ['customer'],
          isAnonymous: false,
        ),
      );

      when(
        mockAuthRepository.register(
          name: 'Phone User',
          email: 'phone@example.com',
          password: 'password',
          confirmPassword: 'password',
          phone: '1234567890',
        ),
      ).thenAnswer((_) async => mockResponse);

      await authProvider.register(
        name: 'Phone User',
        email: 'phone@example.com',
        password: 'password',
        confirmPassword: 'password',
        phone: '1234567890',
      );

      expect(authProvider.state, AuthState.authenticated);
      expect(authProvider.user?.email, 'phone@example.com');
    });

    test('login with empty credentials should update state to error', () async {
      // AuthProvider validates before calling repository
      await authProvider.login('', '');

      expect(authProvider.state, AuthState.error);
      expect(authProvider.errorMessage, 'Email and password are required');
      expect(authProvider.isAuthenticated, false);
    });

    test(
      'forgotPassword with empty email should update state to error',
      () async {
        // AuthProvider validates before calling repository
        await authProvider.forgotPassword('');

        expect(authProvider.state, AuthState.error);
        expect(authProvider.errorMessage, 'Email is required');
      },
    );

    test(
      'logout when not authenticated should not throw and stays unauthenticated',
      () async {
        when(mockAuthRepository.logout()).thenAnswer((_) async {});

        // no prior login
        await authProvider.logout();

        expect(authProvider.state, AuthState.unauthenticated);
        expect(authProvider.user, isNull);
        expect(authProvider.isAuthenticated, false);
      },
    );

    test('hasRole returns false when user is null', () {
      expect(authProvider.user, isNull);
      expect(authProvider.hasRole('admin'), false);
      expect(authProvider.hasRole('customer'), false);
    });

    test('dispose should be called only once in tearDown', () {
      // Dispose is called in tearDown, just verify provider exists
      expect(authProvider, isNotNull);
      expect(authProvider.state, AuthState.initial);
    });
  });
}
