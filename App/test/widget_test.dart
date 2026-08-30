// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ecosystem/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_ecosystem/application/settings_service.dart';
import 'package:local_ecosystem/data/security/device_identity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();
    await DeviceIdentityService.instance.getOrCreate();

    await tester.pumpWidget(
      const ProviderScope(child: LocalEcosystemApp()),
    );
    expect(find.byType(LocalEcosystemApp), findsOneWidget);
  });
}
