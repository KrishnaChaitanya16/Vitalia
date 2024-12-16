import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class Appoinmetpage extends StatefulWidget {
  final String doctorName;
  final List<String> availableSlots;

  const Appoinmetpage({
    Key? key,
    required this.doctorName,
    required this.availableSlots,
  }) : super(key: key);

  @override
  _AppoinmetpageState createState() => _AppoinmetpageState();
}

class _AppoinmetpageState extends State<Appoinmetpage> {
  DateTime? selectedDate; // Selected date
  DateTime focusedDate = DateTime.now(); // Currently focused date in the calendar
  int? selectedSlotIndex; // Index of the selected time slot

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Book Appointment - ${widget.doctorName}',
          style: const TextStyle(color: Colors.black),
        ),
        elevation: 4,
        backgroundColor: Colors.white,
        shadowColor: Colors.black26,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Date for ${widget.doctorName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Embedded Calendar
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 30)), // Limit to 30 days
              focusedDay: focusedDate,
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.blue, // Selected date background color
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.grey.shade300, // Highlight for today's date
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(color: Colors.red), // Red for weekends
                outsideDaysVisible: false, // Hide days from other months
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false, // Hide month/week toggle button
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              selectedDayPredicate: (day) => selectedDate != null && isSameDay(selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  selectedDate = selectedDay; // Update selected date
                  this.focusedDate = focusedDay; // Update calendar focus
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Available Slots',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Number of columns
                  crossAxisSpacing: 10, // Space between columns
                  mainAxisSpacing: 10, // Space between rows
                  childAspectRatio: 3, // Aspect ratio of grid items
                ),
                itemCount: widget.availableSlots.length,
                itemBuilder: (context, index) {
                  bool isSelected = selectedSlotIndex == index; // Check if this slot is selected
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedSlotIndex = index; // Update selected slot index
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Selected Slot: ${widget.availableSlots[index]}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 3,
                      color: isSelected ? Colors.blue : Colors.white, // Change color when selected
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          widget.availableSlots[index],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: selectedDate != null && selectedSlotIndex != null
                  ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Appointment Confirmed for '
                          '${selectedDate!.toLocal().toString().split(' ')[0]} at '
                          '${widget.availableSlots[selectedSlotIndex!]}',
                    ),
                  ),
                );
              }
                  : null, // Disable button if no date or slot is selected
              style: ElevatedButton.styleFrom(
                backgroundColor: (selectedDate != null && selectedSlotIndex != null)
                    ? Colors.blue
                    : Colors.grey,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Confirm Appointment'),
            ),
          ],
        ),
      ),
    );
  }
}
