import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/core/wearables/data/datasources/fitbit_api_datasource.dart';
import 'package:sleepbalance/core/wearables/domain/exceptions/wearable_exception.dart';

/// Manual mock implementation for Dio
class FakeDio implements Dio {
  Response? nextResponse;
  DioException? nextException;
  List<String> requestedUrls = [];
  List<Map<String, dynamic>> requestedHeaders = [];

  void setNextResponse(Response response) {
    nextResponse = response;
    nextException = null;
  }

  void setNextException(DioException exception) {
    nextException = exception;
    nextResponse = null;
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    requestedUrls.add(path);
    if (options?.headers != null) {
      requestedHeaders.add(options!.headers!);
    }

    if (nextException != null) {
      throw nextException!;
    }

    return nextResponse as Response<T>;
  }

  // Stubs for other methods we don't need
  @override
  BaseOptions get options => BaseOptions();

  @override
  set options(BaseOptions value) {}

  @override
  Interceptors get interceptors => Interceptors();

  @override
  HttpClientAdapter get httpClientAdapter =>
      throw UnimplementedError('Not needed for test');

  @override
  set httpClientAdapter(HttpClientAdapter value) {}

  @override
  Transformer get transformer => throw UnimplementedError('Not needed for test');

  @override
  set transformer(Transformer value) {}

  @override
  void close({bool force = false}) {}

  @override
  Future<Response<T>> delete<T>(String path,
          {Object? data,
          Map<String, dynamic>? queryParameters,
          Options? options,
          CancelToken? cancelToken}) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> deleteUri<T>(Uri uri,
          {Object? data,
          Options? options,
          CancelToken? cancelToken}) =>
      throw UnimplementedError();

  @override
  Future<Response> download(String urlPath, dynamic savePath,
          {ProgressCallback? onReceiveProgress,
          Map<String, dynamic>? queryParameters,
          CancelToken? cancelToken,
          bool deleteOnError = true,
          String lengthHeader = Headers.contentLengthHeader,
          Object? data,
          Options? options,
          FileAccessMode? fileAccessMode}) =>
      throw UnimplementedError();

  @override
  Future<Response> downloadUri(Uri uri, dynamic savePath,
          {ProgressCallback? onReceiveProgress,
          CancelToken? cancelToken,
          bool deleteOnError = true,
          String lengthHeader = Headers.contentLengthHeader,
          Object? data,
          Options? options,
          FileAccessMode? fileAccessMode}) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> fetch<T>(RequestOptions requestOptions) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> getUri<T>(Uri uri,
          {Object? data,
          Options? options,
          CancelToken? cancelToken,
          ProgressCallback? onReceiveProgress}) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> head<T>(String path,
          {Object? data,
          Map<String, dynamic>? queryParameters,
          Options? options,
          CancelToken? cancelToken}) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> headUri<T>(Uri uri,
          {Object? data,
          Options? options,
          CancelToken? cancelToken}) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> patch<T>(String path,
          {Object? data,
          Map<String, dynamic>? queryParameters,
          Options? options,
          CancelToken? cancelToken,
          ProgressCallback? onSendProgress,
          ProgressCallback? onReceiveProgress}) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> patchUri<T>(Uri uri,
          {Object? data,
          Options? options,
          CancelToken? cancelToken,
          ProgressCallback? onSendProgress,
          ProgressCallback? onReceiveProgress}) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> post<T>(String path,
          {Object? data,
          Map<String, dynamic>? queryParameters,
          Options? options,
          CancelToken? cancelToken,
          ProgressCallback? onSendProgress,
          ProgressCallback? onReceiveProgress}) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> postUri<T>(Uri uri,
          {Object? data,
          Options? options,
          CancelToken? cancelToken,
          ProgressCallback? onSendProgress,
          ProgressCallback? onReceiveProgress}) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> put<T>(String path,
          {Object? data,
          Map<String, dynamic>? queryParameters,
          Options? options,
          CancelToken? cancelToken,
          ProgressCallback? onSendProgress,
          ProgressCallback? onReceiveProgress}) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> putUri<T>(Uri uri,
          {Object? data,
          Options? options,
          CancelToken? cancelToken,
          ProgressCallback? onSendProgress,
          ProgressCallback? onReceiveProgress}) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> request<T>(String path,
          {Object? data,
          Map<String, dynamic>? queryParameters,
          CancelToken? cancelToken,
          Options? options,
          ProgressCallback? onSendProgress,
          ProgressCallback? onReceiveProgress}) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> requestUri<T>(Uri uri,
          {Object? data,
          CancelToken? cancelToken,
          Options? options,
          ProgressCallback? onSendProgress,
          ProgressCallback? onReceiveProgress}) =>
      throw UnimplementedError();

  @override
  Dio clone({
    BaseOptions? options,
    Interceptors? interceptors,
    HttpClientAdapter? httpClientAdapter,
    Transformer? transformer,
  }) =>
      throw UnimplementedError();
}

