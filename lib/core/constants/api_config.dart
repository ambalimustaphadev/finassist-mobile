/// The Flask backend's base URL — the single place every `Api*Repository`
/// (auth, chat, file upload) reads it from, so there's only one value to
/// change rather than several copies drifting apart.
///
/// For physical-device testing, this must be your Mac's LAN IP, not
/// `127.0.0.1`/`localhost` — the phone can't reach your Mac through
/// either of those. Find it with `ipconfig getifaddr en0` in Terminal (or
/// System Settings -> Wi-Fi -> Details on the Mac), then set it here, e.g.:
///
///   const String apiBaseUrl = 'http://192.168.1.23:5002';
///
/// Both the Mac (running `flask run --host=0.0.0.0 --port=5002`) and the
/// phone must be on the same Wi-Fi network. The iOS Simulator and Android
/// emulator can still reach a Mac-local server via `127.0.0.1` /
/// `10.0.2.2` respectively if you ever need that instead.
const String apiBaseUrl = 'http://172.20.10.3:5002';
