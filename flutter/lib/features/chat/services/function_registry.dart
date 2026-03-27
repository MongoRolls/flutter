typedef FunctionHandler = Future<String> Function(Map<String, dynamic> args);

class FunctionDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
  final FunctionHandler handler;

  const FunctionDefinition({
    required this.name,
    required this.description,
    required this.parameters,
    required this.handler,
  });

  Map<String, dynamic> toToolJson() => {
        'type': 'function',
        'function': {
          'name': name,
          'description': description,
          'parameters': parameters,
        },
      };
}

class FunctionRegistry {
  final Map<String, FunctionDefinition> _functions = {};

  void register(FunctionDefinition fn) => _functions[fn.name] = fn;

  List<Map<String, dynamic>> get toolsJson =>
      _functions.values.map((f) => f.toToolJson()).toList();

  Future<String> execute(String name, Map<String, dynamic> args) async {
    final fn = _functions[name];
    if (fn == null) return '{"error": "未知工具: $name"}';
    try {
      return await fn.handler(args);
    } catch (e) {
      return '{"error": "$e"}';
    }
  }
}
