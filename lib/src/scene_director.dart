import 'package:flutter/material.dart';
import 'router_manager.dart';
import 'interceptor.dart';

///
/// Created by wangjunren on 4/26/21
/// Describe:
///

class SceneDirector extends StatefulWidget {
  final Widget child;
  final Map<String, RouterWidgetBuilder> Function() routeBuilder;
  final List<Interceptor> interceptors;

  const SceneDirector(
      {Key? key, required this.child, required this.routeBuilder, this.interceptors = const []})
      : super(key: key);

  @override
  SceneDirectorState createState() => SceneDirectorState();

  static SceneDirectorState of(BuildContext context) {
    final value = context.findAncestorStateOfType<SceneDirectorState>();
    if (value == null) {
      throw 'Should wrap Director on the top';
    } else {
      return value;
    }
  }
}

class SceneDirectorState extends State<SceneDirector> {
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

  Future<RouterDest> start(
    BuildContext context, {
    required String url,
    Map<String, dynamic> params = const {},
    List<Interceptor> interceptors = const [],
  }) async {
    return _manager.start(
      context,
      url,
      params: params,
      interceptorManager: InterceptorManager()..add(interceptors)..add(widget.interceptors),
    );
  }

  Future<void> push(
    BuildContext context, {
    required String url,
    Map<String, dynamic> params = const {},
    Route Function(Widget child)? routeBuilder,
    List<Interceptor> interceptors = const [],
  }) async {
    final result = await start(
      context,
      url: url,
      params: params,
      interceptors: interceptors,
    );
    var route = routeBuilder?.call(result.build(context)) ??
        MaterialPageRoute(builder: (context) => result.build(context));
    await Navigator.of(context).push(route);
  }
}
