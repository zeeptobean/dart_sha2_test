class Expected<T> {
  bool success;
  T? data;
  String errorString;

  //private named constructor
  Expected._({
    required this.success,
    this.data,
    this.errorString = '',
  });

  factory Expected.success(T data) {
    return Expected<T>._(
      success: true,
      data: data,
    );
  }

  factory Expected.failure(String error) {
    return Expected<T>._(
      success: false,
      data: null,
      errorString: error,
    );
  }

  bool get isSuccess => success;
  bool get isFailure => !success;
  T? get getData => data;
  String get getErrorString => errorString;

  @override
  String toString() {
    if (isSuccess) {
      return 'Success: Data($data)';
    }
    return 'Failure: $errorString';
  }
}
