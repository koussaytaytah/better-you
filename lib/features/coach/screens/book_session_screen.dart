import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import 'my_sessions_screen.dart';

class BookSessionScreen extends StatefulWidget {
  final String coachId;
  final Map<String, dynamic> coachData;
  final String userId;

  const BookSessionScreen({
    super.key,
    required this.coachId,
    required this.coachData,
    required this.userId,
  });

  @override
  State<BookSessionScreen> createState() => _BookSessionScreenState();
}

class _BookSessionScreenState extends State<BookSessionScreen> {
  String? _selectedSlot;
  String _selectedType = 'video';
  String _note = '';
  bool _isBooking = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  List<String> get _slots => List<String>.from(widget.coachData['availableSlots'] ?? []);
  double get _price => (widget.coachData['pricePerSession'] as num?)?.toDouble() ?? 0;

  Future<void> _confirmBooking() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available time slot')),
      );
      return;
    }
    setState(() => _isBooking = true);
    try {
      final bookingId = FirebaseFirestore.instance.collection('bookings').doc().id;
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).set({
        'id': bookingId,
        'userId': widget.userId,
        'coachId': widget.coachId,
        'coachName': widget.coachData['name'] ?? '',
        'coachImageUrl': widget.coachData['profileImageUrl'] ?? '',
        'coachSpecialization': widget.coachData['specialization'] ?? '',
        'slot': _selectedSlot,
        'date': Timestamp.fromDate(_selectedDate),
        'type': _selectedType,
        'note': _note,
        'price': _price,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add coach to user's assignedProfessionals
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'assignedProfessionals': FieldValue.arrayUnion([widget.coachId]),
      });

      if (mounted) {
        _showSuccessSheet();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 44),
            ),
            const SizedBox(height: 20),
            Text('Session Booked!', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Your session with ${widget.coachData['name']} on $_selectedSlot is confirmed.\nYou will receive a notification before the session.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => MySessionsScreen(userId: widget.userId)),
                  );
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 50)),
                child: const Text('View My Sessions'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Back to Coaches'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Session', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CoachSummaryCard(coachData: widget.coachData, price: _price),
            const SizedBox(height: 24),
            Text('Session Type', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                _TypeChip(label: 'Video Call', icon: Icons.videocam_outlined, value: 'video', selected: _selectedType, onTap: (v) => setState(() => _selectedType = v)),
                const SizedBox(width: 12),
                _TypeChip(label: 'Voice Call', icon: Icons.call_outlined, value: 'voice', selected: _selectedType, onTap: (v) => setState(() => _selectedType = v)),
                const SizedBox(width: 12),
                _TypeChip(label: 'Chat', icon: Icons.chat_bubble_outline, value: 'chat', selected: _selectedType, onTap: (v) => setState(() => _selectedType = v)),
              ],
            ),
            const SizedBox(height: 24),
            Text('Select Date', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.primary.withValues(alpha: 0.04),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Available Time Slots', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (_slots.isEmpty)
              const Text('No available slots at this time.', style: TextStyle(color: Colors.grey))
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _slots.map((slot) {
                  final isSelected = _selectedSlot == slot;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSlot = slot),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, size: 14, color: isSelected ? Colors.white : Colors.grey),
                          const SizedBox(width: 6),
                          Text(slot, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            Text('Note to Coach (optional)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => _note = v,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., My main goal is to lose 5kg for summer...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _PriceSummary(price: _price),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isBooking ? null : _confirmBooking,
                icon: _isBooking
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isBooking ? 'Booking...' : 'Confirm Booking • \$$_price', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CoachSummaryCard extends StatelessWidget {
  final Map<String, dynamic> coachData;
  final double price;

  const _CoachSummaryCard({required this.coachData, required this.price});

  @override
  Widget build(BuildContext context) {
    final imageUrl = coachData['profileImageUrl'] as String? ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: imageUrl.isEmpty ? const Icon(Icons.person, size: 32) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coachData['name'] ?? 'Coach', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(coachData['specialization'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text('${coachData['rating'] ?? 4.5}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$$price', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const Text('/session', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String selected;
  final void Function(String) onTap;

  const _TypeChip({required this.label, required this.icon, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.grey[600]),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.grey[600], fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  final double price;

  const _PriceSummary({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _PriceRow(label: 'Session fee', value: '\$$price'),
          const Divider(height: 20),
          _PriceRow(label: 'Total', value: '\$$price', bold: true),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _PriceRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 15 : 13)),
        Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 15 : 13, color: bold ? AppColors.primary : null)),
      ],
    );
  }
}
