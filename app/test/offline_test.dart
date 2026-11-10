// Offline: the chits open from what this phone kept the last time.
import 'package:flutter_test/flutter_test.dart';
import 'package:kuree/core/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    Api.instance.offline = false;
    Api.instance.showingSaved.value = false;
  });

  test('with no network, a kept answer comes back and says so', () async {
    SharedPreferences.setMockInitialValues({
      'kuree.saved::my_kuris:{}': '[{"id":"k1","data":{"name":"5K Chit"}}]',
    });
    Api.instance.offline = true;
    final j = await Api.instance.rpc('my_kuris');
    expect(j, isA<List>());
    expect((j as List).first['id'], 'k1');
    expect(Api.instance.showingSaved.value, isTrue);
  });

  test('with no network and nothing kept, the error stands', () async {
    SharedPreferences.setMockInitialValues({});
    Api.instance.offline = true;
    await expectLater(Api.instance.rpc('my_kuris'), throwsA(isA<ApiError>()));
    expect(Api.instance.showingSaved.value, isFalse);
  });

  test('changes are never answered from the phone', () async {
    SharedPreferences.setMockInitialValues({'kuree.saved::save_kuri:{}': '{}'});
    Api.instance.offline = true;
    await expectLater(Api.instance.rpc('save_kuri'), throwsA(isA<ApiError>()));
  });
}
