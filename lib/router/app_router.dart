import 'package:auto_route/auto_route.dart';

import '../presentation/chat_screen.dart';
import '../presentation/settings_screen.dart';
import '../presentation/setup_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SetupRoute.page, initial: true),
    AutoRoute(page: ChatRoute.page),
    AutoRoute(page: SettingsRoute.page),
  ];
}
