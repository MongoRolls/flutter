import 'package:flutter_test/flutter_test.dart';
import 'package:ke_le_me/features/community/models/care_contact.dart';

void main() {
  test('CareContact round-trip preserves serverRowId', () {
    final c = CareContact(
      id: 'user-peer',
      name: '水友',
      serverRowId: 'clxxxxxxxx',
      relationship: 'friend',
      avatarEmoji: '😊',
    );
    final map = c.toMap();
    final back = CareContact.fromMap(map);
    expect(back.id, 'user-peer');
    expect(back.serverRowId, 'clxxxxxxxx');
  });

  test('CareContact fromMap without serverRowId', () {
    final c = CareContact.fromMap({
      'id': 'a',
      'name': 'b',
      'relationship': 'friend',
      'avatarEmoji': '😊',
    });
    expect(c.serverRowId, isNull);
  });

  test('CareContact friendPushInviteEnabled round-trip', () {
    final c = CareContact(
      id: 'u1',
      name: '水友',
      relationship: 'friend',
      avatarEmoji: '😊',
      friendPushInviteEnabled: true,
    );
    final back = CareContact.fromMap(c.toMap());
    expect(back.friendPushInviteEnabled, isTrue);
  });
}
