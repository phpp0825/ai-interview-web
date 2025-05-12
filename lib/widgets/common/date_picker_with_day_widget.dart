import 'package:flutter/material.dart';

class DatePickerWithDayWidget extends StatefulWidget {
  final String label;
  final String initialValue;
  final Function(String) onChanged;

  const DatePickerWithDayWidget({
    Key? key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<DatePickerWithDayWidget> createState() =>
      _DatePickerWithDayWidgetState();
}

class _DatePickerWithDayWidgetState extends State<DatePickerWithDayWidget> {
  late int selectedYear;
  late int selectedMonth;
  late int selectedDay;

  // 년도 범위: 1980년부터 현재 년도까지
  final int startYear = 1980;
  final int endYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();

    // 초기값 파싱
    if (widget.initialValue.isNotEmpty) {
      List<String> parts = widget.initialValue.split('-');
      if (parts.length == 3) {
        selectedYear = int.tryParse(parts[0]) ?? endYear;
        selectedMonth = int.tryParse(parts[1]) ?? 1;
        selectedDay = int.tryParse(parts[2]) ?? 1;
      } else {
        selectedYear = endYear;
        selectedMonth = 1;
        selectedDay = 1;
      }
    } else {
      selectedYear = endYear;
      selectedMonth = 1;
      selectedDay = 1;
    }
  }

  // 선택한 월의 마지막 일 계산
  int _getLastDayOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  // 값 업데이트 및 콜백 호출
  void _updateValue() {
    final formattedMonth = selectedMonth.toString().padLeft(2, '0');
    final formattedDay = selectedDay.toString().padLeft(2, '0');
    final dateString = '$selectedYear-$formattedMonth-$formattedDay';
    widget.onChanged(dateString);
  }

  // 선택된 월이 변경될 때 일자 조정
  void _adjustDay() {
    final lastDay = _getLastDayOfMonth(selectedYear, selectedMonth);
    if (selectedDay > lastDay) {
      selectedDay = lastDay;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              // 년도 선택
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: _buildYearPicker(),
                ),
              ),
              // 월 선택
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: _buildMonthPicker(),
                ),
              ),
              // 일 선택
              Expanded(
                flex: 2,
                child: _buildDayPicker(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 년도 선택 위젯
  Widget _buildYearPicker() {
    List<int> years =
        List.generate(endYear - startYear + 1, (index) => startYear + index);

    return DropdownButtonHideUnderline(
      child: ButtonTheme(
        alignedDropdown: true,
        child: DropdownButton<int>(
          value: selectedYear,
          items: years
              .map((year) => DropdownMenuItem(
                    value: year,
                    child: Text('$year'),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedYear = value;
                _adjustDay();
              });
              _updateValue();
            }
          },
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
        ),
      ),
    );
  }

  // 월 선택 위젯
  Widget _buildMonthPicker() {
    List<int> months = List.generate(12, (index) => index + 1);

    return DropdownButtonHideUnderline(
      child: ButtonTheme(
        alignedDropdown: true,
        child: DropdownButton<int>(
          value: selectedMonth,
          items: months
              .map((month) => DropdownMenuItem(
                    value: month,
                    child: Text('$month'),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedMonth = value;
                _adjustDay();
              });
              _updateValue();
            }
          },
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
        ),
      ),
    );
  }

  // 일 선택 위젯
  Widget _buildDayPicker() {
    final lastDay = _getLastDayOfMonth(selectedYear, selectedMonth);
    List<int> days = List.generate(lastDay, (index) => index + 1);

    return DropdownButtonHideUnderline(
      child: ButtonTheme(
        alignedDropdown: true,
        child: DropdownButton<int>(
          value: selectedDay,
          items: days
              .map((day) => DropdownMenuItem(
                    value: day,
                    child: Text('$day'),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedDay = value;
              });
              _updateValue();
            }
          },
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
        ),
      ),
    );
  }
}
