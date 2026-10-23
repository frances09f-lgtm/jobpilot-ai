import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/groq_matching_service.dart';

abstract class DeviceKeyStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}
class SecureDeviceKeyStore implements DeviceKeyStore {
  final _storage = const FlutterSecureStorage();
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
final deviceKeyStoreProvider = Provider<DeviceKeyStore>((ref) => SecureDeviceKeyStore());
final groqServiceProvider = Provider<GroqMatchingService>((ref) {
  final service = GroqMatchingService();
  ref.onDispose(service.close);
  return service;
});
class AiSettings {
  const AiSettings({this.hasKey = false, this.enabled = false});
  final bool hasKey, enabled;
}
final aiSettingsProvider = AsyncNotifierProvider<AiSettingsController, AiSettings>(AiSettingsController.new);
class AiSettingsController extends AsyncNotifier<AiSettings> {
  DeviceKeyStore get store => ref.read(deviceKeyStoreProvider);
  @override
  Future<AiSettings> build() async {
    final key = await store.read('groq_api_key');
    final enabled = await store.read('groq_enabled') == 'true';
    return AiSettings(hasKey: (key ?? '').trim().isNotEmpty, enabled: enabled && (key ?? '').trim().isNotEmpty);
  }
  Future<String> readKey() async => (await store.read('groq_api_key') ?? '').trim();
  Future<void> saveKey(String value) async {
    final key = value.trim();
    if (key.isEmpty) {
      await store.delete('groq_api_key');
      await store.delete('groq_enabled');
      state = const AsyncData(AiSettings());
    } else {
      await store.write('groq_api_key', key);
      state = AsyncData(AiSettings(hasKey: true, enabled: state.value?.enabled ?? false));
    }
  }
  Future<void> setEnabled(bool enabled) async {
    final hasKey = (await readKey()).isNotEmpty;
    await store.write('groq_enabled', '${enabled && hasKey}');
    state = AsyncData(AiSettings(hasKey: hasKey, enabled: enabled && hasKey));
  }
}
