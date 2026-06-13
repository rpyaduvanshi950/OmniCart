import 'package:equatable/equatable.dart';
import 'product_model.dart';

enum MessageRole { user, assistant }

class ChatMessage extends Equatable {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isLoading;
  final List<Product> products;
  final List<String> quickReplies;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isLoading = false,
    this.products = const [],
    this.quickReplies = const [],
  });

  bool get isUser => role == MessageRole.user;

  factory ChatMessage.user(String content) => ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_u',
        content: content,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.assistant(String content, {bool isLoading = false, List<String> quickReplies = const []}) => ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_a',
        content: content,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        isLoading: isLoading,
        quickReplies: quickReplies,
      );

  factory ChatMessage.assistantWithProducts(
    String content,
    List<Product> products, {
    List<String> quickReplies = const [],
  }) =>
      ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ap',
        content: content,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        products: products,
        quickReplies: quickReplies,
      );

  ChatMessage copyWith({
    String? content,
    bool? isLoading,
    List<Product>? products,
    List<String>? quickReplies,
  }) =>
      ChatMessage(
        id: id,
        content: content ?? this.content,
        role: role,
        timestamp: timestamp,
        isLoading: isLoading ?? this.isLoading,
        products: products ?? this.products,
        quickReplies: quickReplies ?? this.quickReplies,
      );

  @override
  List<Object?> get props => [id];
}
