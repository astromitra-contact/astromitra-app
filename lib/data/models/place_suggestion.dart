class PlaceSuggestion {
  final String displayName;
  final String city;
  final String? state;
  final String? country;

  const PlaceSuggestion({
    required this.displayName,
    required this.city,
    this.state,
    this.country,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      displayName: json['displayName'] as String? ?? json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String?,
      country: json['country'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceSuggestion &&
          runtimeType == other.runtimeType &&
          displayName.toLowerCase() == other.displayName.toLowerCase();

  @override
  int get hashCode => displayName.toLowerCase().hashCode;
}
