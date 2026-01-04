class ApiMeta {
  const ApiMeta({
    required this.success,
    required this.message,
    this.details,
  });

  final bool success;
  final String message;
  final Map<String, dynamic>? details;

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    return ApiMeta(
      success: json['success'] as bool,
      message: json['message'] as String,
      details: json['details'] as Map<String, dynamic>?,
    );
  }
}

class ApiResponse<T> {
  const ApiResponse({
    required this.meta,
    this.data,
  });

  final ApiMeta meta;
  final T? data;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse(
      meta: ApiMeta.fromJson(json['meta'] as Map<String, dynamic>),
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isSuccess => meta.success;
}
