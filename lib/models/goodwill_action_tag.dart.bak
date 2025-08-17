import 'package:flutter/foundation.dart';

@immutable
class GoodwillActionTag {
  final String goodwillActionId;
  final String tagId;

  const GoodwillActionTag({
    required this.goodwillActionId,
    required this.tagId,
  });

  factory GoodwillActionTag.fromJson(Map<String, dynamic> json) {
    return GoodwillActionTag(
      goodwillActionId: json['goodwill_action_id'] as String,
      tagId: json['tag_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goodwill_action_id': goodwillActionId,
      'tag_id': tagId,
    };
  }
}

