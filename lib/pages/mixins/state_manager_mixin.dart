import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/contact_model.dart';
import '../../models/group_model.dart';
import '../../models/message_model.dart';
import '../../models/recent_contact_model.dart';
import '../../services/websocket_service.dart';
import '../../services/agora_service.dart';
import '../../widgets/mention_member_picker.dart';

/// 状态管理 Mixin - 集中管理所有状态变量
mixin StateManagerMixin<T extends StatefulWidget> on State<T> {
  // ============ 基础状态 ============
  int selectedMenuIndex = 0; // 0: 消息, 1: 通讯录, 2: 资讯, 3: 待办
  int selectedChatIndex = 0;
  int selectedContactIndex = -1;
  Map<String, dynamic>? selectedPerson;
  String userStatus = 'online';
  String userDisplayName = '';
  String username = '';
  String? userAvatar;
  bool isLoadingUserInfo = true;

  // ============ 服务实例 ============
  final WebSocketService wsService = WebSocketService();
  AgoraService? agoraService;

  // ============ 联系人和群组 ============
  List<ContactModel> contacts = [];
  bool isLoadingContacts = false;
  String? contactsError;
  List<GroupModel> groups = [];
  bool isLoadingGroups = false;
  String? groupsError;
  GroupModel? selectedGroup;

  // ============ 常用和通知 ============
  String? selectedFavoriteCategory;
  List<dynamic> favoriteContacts = [];
  List<dynamic> favoriteGroups = [];
  List<dynamic> onlineNotifications = [];
  bool isLoadingFavorites = false;

  // ============ 最近联系人 ============
  List<RecentContactModel> recentContacts = [];
  bool isLoadingRecentContacts = false;
  String? recentContactsError;
  final TextEditingController searchController = TextEditingController();
  String searchText = '';

  // ============ 头像缓存 ============
  final Map<int, String?> avatarCache = {};
  Timer? searchDebounceTimer;

  // ============ 自动离线 ============
  Timer? autoOfflineTimer;
  DateTime? lastResetTime;
  DateTime lastActivityTime = DateTime.now();

  // ============ 搜索 ============
  List<RecentContactModel> searchResults = [];
  bool isSearching = false;
  String? searchError;

  // ============ 消息相关 ============
  List<MessageModel> messages = [];
  bool isLoadingMessages = false;
  String? messagesError;
  int? currentChatUserId;
  bool isCurrentChatGroup = false;
  int currentUserId = 0;
  String? token;
  final TextEditingController messageInputController = TextEditingController();
  final ScrollController messageScrollController = ScrollController();
  String previousInputText = '';
  bool isSendingMessage = false;
  final FocusNode messageInputFocusNode = FocusNode();

  // ============ 文件上传 ============
  final List<File> selectedImageFiles = [];
  bool isUploadingImage = false;
  final List<File> selectedFiles = [];
  bool isUploadingFile = false;

  // ============ 引用和转发 ============
  MessageModel? quotedMessage;
  List<int> selectedForwardContacts = [];

  // ============ 多选模式 ============
  bool isMultiSelectMode = false;
  final Set<int> selectedMessageIds = {};

  // ============ 筛选面板 ============
  bool showFilterPanel = false;
  int selectedFilterTab = 0;
  List<MessageModel> filteredMessages = [];
  final TextEditingController messageSearchController = TextEditingController();
  String messageSearchKeyword = '';
  int? highlightedMessageId;
  Timer? highlightTimer;

  // ============ @功能 ============
  bool showMentionPicker = false;
  List<GroupMemberForMention> groupMembers = [];
  List<int> mentionedUserIds = [];
  String mentionText = '';
  OverlayEntry? mentionOverlay;

  /// 释放所有资源
  void disposeStateManager() {
    wsService.disconnect();
    searchDebounceTimer?.cancel();
    highlightTimer?.cancel();
    autoOfflineTimer?.cancel();
    searchController.dispose();
    messageInputController.dispose();
    messageScrollController.dispose();
    messageInputFocusNode.dispose();
    messageSearchController.dispose();
  }
}
