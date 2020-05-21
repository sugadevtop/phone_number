class ParseResult {
  final String e164;
  final String type;
  final String international;
  final String national;
  final int countryCode;
  final String errorCode;

  ParseResult._({
    this.e164,
    this.type,
    this.international,
    this.national,
    this.countryCode,
    this.errorCode,
  });

  bool get hasError => errorCode != null;

  factory ParseResult(map) => ParseResult._(
        e164: map['e164'],
        type: map['type'],
        international: map['international'],
        national: map['national'],
        countryCode: map['country_code'],
      );

  factory ParseResult.error(code) => ParseResult._(errorCode: code);

  @override
  String toString() {
    return 'ParseResult{'
        'e164: $e164, '
        'type: $type, '
        'international: $international, '
        'national: $national, '
        'countryCode: $countryCode, '
        'errorCode: $errorCode}';
  }
}
