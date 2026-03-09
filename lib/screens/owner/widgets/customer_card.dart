import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../models/customer_model.dart';

/// Modern professional enterprise-style customer card for solar installation management
class CustomerCard extends StatefulWidget {
  final CustomerModel customer;

  const CustomerCard({super.key, required this.customer});

  @override
  State<CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<CustomerCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isPressed ? 2 : 0, 0),
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: _isPressed
                  ? Colors.black.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: _isPressed ? 8 : 16,
              offset: Offset(0, _isPressed ? 2 : 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(18.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TOP ROW: Avatar and Customer Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gradient Avatar with Initials
                      CustomerAvatar(fullName: widget.customer.fullName),
                      SizedBox(width: 14.w),

                      // Name and Email Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.customer.fullName,
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A1A),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              'Customer',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // CONTACT INFO: Email and Phone
                  _buildContactInfo(),

                  // ADDRESS SECTION
                  if (widget.customer.fullAddress.isNotEmpty) ...[
                    SizedBox(height: 14.h),
                    _buildAddressSection(),
                  ],

                  // NOTES SECTION
                  if (widget.customer.notes != null && widget.customer.notes!.isNotEmpty) ...[
                    SizedBox(height: 14.h),
                    _buildNotesSection(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Column(
      children: [
        // Email
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.email_rounded,
                size: 16.w,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                widget.customer.email,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // Phone
        SizedBox(height: 10.h),
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.phone_rounded,
                size: 16.w,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                widget.customer.phone,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 18.w,
            color: const Color(0xFFFFB300),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              widget.customer.fullAddress,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1A1A),
                letterSpacing: 0.1,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.note_rounded,
            size: 16.w,
            color: Colors.grey.shade600,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              widget.customer.notes!,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                letterSpacing: 0.1,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient circle avatar with customer initials and color variants
class CustomerAvatar extends StatelessWidget {
  final String fullName;

  const CustomerAvatar({
    super.key,
    required this.fullName,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  // Generate color variant based on name hash for visual distinction
  List<Color> _getGradientColors() {
    final hash = fullName.hashCode.abs();
    final colorVariants = [
      // Solar Yellow/Amber - Primary brand color
      [const Color(0xFF6EAA99), const Color(0xFF74E48C)],
      // Teal/Cyan - Professional and fresh
      [const Color(0xFF26A69A), const Color(0xFF4DB6AC)],
      // Deep Purple - Professional and modern
      [const Color(0xFF7E57C2), const Color(0xFF9575CD)],
      // Orange - Warm and energetic
      [const Color(0xFF7E4A58), const Color(0xFF43294C)],
      // Blue - Trustworthy and professional
      [const Color(0xFF42A5F5), const Color(0xFF64B5F6)],
      // Green - Growth and sustainability
      [const Color(0xFF66BB6A), const Color(0xFF81C784)],
      // Pink/Rose - Friendly and approachable
      [const Color(0xFFEC407A), const Color(0xFFF06292)],
      // Indigo - Premium and sophisticated
      [const Color(0xFF5C6BC0), const Color(0xFF7986CB)],
    ];

    return colorVariants[hash % colorVariants.length];
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();

    return Container(
      width: 54.w,
      height: 54.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _getInitials(fullName),
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

