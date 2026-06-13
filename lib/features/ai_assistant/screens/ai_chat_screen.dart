import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/product_model.dart';
import '../providers/ai_assistant_provider.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _stt = SpeechToText();
  bool _isListening = false;
  bool _sttAvailable = false;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _sttAvailable = await _stt.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? override]) async {
    final text = override ?? _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    await ref.read(aiAssistantProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _toggleListening() async {
    if (!_sttAvailable) return;
    if (_isListening) {
      await _stt.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _stt.listen(
        onResult: (result) {
          _textCtrl.text = result.recognizedWords;
          if (result.finalResult) setState(() => _isListening = false);
        },
        listenOptions: SpeechListenOptions(listenFor: const Duration(seconds: 30), localeId: 'en_IN'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(aiAssistantProvider);
    if (messages.length != _lastMessageCount) {
      _lastMessageCount = messages.length;
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OmniCart AI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text('Powered by Gemini', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => ref.read(aiAssistantProvider.notifier).clearChat(),
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              itemCount: messages.length,
              itemBuilder: (_, i) => _AnimatedMessageBubble(
                key: ValueKey(messages[i].id),
                message: messages[i],
                onQuickReply: _send,
                onAddToCart: (products) {
                  ref.read(aiAssistantProvider.notifier).addAllToCart(products);
                  final label = products.length == 1
                      ? '${products.first.title} added to cart'
                      : '${products.length} items added to cart';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(label),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                onCheckout: () => context.push('/checkout'),
                onProductTap: (p) => _send('Tell me more about ${p.title}'),
              ),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() => Container(
        padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: Row(
          children: [
            if (_sttAvailable)
              GestureDetector(
                onTap: _toggleListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red.shade400 : AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_outlined,
                    color: _isListening ? Colors.white : AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textCtrl,
                  decoration: InputDecoration(
                    hintText: _isListening ? 'Listening...' : 'Ask me anything...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      );
}

// ─── Animated message wrapper ────────────────────────────────────────────────

class _AnimatedMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final ValueChanged<String> onQuickReply;
  final ValueChanged<List<Product>> onAddToCart;
  final VoidCallback onCheckout;
  final ValueChanged<Product> onProductTap;

  const _AnimatedMessageBubble({
    super.key,
    required this.message,
    required this.onQuickReply,
    required this.onAddToCart,
    required this.onCheckout,
    required this.onProductTap,
  });

  @override
  State<_AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<_AnimatedMessageBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    final isUser = widget.message.isUser;
    _slide = Tween<Offset>(
      begin: Offset(isUser ? 0.3 : -0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _MessageBubble(
          message: widget.message,
          onQuickReply: widget.onQuickReply,
          onAddToCart: widget.onAddToCart,
          onCheckout: widget.onCheckout,
          onProductTap: widget.onProductTap,
        ),
      ),
    );
  }
}

// ─── Message bubble (stateful for product selection) ─────────────────────────

class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final ValueChanged<String> onQuickReply;
  final ValueChanged<List<Product>> onAddToCart;
  final VoidCallback onCheckout;
  final ValueChanged<Product> onProductTap;

  const _MessageBubble({
    required this.message,
    required this.onQuickReply,
    required this.onAddToCart,
    required this.onCheckout,
    required this.onProductTap,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  final Set<int> _selectedIds = {};
  bool _addedToCart = false;

  void _toggle(int id) => setState(() {
        if (_selectedIds.contains(id)) {
          _selectedIds.remove(id);
        } else {
          _selectedIds.add(id);
        }
        _addedToCart = false;
      });

  void _selectAll() => setState(() {
        for (final p in widget.message.products) {
          _selectedIds.add(p.id);
        }
        _addedToCart = false;
      });

  void _confirmAdd() {
    final selected = widget.message.products.where((p) => _selectedIds.contains(p.id)).toList();
    if (selected.isEmpty) return;
    widget.onAddToCart(selected);
    setState(() => _addedToCart = true);
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    final products = widget.message.products;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Text bubble
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle),
                  child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 15),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))
                    ],
                  ),
                  child: widget.message.isLoading
                      ? _TypingIndicator()
                      : Text(
                          widget.message.content,
                          style: TextStyle(
                            color: isUser ? Colors.white : AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
            ],
          ),

          // Product selection cards
          if (products.isNotEmpty) ...[
            const SizedBox(height: 8),
            // "Tap to select" hint
            Padding(
              padding: const EdgeInsets.only(left: 38, bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_outlined, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('Tap cards to select, then add to cart',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 38, right: 12),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final p = products[i];
                  return _ProductCard(
                    product: p,
                    selected: _selectedIds.contains(p.id),
                    onToggle: () => _toggle(p.id),
                    onDetail: () => widget.onProductTap(p),
                  );
                },
              ),
            ),
            // Add to cart action bar — animates in when something is selected
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: _selectedIds.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(left: 38, right: 12, top: 10),
                      child: _addedToCart
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.success),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                                  SizedBox(width: 6),
                                  Text('Added to cart!',
                                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: ElevatedButton.icon(
                                    onPressed: _confirmAdd,
                                    icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                                    label: Text(
                                      _selectedIds.length == 1
                                          ? 'Add 1 item to Cart'
                                          : 'Add ${_selectedIds.length} items to Cart',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => setState(() => _selectedIds.clear()),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Clear', style: TextStyle(fontSize: 13)),
                                ),
                              ],
                            ),
                    ),
            ),
          ],

          // Quick reply chips
          if (widget.message.quickReplies.isNotEmpty && !isUser) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.message.quickReplies.map((reply) {
                  final isCheckout = reply.toLowerCase().contains('checkout');
                  final isSelectAll = reply.toLowerCase().contains('add all');
                  return GestureDetector(
                    onTap: () {
                      if (isCheckout) {
                        widget.onCheckout();
                      } else if (isSelectAll && products.isNotEmpty) {
                        _selectAll();
                      } else {
                        widget.onQuickReply(reply);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isCheckout ? AppColors.primary : Colors.white,
                        border: Border.all(color: isCheckout ? AppColors.primary : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))
                        ],
                      ),
                      child: Text(
                        reply,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isCheckout ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Product card (selectable) ────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onDetail;

  const _ProductCard({
    required this.product,
    required this.selected,
    required this.onToggle,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 148,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: selected ? 12 : 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: p.thumbnail,
                    height: 108,
                    width: 148,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 108,
                      color: Colors.grey.shade100,
                      child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 108,
                      color: Colors.grey.shade100,
                      child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
                    ),
                  ),
                ),
                // Info
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.currency(p.discountedPriceInr),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      if (p.discountPercentage > 0)
                        Text(
                          '${p.discountPercentage.round()}% off',
                          style: const TextStyle(fontSize: 10, color: AppColors.success),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                // Detail link
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: GestureDetector(
                    onTap: onDetail,
                    child: Text(
                      'Ask AI about this →',
                      style: TextStyle(fontSize: 10, color: AppColors.primary.withValues(alpha: 0.8)),
                    ),
                  ),
                ),
              ],
            ),
            // Selection overlay badge
            Positioned(
              top: 8,
              right: 8,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: selected
                    ? Container(
                        key: const ValueKey('checked'),
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      )
                    : Container(
                        key: const ValueKey('unchecked'),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
          final scale = 0.6 + 0.4 * (t < 0.5 ? 2 * t : 2 * (1 - t));
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
            ),
          );
        }),
      ),
    );
  }
}