void main() {
  late FitbitApiDataSource dataSource;
  late FakeDio fakeDio;

  setUp(() {
    fakeDio = FakeDio();
    dataSource = FitbitApiDataSource(dio: fakeDio);
  });

  group('FitbitApiDataSource', () {
    const userId = 'fitbit-user-123';
    const accessToken = 'test-access-token';
    final testDate = DateTime(2025, 11, 15);

    group('fetchSleepData', () {
      test('returns sleep data on successful response', () async {
        final expectedResponse = {
          'sleep': [
            {
              'dateOfSleep': '2025-11-15',
              'isMainSleep': true,
              'minutesAsleep': 420,
            },
          ],
        };

        fakeDio.setNextResponse(Response(
          data: expectedResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        final result = await dataSource.fetchSleepData(
          userId: userId,
          accessToken: accessToken,
          date: testDate,
        );

        expect(result, equals(expectedResponse));
        expect(
          fakeDio.requestedUrls.first,
          equals('https://api.fitbit.com/1.2/user/$userId/sleep/date/2025-11-15.json'),
        );
      });

      test('includes authorization header with access token', () async {
        fakeDio.setNextResponse(Response(
          data: {'sleep': []},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        await dataSource.fetchSleepData(
          userId: userId,
          accessToken: accessToken,
          date: testDate,
        );

        expect(
          fakeDio.requestedHeaders.first['Authorization'],
          equals('Bearer $accessToken'),
        );
      });

      test('throws WearableException with authentication type on 401', () async {
        fakeDio.setNextException(DioException(
          response: Response(
            statusCode: 401,
            data: {'errors': [{'message': 'Access token expired'}]},
            requestOptions: RequestOptions(path: ''),
          ),
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: ''),
        ));

        expect(
          () => dataSource.fetchSleepData(
            userId: userId,
            accessToken: accessToken,
            date: testDate,
          ),
          throwsA(isA<WearableException>().having(
            (e) => e.errorType,
            'errorType',
            WearableErrorType.authentication,
          )),
        );
      });

      test('throws WearableException with rateLimited type on 429', () async {
        fakeDio.setNextException(DioException(
          response: Response(
            statusCode: 429,
            data: {'errors': [{'message': 'Rate limit exceeded'}]},
            requestOptions: RequestOptions(path: ''),
          ),
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: ''),
        ));

        expect(
          () => dataSource.fetchSleepData(
            userId: userId,
            accessToken: accessToken,
            date: testDate,
          ),
          throwsA(isA<WearableException>().having(
            (e) => e.errorType,
            'errorType',
            WearableErrorType.rateLimited,
          )),
        );
      });

      test('throws WearableException with network type on 500 server error', () async {
        fakeDio.setNextException(DioException(
          response: Response(
            statusCode: 500,
            data: {'errors': [{'message': 'Internal server error'}]},
            requestOptions: RequestOptions(path: ''),
          ),
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: ''),
        ));

        expect(
          () => dataSource.fetchSleepData(
            userId: userId,
            accessToken: accessToken,
            date: testDate,
          ),
          throwsA(isA<WearableException>().having(
            (e) => e.errorType,
            'errorType',
            WearableErrorType.network,
          )),
        );
      });

      test('throws WearableException with network type on connection timeout', () async {
        fakeDio.setNextException(DioException(
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timed out',
          requestOptions: RequestOptions(path: ''),
        ));

        expect(
          () => dataSource.fetchSleepData(
            userId: userId,
            accessToken: accessToken,
            date: testDate,
          ),
          throwsA(isA<WearableException>().having(
            (e) => e.errorType,
            'errorType',
            WearableErrorType.network,
          )),
        );
      });

      test('throws WearableException with unknown type on unexpected error', () async {
        fakeDio.setNextException(DioException(
          response: Response(
            statusCode: 403,
            data: {'errors': [{'message': 'Forbidden'}]},
            requestOptions: RequestOptions(path: ''),
          ),
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: ''),
        ));

        expect(
          () => dataSource.fetchSleepData(
            userId: userId,
            accessToken: accessToken,
            date: testDate,
          ),
          throwsA(isA<WearableException>().having(
            (e) => e.errorType,
            'errorType',
            WearableErrorType.unknown,
          )),
        );
      });
    });

    group('fetchSleepDataRange', () {
      test('fetches data for each day in range', () async {
        final startDate = DateTime(2025, 11, 13);
        final endDate = DateTime(2025, 11, 15);

        fakeDio.setNextResponse(Response(
          data: {'sleep': []},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        final results = await dataSource.fetchSleepDataRange(
          userId: userId,
          accessToken: accessToken,
          startDate: startDate,
          endDate: endDate,
        );

        // 3 days: Nov 13, 14, 15
        expect(results.length, equals(3));
        expect(fakeDio.requestedUrls.length, equals(3));
        expect(
          fakeDio.requestedUrls[0],
          contains('2025-11-13'),
        );
        expect(
          fakeDio.requestedUrls[1],
          contains('2025-11-14'),
        );
        expect(
          fakeDio.requestedUrls[2],
          contains('2025-11-15'),
        );
      });

      test('handles single day range', () async {
        final singleDate = DateTime(2025, 11, 15);

        fakeDio.setNextResponse(Response(
          data: {'sleep': []},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        final results = await dataSource.fetchSleepDataRange(
          userId: userId,
          accessToken: accessToken,
          startDate: singleDate,
          endDate: singleDate,
        );

        expect(results.length, equals(1));
      });
    });
  });
}
