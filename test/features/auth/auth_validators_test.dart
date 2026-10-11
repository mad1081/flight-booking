import 'package:flutter_test/flutter_test.dart';
import 'package:qanat/features/auth/domain/validators/auth_validators.dart';

void main() {
  test('accepts valid registration data', () {
    expect(AuthValidators.name('Ayan Serik'), isNull);
    expect(AuthValidators.email('ayan@example.com'), isNull);
    expect(AuthValidators.password('Qanat123'), isNull);
    expect(AuthValidators.confirmation('Qanat123', 'Qanat123'), isNull);
  });

  test('rejects malformed registration data', () {
    expect(AuthValidators.name(' '), isNotNull);
    expect(AuthValidators.email('invalid'), isNotNull);
    expect(AuthValidators.password('password'), isNotNull);
    expect(AuthValidators.confirmation('Qanat124', 'Qanat123'), isNotNull);
  });
}
