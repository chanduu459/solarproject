import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../models/user_model.dart';

/// Modern professional enterprise-style worker card for solar installation management
class WorkerCard extends StatefulWidget {
  final UserModel worker;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onStatusChange;

  const WorkerCard({
    super.key,
    required this.worker,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  State<WorkerCard> createState() => _WorkerCardState();
}

class _WorkerCardState extends State<WorkerCard> with SingleTickerProviderStateMixin {
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
                children: [
                  // TOP ROW: Avatar, Name, Role, Toggle
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gradient Avatar with Initials
                      WorkerAvatar(
                        fullName: widget.worker.fullName,
                        role: widget.worker.role,
                      ),
                      SizedBox(width: 14.w),

                      // Name and Role Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.worker.fullName,
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
                              widget.worker.role == 'owner' ? 'Business Owner' : 'Field Technician',
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

                      // Active/Inactive Toggle
                      Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: widget.worker.isActive,
                          onChanged: widget.onStatusChange,
                          activeThumbColor: const Color(0xFF34C759),
                          activeTrackColor: const Color(0xFF34C759).withValues(alpha: 0.5),
                          inactiveThumbColor: Colors.grey.shade400,
                          inactiveTrackColor: Colors.grey.shade300,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // MIDDLE SECTION: Email and Phone with Icons
                  _buildContactInfo(),

                  SizedBox(height: 14.h),

                  // STATUS SECTION: Role and Status Chips
                  Row(
                    children: [
                      StatusChip(
                        label: widget.worker.role.toUpperCase(),
                        backgroundColor: widget.worker.role == 'owner'
                            ? const Color(0xFFFFF4E6)
                            : const Color(0xFFE3F2FD),
                        textColor: widget.worker.role == 'owner'
                            ? const Color(0xFFFF9800)
                            : const Color(0xFF1E88E5),
                        icon: widget.worker.role == 'owner'
                            ? Icons.workspace_premium_rounded
                            : Icons.engineering_rounded,
                      ),
                      SizedBox(width: 8.w),
                      StatusChip(
                        label: widget.worker.isActive ? 'ACTIVE' : 'OFFLINE',
                        backgroundColor: widget.worker.isActive
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        textColor: widget.worker.isActive
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFC62828),
                        icon: widget.worker.isActive
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),

                  SizedBox(height: 12.h),

                  // ACTION BUTTONS: Edit and Delete
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildActionButton(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        color: const Color(0xFF1E88E5),
                        onPressed: widget.onEdit,
                      ),
                      SizedBox(width: 12.w),
                      _buildActionButton(
                        icon: Icons.delete_rounded,
                        label: 'Delete',
                        color: const Color(0xFFE53935),
                        onPressed: widget.onDelete,
                      ),
                    ],
                  ),
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
                widget.worker.email,
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

        // Phone (if available)
        if (widget.worker.phone != null) ...[
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
                  widget.worker.phone!,
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
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10.r),
      splashColor: color.withValues(alpha: 0.2),
      highlightColor: color.withValues(alpha: 0.1),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18.w, color: color),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient circle avatar with worker initials
class WorkerAvatar extends StatelessWidget {
  final String fullName;
  final String role;

  const WorkerAvatar({
    super.key,
    required this.fullName,
    required this.role,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  LinearGradient _getGradient() {
    if (role == 'owner') {
      return const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54.w,
      height: 54.w,
      decoration: BoxDecoration(
        gradient: _getGradient(),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (role == 'owner' ? const Color(0xFFFF9800) : const Color(0xFF1E88E5))
                .withValues(alpha: 0.3),
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

/// Modern status chip with rounded design
class StatusChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.w, color: textColor),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

