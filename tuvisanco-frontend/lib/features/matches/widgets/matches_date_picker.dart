import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MatchesDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const MatchesDatePicker({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<MatchesDatePicker> createState() => _MatchesDatePickerState();
}

class _MatchesDatePickerState extends State<MatchesDatePicker> {
  late DateTime _selectedDate;
  final ScrollController _scrollController = ScrollController();
  final List<DateTime> _dates = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _generateDates();
    
    // Cuộn đến ngày hiện tại sau khi render xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  void _generateDates() {
    // Tạo danh sách 15 ngày: 7 ngày trước, hôm nay, 7 ngày sau
    final today = DateTime.now();
    for (int i = -7; i <= 7; i++) {
      _dates.add(today.add(Duration(days: i)));
    }
  }

  void _scrollToSelectedDate() {
    if (!_scrollController.hasClients) return;
    
    final index = _dates.indexWhere((d) => _isSameDay(d, _selectedDate));
    if (index != -1) {
      // Ước tính chiều rộng mỗi item là khoảng 60px
      final position = index * 60.0 - (MediaQuery.of(context).size.width / 2) + 30;
      _scrollController.animateTo(
        position.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDayOfWeek(DateTime date) {
    final today = DateTime.now();
    if (_isSameDay(date, today)) return 'HÔM NAY';
    
    switch (date.weekday) {
      case 1: return 'T2';
      case 2: return 'T3';
      case 3: return 'T4';
      case 4: return 'T5';
      case 5: return 'T6';
      case 6: return 'T7';
      case 7: return 'CN';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      color: const Color(0xFF161F2C),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isSameDay(date, DateTime.now());

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
              _scrollToSelectedDate();
              widget.onDateSelected(date);
            },
            child: Container(
              width: 56,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B66F5) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF3B66F5) 
                      : (isToday ? Colors.white24 : Colors.transparent),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatDayOfWeek(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isToday ? Colors.white : Colors.white54),
                      fontSize: 10,
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
