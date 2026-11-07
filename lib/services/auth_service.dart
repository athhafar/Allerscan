import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static const String webClientId =
      '698258816532-1eeircuhivgv68hohtjiclabt348c4cb.apps.googleusercontent.com';

  static Future<AuthResponse> signInWithGoogle() async {
    final googleUser = await GoogleSignIn(serverClientId: webClientId).signIn();
    if (googleUser == null) throw 'Login dibatalkan';

    final auth = await googleUser.authentication;
    final idToken = auth.idToken;
    if (idToken == null) throw 'ID token tidak ditemukan';

    return Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: auth.accessToken,
    );
  }

  static Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await Supabase.instance.client.auth.signOut();
  }
}
