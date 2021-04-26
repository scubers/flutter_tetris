import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tetris/flutter_tetris.dart';
import 'package:flutter_tetris/router_manager.dart';

///
/// Created by wangjunren on 4/26/21
/// Describe:
///

class Director extends StatefulWidget {
  final Widget child;
  final Map<String, RouterWidgetBuilder> Function() routeBuilder;
  final List<Interceptor> interceptors;
  final NavigatorState navigator;

  const Director(
      {Key? key,
      required this.child,
      required this.routeBuilder,
      this.interceptors = const [],
      required this.navigator})
      : super(key: key);

  @override
  DirectorState createState() => DirectorState();

  static DirectorState of(BuildContext context) {
    final value = context.findAncestorStateOfType<DirectorState>();
    if (value == null) {
      throw 'Should wrap Director on the top';
    } else {
      return value;
    }
  }
}

class DirectorState extends State<Director> {
  final _manager = RouterManager();

  @override
  void initState() {
    super.initState();
    widget.routeBuilder().forEach(_manager.bindRoute);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  Future<void> push({
    required String url,
    Map<String, Object> params = const {},
    Route Function(Widget child)? routeBuilder,
  }) async {
    final result = await _manager.start(context, url, params: params);
    var route = routeBuilder?.call(result.build(context)) ??
        MaterialPageRoute(builder: (context) => result.build(context));
    await widget.navigator.push(route);
  }
}
