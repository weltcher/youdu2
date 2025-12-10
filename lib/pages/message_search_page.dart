import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';

/// 消息搜索页面
class MessageSearchPage extends StatefulWidget {
  final List<MessageModel> messages;
  final String chatName;

  const MessageSearchPage({
    super.key,
    required this.messages,
    required this.chatName,
  });

  @override
  State<MessageSearchPage> createState() => _MessageSearchPageState();
}

class _MessageSearchPageState extends State<MessageSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<MessageModel> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  // 搜索过滤条件
  bool _searchInText = true;
  bool _searchInFiles = false;
  bool _searchInImages = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // 自动聚焦搜索框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchQuery = '';
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    // 执行搜索
    final results = widget.messages.where((message) {
      // 按消息类型过滤
      if (!_shouldSearchMessageType(message.messageType)) {
        return false;
      }

      // 按日期过滤
      if (_startDate != null && message.createdAt.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && message.createdAt.isAfter(_endDate!)) {
        return false;
      }

      // 搜索内容
      final lowerQuery = query.toLowerCase();
      if (message.messageType == 'text') {
        return message.content.toLowerCase().contains(lowerQuery);
      } else if (message.messageType == 'file' && message.fileName != null) {
        return message.fileName!.toLowerCase().contains(lowerQuery);
      }

      return false;
    }).toList();

    // 按时间倒序排列
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  bool _shouldSearchMessageType(String messageType) {
    switch (messageType) {
      case 'text':
        return _searchInText;
      case 'file':
        return _searchInFiles;
      case 'image':
      case 'video':
        return _searchInImages;
      default:
        return false;
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 拖动指示器
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            // 标题
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '搜索选项',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchInText = true;
                        _searchInFiles = false;
                        _searchInImages = false;
                        _startDate = null;
                        _endDate = null;
                      });
                      Navigator.pop(context);
                      _performSearch(_searchQuery);
                    },
                    child: const Text('重置'),
                  ),
                ],
              ),
            ),
            const Divider(),
            // 消息类型
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '消息类型',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('文字消息'),
                    value: _searchInText,
                    onChanged: (value) {
                      setState(() {
                        _searchInText = value ?? true;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('文件'),
                    value: _searchInFiles,
                    onChanged: (value) {
                      setState(() {
                        _searchInFiles = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('图片和视频'),
                    value: _searchInImages,
                    onChanged: (value) {
                      setState(() {
                        _searchInImages = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            const Divider(),
            // 时间范围
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '时间范围',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(
                          label: '开始日期',
                          date: _startDate,
                          onDateSelected: (date) {
                            setState(() {
                              _startDate = date;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDatePicker(
                          label: '结束日期',
                          date: _endDate,
                          onDateSelected: (date) {
                            setState(() {
                              _endDate = date;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 确定按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _performSearch(_searchQuery);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '应用',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required Function(DateTime?) onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        onDateSelected(pickedDate);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null ? DateFormat('yyyy-MM-dd').format(date) : label,
                style: TextStyle(
                  color: date != null ? Colors.black87 : Colors.grey,
                ),
              ),
            ),
            Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: '搜索聊天记录',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
          ),
          onChanged: _performSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索信息栏
          if (_searchQuery.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Text(
                '找到 ${_searchResults.length} 条相关消息',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          // 搜索结果
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '输入关键字搜索聊天记录',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '没有找到相关消息',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '试试其他关键字',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final message = _searchResults[index];
        return _buildSearchResultItem(message);
      },
    );
  }

  Widget _buildSearchResultItem(MessageModel message) {
    String displayContent = '';
    IconData? typeIcon;
    Color? typeIconColor;

    switch (message.messageType) {
      case 'text':
        displayContent = message.content;
        break;
      case 'image':
        displayContent = '[图片]';
        typeIcon = Icons.image;
        typeIconColor = Colors.green;
        break;
      case 'video':
        displayContent = '[视频]';
        typeIcon = Icons.videocam;
        typeIconColor = Colors.blue;
        break;
      case 'file':
        displayContent = '[文件] ${message.fileName ?? ''}';
        typeIcon = Icons.attach_file;
        typeIconColor = Colors.orange;
        break;
      case 'voice':
        displayContent = '[语音]';
        typeIcon = Icons.mic;
        typeIconColor = Colors.purple;
        break;
      default:
        displayContent = message.content;
    }

    // 高亮搜索关键字
    if (message.messageType == 'text' && _searchQuery.isNotEmpty) {
      displayContent = displayContent;
    }

    return InkWell(
      onTap: () {
        // TODO: 跳转到消息位置
        Navigator.pop(context, message);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 发送者和时间
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  message.senderName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A90E2),
                  ),
                ),
                Text(
                  _formatMessageTime(message.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 消息内容
            Row(
              children: [
                if (typeIcon != null) ...[
                  Icon(typeIcon, size: 16, color: typeIconColor),
                  const SizedBox(width: 4),
                ],
                Expanded(child: _buildHighlightedText(displayContent)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text) {
    if (_searchQuery.isEmpty ||
        !text.toLowerCase().contains(_searchQuery.toLowerCase())) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = _searchQuery.toLowerCase();
    final spans = <TextSpan>[];

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      // 添加高亮前的文本
      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        );
      }

      // 添加高亮文本
      spans.add(
        TextSpan(
          text: text.substring(index, index + _searchQuery.length),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.orange,
            fontWeight: FontWeight.w500,
            backgroundColor: Color(0xFFFFF3CD),
          ),
        ),
      );

      start = index + _searchQuery.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // 添加最后的文本
    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return '昨天 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (dateTime.year == now.year) {
      return DateFormat('MM-dd HH:mm').format(dateTime);
    } else {
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    }
  }
}
