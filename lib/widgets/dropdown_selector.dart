import 'package:flutter/material.dart';

class CustomDropdownSelector extends StatefulWidget {
  final List<String> options;
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const CustomDropdownSelector({
    super.key,
    required this.options,
    required this.label,
    this.value,
    required this.onChanged,
    this.validator,
  });

  @override
  State<CustomDropdownSelector> createState() => _CustomDropdownSelectorState();
}

class _CustomDropdownSelectorState extends State<CustomDropdownSelector> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown(FormFieldState<String> fieldState) {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown(fieldState);
    }
  }

  void _openDropdown(FormFieldState<String> fieldState) {
    _overlayEntry = _createOverlayEntry(fieldState);
    Overlay.of(context)?.insert(_overlayEntry!);
    _isOpen = true;
    setState(() {});
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
    // setState(() {});
  }

  OverlayEntry _createOverlayEntry(FormFieldState<String> fieldState) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height,
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: BoxConstraints(maxHeight: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: widget.options.map((option) {
                  return InkWell(
                    onTap: () {
                      widget.onChanged(option);
                      fieldState.didChange(option); // 通知表单状态更新
                      fieldState.validate();
                      _closeDropdown();
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(option),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _clearSelection(FormFieldState<String> fieldState) {
    widget.onChanged(null);
    fieldState.didChange(null);
    _closeDropdown();
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.validator,
      initialValue: widget.value,
      builder: (fieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: GestureDetector(
                onTap: () => _toggleDropdown(fieldState),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: fieldState.hasError
                          ? Colors.red
                          : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          fieldState.value ?? '请选择${widget.label}',
                          style: TextStyle(
                            color: fieldState.value == null
                                ? Colors.grey.shade500
                                : Colors.black,
                          ),
                        ),
                      ),
                      if (fieldState.value != null)
                        GestureDetector(
                          onTap: () => _clearSelection(fieldState),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.clear,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )
                      else
                        Icon(
                          _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: Colors.grey.shade700,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (fieldState.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 12),
                child: Text(
                  fieldState.errorText ?? '',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

// 下面是示例用法

//   String? _validator(String? value) {
//     if (value == null || value.isEmpty) {
//       return '请选择一个选项'; // 提示错误
//     }
//     return null;
//   }
// CustomDropdownSelector(
//   label: '机构选择',
//   options: ['医院', '企业', '教育机构'],
//   value: _selectedIdentity,
//   onChanged: (val) {
//         print('机构选择: $val');
//         setState(() {
//               selectedIdentity = val;
//         });
//   },
//   validator: _validator,
//   ),