class RefreshRequest {
  const RefreshRequest({
    required this.refreshToken,
  });

  final String refreshToken;

  Map<String, dynamic> toJson() => {
        'refresh_token': refreshToken,
      };
}
