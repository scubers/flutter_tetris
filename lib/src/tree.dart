///
/// Created by wangjunren on 2020/10/28
/// Describe:
///

///
/// 路径管理树
class Tree {
  final _root = TreeNode('root', null, 0);

  buildTree(NodePath nodePath) {
    if (nodePath.path.isEmpty) return;

    var count = nodePath.path.length;

    TreeNode current = _root;

    nodePath.path.asMap().forEach((idx, value) {
      TreeNode node;
      if (idx == count - 1) {
        node = TreeNode(value, nodePath.value, idx);
      } else {
        node = TreeNode(value, null, idx);
      }
      current = current.addChild(node);
    });
  }

  TreeResult? findByPath(List<String> path) {
    TreeNode? currentNode = _root;
    var params = <String, String>{};
    TreeNode? finalNode;

    var count = path.length;

    for (var i = 0; i < count; i++) {
      if (currentNode == null) break;

      var value = path[i];

      var existsNode = currentNode._children[value];
      if (existsNode != null) {
        currentNode = existsNode;
      } else if (currentNode._children.length > 0 && currentNode.childIsPlaceholder) {
        currentNode = currentNode._children.values.first;
        params[currentNode.realKey] = value;
      } else {
        currentNode = null;
        break;
      }
      if (i == count - 1) {
        finalNode = currentNode.value == null ? null : currentNode;
      }
    }
    return finalNode == null ? null : TreeResult(params, finalNode);
  }

  removeNodeByPath(List<String> path) {
    var result = findByPath(path);
    if (result == null) return;
    _removeNode(result.node);
  }

  _removeNode(TreeNode node) {
    node.setValue(null);
    if (node._children.isNotEmpty) return;

    var parent = node._parent;
    if (parent != null) {
      parent._removeChild(node.key);
      if (parent.isEndNode) return;
      _removeNode(parent);
    }
  }

  buildTreeByUrlComponent(UrlComponent component) =>
      buildTree(NodePath(component.pathSegments, component.value));

  buildByUrl(Uri uri, dynamic value) => buildTreeByUrlComponent(UrlComponent(uri, value));

  UrlComponent findByUri(Uri uri) {
    var component = UrlComponent(uri, null);
    var result = findByPath(component.pathSegments);
    if (result != null) {
      component.value = result.node.value;
      component.addExtra(result.params);
    }
    return component;
  }
}

class TreeNode {
  final String key;
  dynamic _value;
  final int depth;
  TreeNode? _parent;

  TreeNode(this.key, dynamic value, this.depth) : this._value = value;

  Map<String, TreeNode> _children = {};

  bool get isEndNode => _value != null;

  bool get isPlaceholder => key.startsWith(":");

  bool get childIsPlaceholder => _children.length == 1 && _children.values.first.isPlaceholder;

  bool get isRoot => _parent == null;

  String get realKey => isPlaceholder ? key.substring(1) : key;

  dynamic get value => _value;

  setValue(dynamic value) => _value = value;

  TreeNode addChild(TreeNode node) {
    if (_children.isNotEmpty && _children.values.first.isPlaceholder) {
      // 占位节点不能添加
      assert(false, "Place holder node must be only one");
    }

    if (_children.isNotEmpty && node.isPlaceholder) {
      // 占位节点不能添加
      assert(false, "Place holder node must be only one");
    }

    TreeNode finalNode;
    TreeNode? existsNode = _children[node.key];
    if (existsNode != null) {
      if (node.isEndNode && existsNode.isEndNode) {
        assert(false, "Multiple end pattern: /${existsNode._getPathToRoot().join("/")}");
      }
      if (node.isEndNode) {
        existsNode.setValue(node.value);
      }
      finalNode = existsNode;
    } else {
      _children[node.key] = node;
      finalNode = node;
    }
    finalNode._parent = this;
    return finalNode;
  }

  _removeChild(String key) => _children.remove(key);

  List<String> _getPathToRoot() {
    var list = <String>[];
    TreeNode? current = this;
    while (current?._parent != null) {
      list.add(current!.key);
      current = current._parent;
    }
    return list.reversed.toList();
  }
}

class NodePath {
  final List<String> path;
  final dynamic value;

  NodePath(this.path, this.value);
}

class TreeResult {
  final Map<String, String> params;
  final TreeNode node;

  TreeResult(this.params, this.node);
}

class UrlComponent {
  final Uri _uri;
  dynamic value;
  var _map = <String, dynamic>{};

  Uri get uri => _uri;

  String get scheme => _uri.scheme;

  String get host => _uri.host;

  String get path => _uri.path;

  List<String> get pathSegments => _uri.pathSegments;

  String get queryString => _uri.query;

  Map<String, dynamic> get parameters => _map;

  int get port => _uri.port;

  UrlComponent(Uri uri, this.value)
      : this._uri = uri,
        this._map = Map.of(uri.queryParameters);

  addExtra(Map<String, dynamic> parameters) => _map.addAll(parameters);

  String? getString(String key) {
    var target = _map[key];
    if (target == null) return null;
    return target.toString();
  }

  int? getInt(String key) {
    var target = _map[key];
    if (target == null) return null;
    return int.tryParse(target.toString());
  }

  double? getDouble(String key) {
    var target = _map[key];
    if (target == null) return null;
    return double.tryParse(target.toString());
  }
}
