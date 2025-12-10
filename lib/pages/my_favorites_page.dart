import 'package:flutter/material.dart';
import 'package:youdu/models/favorite_common_model.dart';
import 'package:youdu/models/online_notification_model.dart';
import 'package:youdu/services/api_service.dart';
import 'package:youdu/utils/storage.dart';

/// 我的常用页面
class MyFavoritesPage extends StatefulWidget {
  const MyFavoritesPage({super.key});

  @override
  State<MyFavoritesPage> createState() => _MyFavoritesPageState();
}

class _MyFavoritesPageState extends State<MyFavoritesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _token;
  bool _isLoading = false;

  // 常用联系人列表
  List<FavoriteContactDetail> _favoriteContacts = [];
  // 常用群组列表
  List<FavoriteGroupDetail> _favoriteGroups = [];
  // 上线提醒列表
  List<OnlineNotificationModel> _onlineNotifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadToken();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 加载token
  Future<void> _loadToken() async {
    final token = await Storage.getToken();
    if (token != null) {
      setState(() {
        _token = token;
      });
      // 加载数据
      _loadFavoriteContacts();
      _loadFavoriteGroups();
      _loadOnlineNotifications();
    }
  }

  /// 加载常用联系人
  Future<void> _loadFavoriteContacts() async {
    if (_token == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getFavoriteContacts(token: _token!);
      if (response['code'] == 0) {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          _favoriteContacts = data
              .map((json) => FavoriteContactDetail.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载常用联系人失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 加载常用群组
  Future<void> _loadFavoriteGroups() async {
    if (_token == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getFavoriteGroups(token: _token!);
      if (response['code'] == 0) {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          _favoriteGroups = data
              .map((json) => FavoriteGroupDetail.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载常用群组失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 移除常用联系人
  Future<void> _removeFavoriteContact(FavoriteContactDetail contact) async {
    if (_token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确定要将 ${contact.displayName} 从常用联系人中移除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.removeFavoriteContact(
        token: _token!,
        contactId: contact.contactId,
      );
      if (response['code'] == 0) {
        setState(() {
          _favoriteContacts.removeWhere((c) => c.id == contact.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('移除成功')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('移除失败: $e')));
      }
    }
  }

  /// 移除常用群组
  Future<void> _removeFavoriteGroup(FavoriteGroupDetail group) async {
    if (_token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确定要将 ${group.name} 从常用群组中移除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.removeFavoriteGroup(
        token: _token!,
        groupId: group.groupId,
      );
      if (response['code'] == 0) {
        setState(() {
          _favoriteGroups.removeWhere((g) => g.id == group.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('移除成功')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('移除失败: $e')));
      }
    }
  }

  /// 加载上线提醒
  Future<void> _loadOnlineNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await Storage.getOnlineNotifications();
      
      // 根据用户ID去重，保留每个用户最新的一条通知
      final Map<int, OnlineNotificationModel> uniqueNotifications = {};
      for (var notification in notifications) {
        final existingNotification = uniqueNotifications[notification.userId];
        // 如果不存在或者当前通知时间更新，则更新
        if (existingNotification == null || 
            notification.onlineTime.isAfter(existingNotification.onlineTime)) {
          uniqueNotifications[notification.userId] = notification;
        }
      }
      
      // 转换为列表并按时间倒序排列
      final deduplicatedNotifications = uniqueNotifications.values.toList()
        ..sort((a, b) => b.onlineTime.compareTo(a.onlineTime));
      
      setState(() {
        _onlineNotifications = deduplicatedNotifications;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载上线提醒失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的常用'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '常用联系人'),
            Tab(text: '常用群组'),
            Tab(text: '上线提醒'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFavoriteContactsTab(),
          _buildFavoriteGroupsTab(),
          _buildOnlineNotificationsTab(),
        ],
      ),
    );
  }

  /// 构建常用联系人标签页
  Widget _buildFavoriteContactsTab() {
    if (_isLoading && _favoriteContacts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoriteContacts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无常用联系人', style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text(
              '在联系人详情中点击"常用联系人"按钮添加',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavoriteContacts,
      child: ListView.separated(
        itemCount: _favoriteContacts.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final contact = _favoriteContacts[index];
          return _buildContactItem(contact);
        },
      ),
    );
  }

  /// 构建常用群组标签页
  Widget _buildFavoriteGroupsTab() {
    if (_isLoading && _favoriteGroups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoriteGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无常用群组', style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text(
              '在群组详情中点击"常用群组"按钮添加',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavoriteGroups,
      child: ListView.separated(
        itemCount: _favoriteGroups.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final group = _favoriteGroups[index];
          return _buildGroupItem(group);
        },
      ),
    );
  }

  /// 构建联系人项
  Widget _buildContactItem(FavoriteContactDetail contact) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        backgroundImage: contact.avatar.isNotEmpty
            ? NetworkImage(contact.avatar)
            : null,
        child: contact.avatar.isEmpty
            ? Text(
                contact.avatarText,
                style: TextStyle(color: Theme.of(context).primaryColor),
              )
            : null,
      ),
      title: Row(
        children: [
          Text(contact.displayName),
          const SizedBox(width: 8),
          if (contact.isOnline)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      subtitle: Text(
        contact.workSignature ?? contact.username,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.star, color: Colors.amber),
        onPressed: () => _removeFavoriteContact(contact),
        tooltip: '移除常用联系人',
      ),
      onTap: () {
        // 这里可以添加跳转到联系人详情或聊天页面的逻辑
        // 可以通过Navigator返回并传递选中的联系人信息
        Navigator.pop(context, {'type': 'contact', 'data': contact});
      },
    );
  }

  /// 构建群组项
  Widget _buildGroupItem(FavoriteGroupDetail group) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        backgroundImage: group.avatar != null && group.avatar!.isNotEmpty
            ? NetworkImage(group.avatar!)
            : null,
        child: group.avatar == null || group.avatar!.isEmpty
            ? Text(
                group.avatarText,
                style: TextStyle(color: Theme.of(context).primaryColor),
              )
            : null,
      ),
      title: Text(group.name),
      subtitle: Text(
        '${group.memberCount} 人',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.star, color: Colors.amber),
        onPressed: () => _removeFavoriteGroup(group),
        tooltip: '移除常用群组',
      ),
      onTap: () {
        // 这里可以添加跳转到群组详情或群聊页面的逻辑
        // 可以通过Navigator返回并传递选中的群组信息
        Navigator.pop(context, {'type': 'group', 'data': group});
      },
    );
  }

  /// 构建上线提醒标签页
  Widget _buildOnlineNotificationsTab() {
    if (_isLoading && _onlineNotifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_onlineNotifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无上线提醒', style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text(
              '当您的联系人上线时，会在这里显示',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOnlineNotifications,
      child: ListView.separated(
        itemCount: _onlineNotifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notification = _onlineNotifications[index];
          return _buildOnlineNotificationItem(notification);
        },
      ),
    );
  }

  /// 构建上线提醒项
  Widget _buildOnlineNotificationItem(OnlineNotificationModel notification) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        backgroundImage:
            notification.avatar != null && notification.avatar!.isNotEmpty
            ? NetworkImage(notification.avatar!)
            : null,
        child: notification.avatar == null || notification.avatar!.isEmpty
            ? Text(
                notification.avatarText,
                style: TextStyle(color: Theme.of(context).primaryColor),
              )
            : null,
      ),
      title: Row(
        children: [
          Text(notification.displayName),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
      subtitle: Text('${notification.formattedTime} 上线'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // 可以跳转到与该用户的聊天页面
        Navigator.pop(context, {
          'type': 'user',
          'userId': notification.userId,
          'username': notification.username,
        });
      },
    );
  }
}
