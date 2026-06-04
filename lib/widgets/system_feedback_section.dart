import 'package:flutter/material.dart';
import 'package:medbot_ai_app/generated/l10n.dart';

class SystemFeedbackSection extends StatefulWidget {
  final Map<String, dynamic>? initialValue;
  final bool showInput;
  final Future<void> Function(int, String) onSubmit;

  const SystemFeedbackSection({
    Key? key,
    this.initialValue,
    this.showInput = false,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _SystemFeedbackSectionState createState() => _SystemFeedbackSectionState();
}

class _SystemFeedbackSectionState extends State<SystemFeedbackSection> {
  Map<String, dynamic>? feedback;
  late TextEditingController _controller;
  int selectedRating = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    feedback = widget.initialValue;
    if (feedback != null) {
      // 如果有初始值，初始化评分和建议内容
      selectedRating = int.parse(feedback!['rating']);
      _controller = TextEditingController(text: feedback!['comment'] ?? '');
    } else {
      _controller = TextEditingController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_isSubmitting) return;
    final suggestion = _controller.text.trim();
    if (selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).pleaseSelectRating)),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(selectedRating, suggestion);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildStarRating({bool isReadOnly = false}) {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < selectedRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: (isReadOnly || _isSubmitting)
              ? null
              : () {
                  setState(() {
                    selectedRating = index + 1;
                  });
                },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 有初始值时，不显示输入框和提交按钮，星星只读
    if (feedback != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context).rating, style: TextStyle(fontWeight: FontWeight.bold)),
          _buildStarRating(isReadOnly: true),
          SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: Text(
              _controller.text.isNotEmpty ? _controller.text : S.of(context).noSuggestion,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      );
    }

    // 无初始值时显示输入框和提交按钮，星星可操作
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text(S.of(context).rating, style: TextStyle(fontWeight: FontWeight.bold)),
        _buildStarRating(isReadOnly: false),
        SizedBox(height: 10),
        TextField(
          controller: _controller,
          maxLines: 3,
          enabled: !_isSubmitting,
          decoration: InputDecoration(
            hintText: S.of(context).pleaseFillSuggestion,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitFeedback,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(S.of(context).submit),
          ),
        ),
      ],
    );
  }
}
