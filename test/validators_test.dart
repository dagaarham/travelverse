import 'package:flutter_test/flutter_test.dart';
import 'package:travelverse/core/validators.dart';

void main() {
  group('Email', () {
    test('accepts a valid address', () => expect(Validators.email('aria@gmail.com'), isNull));
    test('rejects empty', () => expect(Validators.email(''), 'Email is required'));
    test('rejects a missing domain', () => expect(Validators.email('aria@'), contains('valid email')));
    test('rejects spaces', () => expect(Validators.email('ar ia@gmail.com'), contains('valid email')));
  });

  group('Mobile number', () {
    test('accepts 10 digits starting 6-9', () => expect(Validators.phone('9876543210'), isNull));
    test('accepts +91 prefix', () => expect(Validators.phone('+91 98765 43210'), isNull));
    test('rejects short numbers', () => expect(Validators.phone('98765'), 'Mobile number must be 10 digits'));
    test('rejects numbers starting with 5', () => expect(Validators.phone('5876543210'), contains('starting with 6-9')));
    test('rejects letters', () => expect(Validators.phone('98765abcde'), contains('only digits')));
  });

  group('Password', () {
    test('accepts a strong password', () => expect(Validators.password('Travel@2026'), isNull));
    test('rejects short', () => expect(Validators.password('Ab@1'), contains('at least 8')));
    test('needs a capital', () => expect(Validators.password('travel@2026'), contains('capital')));
    test('needs a digit', () => expect(Validators.password('Travel@abc'), contains('number')));
    test('needs a symbol', () => expect(Validators.password('Travel2026'), contains('special')));
    test('confirm must match', () => expect(Validators.confirmPassword('Travel@2027', 'Travel@2026'), 'Passwords do not match'));
  });

  group('Name', () {
    test('accepts letters and spaces', () => expect(Validators.name('Prithvi Agarwal'), isNull));
    test('rejects digits', () => expect(Validators.name('R2D2'), contains('only letters')));
    test('rejects too short', () => expect(Validators.name('Al'), contains('at least 3')));
  });

  group('Numbers', () {
    test('travellers within range', () => expect(Validators.intInRange('4', 'Travellers', min: 1, max: 20), isNull));
    test('travellers zero is rejected', () => expect(Validators.intInRange('0', 'Travellers', min: 1, max: 20), 'Travellers must be at least 1'));
    test('budget upper boundary accepted', () => expect(Validators.intInRange('10000000', 'Budget', min: 500, max: 10000000), isNull));
    test('budget over boundary rejected', () => expect(Validators.intInRange('10000001', 'Budget', min: 500, max: 10000000), contains('at most')));
    test('non-numeric rejected', () => expect(Validators.intInRange('abc', 'Budget', min: 500, max: 10000000), contains('whole number')));
  });

  group('Trip dates', () {
    final today = DateTime(2026, 10, 12);
    test('valid range', () => expect(Validators.tripDates(DateTime(2026, 10, 20), DateTime(2026, 10, 23), today: today), isNull));
    test('same-day trip allowed', () => expect(Validators.tripDates(DateTime(2026, 10, 12), DateTime(2026, 10, 12), today: today), isNull));
    test('end before start', () => expect(Validators.tripDates(DateTime(2026, 10, 23), DateTime(2026, 10, 20), today: today), contains('on or after')));
    test('start in the past', () => expect(Validators.tripDates(DateTime(2026, 10, 1), DateTime(2026, 10, 3), today: today), contains('past')));
    test('longer than 30 days', () => expect(Validators.tripDates(DateTime(2026, 11, 1), DateTime(2026, 12, 15), today: today), contains('30 days')));
    test('missing start', () => expect(Validators.tripDates(null, DateTime(2026, 10, 23), today: today), 'Select a start date'));
  });

  group('Free text', () {
    test('review shorter than 20 chars', () => expect(Validators.text('Nice place', 'Review', min: 20, max: 500), contains('at least 20')));
    test('whitespace-only is empty', () => expect(Validators.text('    ', 'Title'), 'Title is required'));
    test('rating required', () => expect(Validators.rating(0, 'cleanliness'), 'Please rate cleanliness'));
  });
}
