///
/// Created by wangjunren on 2021/7/22
/// Describe:
///

typedef ObjectCreation<T> = T Function();

class Repository {
  static Repository shared = Repository();

  final _singletons = <Type, dynamic>{};
  final _namedService = <String, dynamic>{};

  final _initChain = <Type>[];

  T registerSingleton<T>(ObjectCreation<T> factory) {
    return _watchGenerating(T, () => _singletons[T] = factory());
  }

  T register<T>(String name, ObjectCreation<T> factory) {
    return _watchGenerating(T, () => _namedService[name] = factory());
  }

  T _watchGenerating<T>(Type type, ObjectCreation<T> action) {
    _initChain.add(type);
    T value = action();
    if (_initChain.isNotEmpty) _initChain.removeLast();
    return value;
  }

  T _findForGenerate<T>([String? name]) {
    return _watchGenerating(T, () {
      T? service = find(name);
      if (service == null) {
        final initChainDesc = 'Tetris Repository Dependency Chain ${_currentDependencyChain()}';
        print(initChainDesc);
        assert(false, 'Register ${name ?? T.toString()} first!');
      }
      return service!;
    });
  }

  T? find<T>([String? name]) {
    var service = name != null ? _namedService[name] : _singletons[T];
    if (service == null || !(service is T)) {
      return null;
    }
    return service;
  }

  String _currentDependencyChain() => '[ ${_initChain.map((e) => e.toString()).join(' -> ')} ]';
}

T injection<T>([String? name, Repository? container]) {
  return (container ?? Repository.shared)._findForGenerate(name);
}
