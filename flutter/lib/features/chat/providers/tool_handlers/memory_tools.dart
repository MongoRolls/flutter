import 'dart:convert';

import '../../../../core/models/memory_fact.dart';
import '../../../../core/services/memory_service.dart';
import '../../services/function_registry.dart';

List<FunctionDefinition> createMemoryTools() {
  return [
    FunctionDefinition(
      name: 'save_health_note',
      description: '保存用户的健康信息、偏好或习惯到长期记忆中。发现用户提到明确的健康信息时主动调用。',
      parameters: {
        'type': 'object',
        'properties': {
          'content': {'type': 'string', 'description': '要保存的信息内容'},
          'category': {
            'type': 'string',
            'enum': ['health', 'preference', 'habit', 'event'],
            'description': '信息类别：health=健康数据, preference=偏好, habit=习惯, event=待关注事件',
          },
          'importance': {
            'type': 'integer',
            'description': '重要性 1-5，默认 3',
          },
        },
        'required': ['content', 'category'],
      },
      handler: (args) async {
        final content = args['content'] as String;
        final category = args['category'] as String;
        final importance = (args['importance'] as num?)?.toInt() ?? 3;
        final fact = MemoryFact(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          category: category,
          content: content,
          createdAt: DateTime.now(),
          importance: importance.clamp(1, 5),
        );
        await MemoryService.instance.addFact(fact);
        return jsonEncode({
          'success': true,
          'saved_content': content,
          'category': category,
        });
      },
    ),
  ];
}
