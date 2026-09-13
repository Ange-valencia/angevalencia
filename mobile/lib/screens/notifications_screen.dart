import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.notifications});

  final List<AppNotification> notifications;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<AppNotification> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.notifications);
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    final api = context.read<ApiClient>();
    try {
      await api.post('/notifications/${n.id}/read');
    } catch (_) {}
    setState(() {
      _items = [
        for (final x in _items)
          if (x.id == n.id)
            AppNotification(
              id: x.id,
              type: x.type,
              title: x.title,
              body: x.body,
              isRead: true,
              createdAt: x.createdAt,
            )
          else
            x,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _items.isEmpty
          ? const Center(child: Text('Aucune notification pour le moment'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final n = _items[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _markRead(n),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: n.isRead ? AppColors.beige : AppColors.beigeLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.beigeDark, width: 0.8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_icon(n.type),
                            size: 22,
                            color:
                                n.isRead ? AppColors.textMuted : AppColors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: n.isRead
                                          ? AppColors.textMuted
                                          : AppColors.textPrimary)),
                              if (n.body != null) ...[
                                const SizedBox(height: 4),
                                Text(n.body!,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted)),
                              ],
                              if (n.createdAt != null) ...[
                                const SizedBox(height: 4),
                                Text(_ago(n.createdAt!),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted)),
                              ],
                            ],
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

  IconData _icon(String type) => switch (type) {
        'order' => Icons.receipt_long,
        'status' => Icons.local_shipping,
        _ => Icons.notifications,
      };

  String _ago(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    final d = t.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}