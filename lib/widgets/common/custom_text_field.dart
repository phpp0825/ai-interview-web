import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final IconData? icon;
  final int? maxLines;
  final TextInputType? keyboardType;
  final String initialValue;
  final Function(String) onChanged;
  final bool isRequired;
  final TextDirection? textDirection;

  const CustomTextField({
    Key? key,
    required this.label,
    this.hint,
    this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.initialValue = '',
    required this.onChanged,
    this.isRequired = false,
    this.textDirection,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // 컨트롤러 초기화
    _controller = TextEditingController(text: widget.initialValue);
    // 커서를 텍스트 끝에 위치
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.initialValue.length),
    );
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 위젯이 업데이트될 때 컨트롤러 갱신 (필요한 경우만)
    if (oldWidget.initialValue != widget.initialValue) {
      final currentPosition = _controller.selection.baseOffset;
      _controller.text = widget.initialValue;
      // 커서 위치 유지 시도
      if (currentPosition >= 0 &&
          currentPosition <= widget.initialValue.length) {
        _controller.selection =
            TextSelection.collapsed(offset: currentPosition);
      } else {
        _controller.selection =
            TextSelection.collapsed(offset: widget.initialValue.length);
      }
    }
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위한 컨트롤러 해제
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 필수 항목 표시를 위한 레이블
        if (widget.isRequired)
          _buildRequiredLabel()
        else
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: widget.hint,
            border: const OutlineInputBorder(),
            prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
            contentPadding: const EdgeInsets.all(16),
            fillColor: Colors.white,
            filled: true,
          ),
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          controller: _controller,
          onChanged: widget.onChanged,
          textDirection: widget.textDirection, // 명시적 텍스트 방향 설정
        ),
      ],
    );
  }

  // 필수 정보 레이블 생성 함수
  Widget _buildRequiredLabel() {
    return Row(
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '* 필수',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}

class CustomDropdown<T> extends StatelessWidget {
  final String? label;
  final Widget? labelWidget;
  final IconData? icon;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const CustomDropdown({
    Key? key,
    this.label,
    this.labelWidget,
    this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  })  : assert(label != null || labelWidget != null,
            'Either label or labelWidget must be provided'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        labelWidget ??
            Text(
              label!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: icon != null ? Icon(icon) : null,
              border: InputBorder.none,
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            icon: const Icon(Icons.arrow_drop_down),
            isExpanded: true,
            dropdownColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
