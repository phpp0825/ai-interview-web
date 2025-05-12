import 'package:flutter/material.dart';

class DatePickerWidget extends StatefulWidget {
  final String label;
  final String initialValue;
  final Function(String) onChanged;
  final bool isRequired;

  const DatePickerWidget({
    Key? key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.isRequired = false,
  }) : super(key: key);

  @override
  State<DatePickerWidget> createState() => _DatePickerWidgetState();
}

class _DatePickerWidgetState extends State<DatePickerWidget> {
  late int selectedYear;
  late int selectedMonth;

  // 년도 범위: 1980년부터 현재 년도까지
  final int startYear = 1980;
  final int endYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();

    // 초기값 파싱
    if (widget.initialValue.isNotEmpty) {
      List<String> parts = widget.initialValue.split('-');
      if (parts.length == 2) {
        selectedYear = int.tryParse(parts[0]) ?? endYear;
        selectedMonth = int.tryParse(parts[1]) ?? 1;
      } else {
        selectedYear = endYear;
        selectedMonth = 1;
      }
    } else {
      selectedYear = endYear;
      selectedMonth = 1;

      // 초기값이 비어있으면 현재 날짜로 설정하고 콜백 호출
      _updateValue();
    }
  }

  // 값 업데이트 및 콜백 호출
  void _updateValue() {
    final formattedMonth = selectedMonth.toString().padLeft(2, '0');
    final dateString = '$selectedYear-$formattedMonth';
    widget.onChanged(dateString);
  }

  @override
  Widget build(BuildContext context) {
    // 년도 목록 생성
    final List<int> years = List.generate(
      endYear - startYear + 1,
      (index) => startYear + index,
    );

    // 월 목록 생성
    final List<int> months = List.generate(12, (index) => index + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 필수 항목 표시를 위한 레이블
        if (widget.isRequired)
          _buildRequiredLabel(widget.label)
        else
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            // 년도 드롭다운
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonFormField<int>(
                  value: selectedYear,
                  items: years.reversed.map((year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text('$year년'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedYear = value;
                      });
                      _updateValue();
                    }
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  icon: const Icon(Icons.arrow_drop_down),
                  isExpanded: true,
                  dropdownColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 월 드롭다운
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonFormField<int>(
                  value: selectedMonth,
                  items: months.map((month) {
                    return DropdownMenuItem<int>(
                      value: month,
                      child: Text('$month월'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedMonth = value;
                      });
                      _updateValue();
                    }
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  icon: const Icon(Icons.arrow_drop_down),
                  isExpanded: true,
                  dropdownColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 필수 정보 레이블 생성 함수
  Widget _buildRequiredLabel(String label) {
    return Row(
      children: [
        Text(
          label,
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
