import 'package:firebase_auth/firebase_auth.dart';

import 'platform_api_service.dart';

PlatformApiService firebasePlatformApi() => PlatformApiService(
  owner: () => FirebaseAuth.instance.currentUser?.uid,
  tokenFor: (uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.uid != uid) return null;
    return user!.getIdToken();
  },
);
