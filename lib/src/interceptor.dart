import 'package:flutter/cupertino.dart';
import 'router_manager.dart';
import 'tree.dart';

///
/// Created by wangjunren on 2020/10/28
/// Describe:
///

class InterceptorContext {
  final BuildContext buildContext;
  final UrlComponent component;

  InterceptorContext(this.buildContext, this.component);
}

abstract class Interceptor {
  int get priority;

  Future<InterceptorResult> doDecision(InterceptorContext context) =>
      Future.value(InterceptorResult(status: RouterRunInterceptorResultStatus.pass));
}

enum RouterRunInterceptorResultStatus { pass, switched, rejected }

class InterceptorResult {
  final RouterRunInterceptorResultStatus status;
  final RouterWidgetBuilder? builder;
  final String? url;
  final Error? error;
  final Map<String, Object> params;

  InterceptorResult(
      {required this.status, this.builder, this.url, this.error, this.params = const {}});

  static InterceptorResult pass() =>
      InterceptorResult(status: RouterRunInterceptorResultStatus.pass);

  static InterceptorResult rejected(Error error) =>
      InterceptorResult(status: RouterRunInterceptorResultStatus.rejected, error: error);

  static InterceptorResult switched(
      {String? url, RouterWidgetBuilder? builder, Map<String, Object> params = const {}}) {
    assert(url != null || builder != null);
    return InterceptorResult(
      status: RouterRunInterceptorResultStatus.switched,
      url: url,
      builder: builder,
      params: params,
    );
  }
}

class InterceptorManager {
  final _list = <Interceptor>[];
  var _dirty = true;

  add(List<Interceptor> interceptors) {
    _list.addAll(interceptors);
    _dirty = true;
  }

  _resetPriority() {
    if (!_dirty) return;
    _list.sort((a, b) => b.priority - a.priority);
    _dirty = false;
  }

  Future<InterceptorResult> runInterceptor(InterceptorContext context) async {
    _resetPriority();
    if (_list.isEmpty) {
      return InterceptorResult(status: RouterRunInterceptorResultStatus.pass);
    }

    for (var interceptor in _list) {
      var result = await interceptor.doDecision(context);
      switch (result.status) {
        case RouterRunInterceptorResultStatus.pass:
          continue;
        case RouterRunInterceptorResultStatus.switched:
          return InterceptorResult.switched(
            url: result.url,
            builder: result.builder,
            params: result.params,
          );
        case RouterRunInterceptorResultStatus.rejected:
          if (result.error == null) {
            assert(result.error != null);
            throw 'error should not be null';
          }
          return InterceptorResult.rejected(result.error!);
        default:
          assert(false);
      }
    }
    return InterceptorResult.pass();
  }
}
