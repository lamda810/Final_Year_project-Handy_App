import 'package:flutter/material.dart';

/// App-wide navigator key so non-widget code (e.g. the Dio client's error
/// interceptor) can navigate — most importantly, to force the user back to
/// login when their session is no longer valid.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
