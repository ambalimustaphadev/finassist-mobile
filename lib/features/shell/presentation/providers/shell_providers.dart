import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which bottom-nav tab is active on the main shell — an index into
/// `AppBottomNavBar`'s items (`chatTabIndex`, `trackTabIndex`,
/// `toolsTabIndex`, `profileTabIndex`). Switching it swaps the shell's body
/// in place rather than pushing a new route, so the bottom nav never
/// disappears the way a full-screen push would make it. Defaults to Chat —
/// FinAssist's landing destination.
final mainTabProvider = StateProvider<int>((ref) => chatTabIndex);

const chatTabIndex = 0;
const trackTabIndex = 1;
const toolsTabIndex = 2;
const profileTabIndex = 3;
