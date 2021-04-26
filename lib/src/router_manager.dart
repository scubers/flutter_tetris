import 'package:flutter/cupertino.dart';
import 'interceptor.dart';
import 'tree.dart';

///
/// Created by wangjunren on 2020/10/28
/// Describe:
///

enum RouterErrorType { intercepted, lost, other }

typedef RouterWidgetBuilder = Widget Function(BuildContext context, UrlComponent component);

class RouterManager {
  final _tree = Tree();

  ///
  /// 注册路由
  bindRoute(String url, RouterWidgetBuilder builder) {
    var uri = Uri.parse(url);
    _tree.buildByUrl(uri, _Holder(builder));
  }

  Future<RouterDest> start(BuildContext context, String url,
      {Map<String, Object> params = const {}, InterceptorManager? interceptorManager}) async {
    try {
      var uri = Uri.parse(url);
      var component = _tree.findByUri(uri);
      component.addExtra(params);
      var result = await (interceptorManager ?? InterceptorManager())
          .runInterceptor(InterceptorContext(context, component));
      switch (result.status) {
        case RouterRunInterceptorResultStatus.pass:
          if (component.value == null) {
            print("Tetris lost: [$url}]");
            throw RouterError(RouterErrorType.lost, null);
          }
          return RouterDest(component, (component.value as _Holder).builder);
        case RouterRunInterceptorResultStatus.switched:
          if (result.url != null) {
            return start(context, result.url!, params: result.params);
          }
          assert(result.builder != null);
          return RouterDest(component, result.builder!);
        case RouterRunInterceptorResultStatus.rejected:
          print("Tetris rejected: [$url}]");
          throw RouterError(RouterErrorType.intercepted, result.error!);
        default:
          throw RouterError(RouterErrorType.other, result.error!);
      }
    } on RouterError catch (e) {
      throw e;
    } catch (error) {
      debugPrint(error.toString());
      throw RouterError(RouterErrorType.other, null);
    }
  }
}

class _Holder {
  final RouterWidgetBuilder builder;

  _Holder(this.builder);
}

class RouterDest {
  final UrlComponent component;
  final RouterWidgetBuilder builder;

  RouterDest(this.component, this.builder);

  Widget build(BuildContext context) {
    return builder(context, component);
  }
}

class RouterError extends Error {
  final RouterErrorType errorType;
  final Error? error;

  RouterError(this.errorType, this.error);

  @override
  String toString() {
    return "$errorType info: $error";
  }
}
