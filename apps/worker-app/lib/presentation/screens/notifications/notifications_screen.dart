import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/dio_client.dart';
import '../../../injection_container.dart';
import '../../routes/app_routes.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Dio _dio = sl<DioClient>().dio;
  bool _isLoading = true;
  final List<_NotificationItem> _notifications = [];
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    // Poll for new notifications periodically
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_isLoading) _loadNotifications(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await _dio.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': 1, 'limit': 50},
      );
      final payload = response.data['data'] ?? response.data;
      final rows = payload is List
          ? payload
          : (payload['notifications'] ?? []) as List;

      _notifications.clear();
      for (final row in rows) {
        try {
          String? bookingId;
          final rawData = row['data'];
          if (rawData is String && rawData.isNotEmpty) {
            try {
              final parsed = jsonDecode(rawData);
              if (parsed is Map) {
                bookingId = parsed['bookingId']?.toString();
              }
            } catch (_) {}
          } else if (rawData is Map) {
            bookingId = rawData['bookingId']?.toString();
          }

          _notifications.add(
            _NotificationItem(
              id: (row['_id'] ?? '').toString(),
              type: (row['type'] ?? 'SYSTEM').toString(),
              title: (row['title'] ?? '').toString(),
              body: (row['body'] ?? '').toString(),
              isRead: row['isRead'] == true,
              createdAt:
                  DateTime.tryParse((row['createdAt'] ?? '').toString()) ??
                  DateTime.now(),
              bookingId: bookingId,
            ),
          );
        } catch (_) {
          // Skip malformed notification entries
        }
      }
      if (silent && mounted) setState(() {});
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _dio.put(ApiEndpoints.markAsRead(notificationId));

      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1 && mounted) {
        setState(() {
          _notifications[idx] = _notifications[idx].copyWith(isRead: true);
        });
      }
    } catch (e) {
      // Silent fail for mark-as-read
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _dio.put(ApiEndpoints.markAllAsRead);

      if (mounted) {
        setState(() {
          for (int i = 0; i < _notifications.length; i++) {
            _notifications[i] = _notifications[i].copyWith(isRead: true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _dio.delete('${ApiEndpoints.notifications}/$notificationId');

      if (mounted) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notificationId);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Error: $_error'),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: _loadNotifications,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.sm),
                itemCount: _notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 2),
                itemBuilder: (context, index) =>
                    _buildNotificationTile(_notifications[index]),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You will receive notifications about\nyour bookings and updates here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(_NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: AppColors.textOnPrimary),
      ),
      onDismissed: (_) => _deleteNotification(notification.id),
      child: Card(
        color: notification.isRead
            ? null
            : AppColors.primary.withValues(alpha: 0.05),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getNotificationColor(
                notification.type,
              ).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
              size: 20,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead
                  ? FontWeight.normal
                  : FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(notification.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: () {
            if (!notification.isRead) {
              _markAsRead(notification.id);
            }
            _navigateToNotification(notification);
          },
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'BOOKING':
        return Icons.calendar_today;
      case 'PAYMENT':
        return Icons.payment;
      case 'SOS':
        return Icons.warning;
      case 'PROMOTION':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'BOOKING':
        return AppColors.primary;
      case 'PAYMENT':
        return AppColors.success;
      case 'SOS':
        return AppColors.error;
      case 'PROMOTION':
        return AppColors.accent;
      default:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    }
  }

  void _navigateToNotification(_NotificationItem notification) {
    switch (notification.type) {
      case 'BOOKING':
        if (notification.bookingId != null &&
            notification.bookingId!.isNotEmpty) {
          Navigator.pushNamed(
            context,
            AppRoutes.bookingDetails,
            arguments: notification.bookingId,
          );
        }
        break;
      case 'PAYMENT':
        Navigator.pushNamed(context, AppRoutes.earnings);
        break;
      case 'SOS':
        // SOS notifications don't navigate further
        break;
      default:
        break;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? bookingId;

  const _NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.bookingId,
  });

  _NotificationItem copyWith({bool? isRead}) {
    return _NotificationItem(
      id: id,
      type: type,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      bookingId: bookingId,
    );
  }
}
