import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '思语',
      theme: ThemeData(
        fontFamily: '.SF Pro Display',
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      home: const MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ============================================================
//  数据模型
// ============================================================
class Message {
  String type; // 'text' or 'transfer'
  String direction; // 'incoming' or 'outgoing'
  String content;
  double amount;
  String time;
  String status; // 'pending', 'completed', 'refunded'
  String memo;

  Message({
    required this.type,
    required this.direction,
    this.content = '',
    this.amount = 0,
    required this.time,
    this.status = 'pending',
    this.memo = '',
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'direction': direction,
        'content': content,
        'amount': amount,
        'time': time,
        'status': status,
        'memo': memo,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        type: json['type'],
        direction: json['direction'],
        content: json['content'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        time: json['time'] ?? '',
        status: json['status'] ?? 'pending',
        memo: json['memo'] ?? '',
      );
}

class Chat {
  String id;
  String name;
  String avatar;
  int unread;
  String lastMsg;
  String time;
  List<Message> messages;

  Chat({
    required this.id,
    required this.name,
    required this.avatar,
    this.unread = 0,
    this.lastMsg = '',
    this.time = '',
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'unread': unread,
        'lastMsg': lastMsg,
        'time': time,
        'messages': messages.map((e) => e.toJson()).toList(),
      };

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        id: json['id'],
        name: json['name'],
        avatar: json['avatar'] ?? '👤',
        unread: json['unread'] ?? 0,
        lastMsg: json['lastMsg'] ?? '',
        time: json['time'] ?? '',
        messages: (json['messages'] as List)
            .map((e) => Message.fromJson(e))
            .toList(),
      );
}

// ============================================================
//  数据持久化
// ============================================================
class DataStore {
  static const String _key = 'siyu_data';

  static Future<void> saveChats(List<Chat> chats) async {
    final prefs = await SharedPreferences.getInstance();
    final json = chats.map((c) => c.toJson()).toList();
    await prefs.setString(_key, jsonEncode(json));
  }

  static Future<List<Chat>> loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return _getDefaultChats();
    try {
      final List<dynamic> json = jsonDecode(data);
      return json.map((e) => Chat.fromJson(e)).toList();
    } catch (e) {
      return _getDefaultChats();
    }
  }

  static List<Chat> _getDefaultChats() {
    return [
      Chat(
        id: 'c1',
        name: '林晓',
        avatar: '🦊',
        unread: 2,
        messages: [
          Message(type: 'text', direction: 'incoming', content: '嘿，下午好！', time: '14:20'),
          Message(type: 'transfer', direction: 'incoming', amount: 500, time: '14:20',
              status: 'pending', memo: '项目订金'),
          Message(type: 'text', direction: 'outgoing', content: '收到，我确认一下', time: '14:22'),
          Message(type: 'transfer', direction: 'outgoing', amount: 128.50, time: '14:30',
              status: 'completed', memo: '红包'),
        ],
      ),
      Chat(
        id: 'c2',
        name: '项目群 (3)',
        avatar: '👥',
        messages: [
          Message(type: 'text', direction: 'incoming', content: '@所有人 今晚8点开会', time: '昨天'),
          Message(type: 'transfer', direction: 'incoming', amount: 2000, time: '昨天',
              status: 'refunded', memo: '退还押金'),
        ],
      ),
      Chat(
        id: 'c3',
        name: '王小明',
        avatar: '🐱',
        messages: [
          Message(type: 'text', direction: 'incoming', content: '转账收到了吗？', time: '10:00'),
          Message(type: 'transfer', direction: 'incoming', amount: 66.66, time: '10:00',
              status: 'completed', memo: '奶茶钱'),
        ],
      ),
    ];
  }
}

// ============================================================
//  主页面
// ============================================================
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  List<Chat> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final chats = await DataStore.loadChats();
    setState(() {
      _chats = chats;
      _isLoading = false;
    });
  }

  void _updateChats(List<Chat> newChats) {
    setState(() {
      _chats = newChats;
    });
    DataStore.saveChats(_chats);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomePage(),
          const MatchPage(),
          const DiscoverPage(),
          MessagesPage(
            chats: _chats,
            onUpdate: _updateChats,
          ),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: const Color(0xFF8E8E93),
        selectedFontSize: 10,
        unselectedFontSize: 10,
        iconSize: 24,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), label: '交友'),
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined), label: '发现'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '消息'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}

// ============================================================
//  首页
// ============================================================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _entryCard({required String icon, required String label, required String sub, String? badge}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        border: Border.all(color: const Color(0xFFF0F0F0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
          if (badge != null)
            Positioned(
              right: 12,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(badge, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String more) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text(more, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
      ],
    );
  }

  Widget _dramaItem(String emoji, String name, String ep) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFD0E8FF), Color(0xFFA0C4FF)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 34))),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                Text(ep, style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 0.5),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _postCard({
    required String avatar,
    required String name,
    required bool pinned,
    required String time,
    required String location,
    required String content,
    List<String>? images,
    String? likes,
    String? comments,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0E8FF),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(avatar, style: const TextStyle(fontSize: 16))),
              ),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (pinned) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('置', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
              const Spacer(),
              Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
              const SizedBox(width: 4),
              Text(location, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
          if (images != null) ...[
            const SizedBox(height: 10),
            Row(
              children: images.map((e) => Expanded(
                child: Container(
                  height: 80,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9ECF0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text(e, style: const TextStyle(fontSize: 28))),
                ),
              )).toList(),
            ),
          ],
          if (likes != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('❤️ $likes', style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                const SizedBox(width: 20),
                Text('💬 $comments', style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                const SizedBox(width: 20),
                const Text('↗️ 分享', style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                const Spacer(),
                const Text('点击发帖>', style: TextStyle(fontSize: 13, color: Color(0xFF007AFF), fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('思语', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Color(0xFF007AFF)), onPressed: () {}),
          IconButton(icon: const Icon(Icons.add, color: Color(0xFF007AFF)), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _entryCard(
                    icon: '❤️',
                    label: '心动匹配',
                    sub: '遇见同频的人',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _entryCard(
                    icon: '▶️',
                    label: '思语视频',
                    sub: '精彩内容抢鲜看',
                    badge: '今日剩余10次',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionTitle('热播短剧', '开始匹配'),
            const SizedBox(height: 8),
            SizedBox(
              height: 155,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _dramaItem('🎬', '重生之...', '第8集'),
                  const SizedBox(width: 10),
                  _dramaItem('🔥', '逆袭千金', '第12集'),
                  const SizedBox(width: 10),
                  _dramaItem('💎', '豪门恩怨', '第5集'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionTitle('热门话题', '更多'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _topicTag('🔥 全网都在追'),
                _topicTag('💬 思语动态'),
                _topicTag('🎧 语聊房'),
                _topicTag('👥 交友社区'),
              ],
            ),
            const SizedBox(height: 12),
            const Text('轻松聊，交朋友', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _postCard(
              avatar: '🤖',
              name: '思语话题小助手',
              pinned: true,
              time: '08-0313:33',
              location: '来自黑龙江省',
              content: '#短裙小心机 分享今日短裙穿搭！',
              images: null,
            ),
            _postCard(
              avatar: '👩',
              name: '短裙小心机',
              pinned: false,
              time: '08-0313:33',
              location: '来自黑龙江省',
              content: '#短裙小心机 分享今日短裙穿搭！',
              images: const ['👗', '👠', '👜'],
              likes: '128',
              comments: '56',
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('🔥 热门话题', style: TextStyle(fontSize: 13)),
                  Text('🎧 语聊房', style: TextStyle(fontSize: 13)),
                  Text('👥 交友社区', style: TextStyle(fontSize: 13)),
                  Text('更多话题›', style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  交友页
// ============================================================
class MatchPage extends StatelessWidget {
  const MatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text('心动匹配', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            Text('语聊房', style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93))),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text('🎤 语聊房', style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32))),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RichText(
              text: const TextSpan(
                text: '今日已成功匹配 ',
                style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                children: [
                  TextSpan(text: '39,722', style: TextStyle(fontSize: 18, color: Color(0xFF007AFF), fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF9500), Color(0xFFFF6B00)]),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text('👑 VIP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                  ),
                  child: const Text('⚙️ 高级筛选', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF0055B3)]),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [BoxShadow(color: Color(0xFF007AFF).withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: const Center(
                child: Text('✨ 开始匹配', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          text: '👑 VIP每日赠送 ',
                          style: TextStyle(fontSize: 13),
                          children: [
                            TextSpan(text: '30次', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF007AFF))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: const TextSpan(
                          text: '当前次数：',
                          style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                          children: [
                            TextSpan(text: '10次', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text('立即购买', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  发现页
// ============================================================
class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  Widget _videoTab(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF007AFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(text, style: TextStyle(color: active ? Colors.white : const Color(0xFF8E8E93), fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _videoCard({required String emoji, required String title, required String desc, required List<String> tags, required String author, required String series}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFA0C4FF), Color(0xFFD0E8FF)]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 48)),
                ),
              ),
              const Positioned(
                bottom: 10,
                left: 12,
                child: _EpTag('第3集'),
              ),
              Positioned(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 13, color: Color(0xFF6C6C70))),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    children: tags.map((e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F6),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 11, color: Color(0xFF6C6C70))),
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(author, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    if (series.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(series, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Text('⭐ 收藏', style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                    SizedBox(width: 16),
                    Text('↗️ 分享', style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                    Spacer(),
                    Text('❤️ 赞赏', style: TextStyle(fontSize: 13, color: Color(0xFFFF3B30))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('思语视频', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Color(0xFF007AFF)), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _videoTab('短剧', true),
                _videoTab('动态', false),
                _videoTab('推荐', false),
                _videoTab('关注', false),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _videoCard(
                    emoji: '🎬',
                    title: '国外版：王多鱼的爷爷',
                    desc: '穷小子逆袭亿万富豪 · 这个小伙真聪明自己家地的石油快采光了',
                    tags: ['#超级人生', '#首富王多鱼'],
                    author: '@V剧说',
                    series: '《超级人生》-3',
                  ),
                  _videoCard(
                    emoji: '🎭',
                    title: '重生之我是首富',
                    desc: '意外回到2008年，我决定弥补所有遗憾...',
                    tags: [],
                    author: '@短剧工坊',
                    series: '',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EpTag extends StatelessWidget {
  final String text;
  const _EpTag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}

// ============================================================
//  消息页
// ============================================================
class MessagesPage extends StatefulWidget {
  final List<Chat> chats;
  final Function(List<Chat>) onUpdate;

  const MessagesPage({super.key, required this.chats, required this.onUpdate});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  void _openChat(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          chat: widget.chats[index],
          onUpdate: (updatedChat) {
            final newChats = List<Chat>.from(widget.chats);
            newChats[index] = updatedChat;
            widget.onUpdate(newChats);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('消息', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Color(0xFF007AFF)), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.chats.length,
        itemBuilder: (context, index) {
          final chat = widget.chats[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFD0E8FF),
              child: Text(chat.avatar, style: const TextStyle(fontSize: 20)),
            ),
            title: Text(chat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              chat.lastMsg,
              style: const TextStyle(color: Color(0xFF8E8E93)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(chat.time, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                if (chat.unread > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '${chat.unread}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            onTap: () => _openChat(index),
          );
        },
      ),
    );
  }
}

// ============================================================
//  聊天详情页（核心功能：编辑转账记录）
// ============================================================
class ChatDetailPage extends StatefulWidget {
  final Chat chat;
  final Function(Chat) onUpdate;

  const ChatDetailPage({super.key, required this.chat, required this.onUpdate});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  bool _editMode = false;

  void _updateChat(Chat newChat) {
    widget.onUpdate(newChat);
    setState(() {});
  }

  void _editAmount(int index) {
    final msg = widget.chat.messages[index];
    if (msg.type != 'transfer') return;

    final controller = TextEditingController(text: msg.amount.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改金额'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '输入新金额'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value >= 0) {
                final newChat = Chat(
                  id: widget.chat.id,
                  name: widget.chat.name,
                  avatar: widget.chat.avatar,
                  unread: widget.chat.unread,
                  lastMsg: widget.chat.lastMsg,
                  time: widget.chat.time,
                  messages: List.from(widget.chat.messages),
                );
                newChat.messages[index].amount = value;
                _updateChat(newChat);
                Navigator.pop(context);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _editTime(int index) {
    final msg = widget.chat.messages[index];
    if (msg.type != 'transfer') return;

    final controller = TextEditingController(text: msg.time);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改时间'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '输入时间（如 14:30）'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final newChat = Chat(
                  id: widget.chat.id,
                  name: widget.chat.name,
                  avatar: widget.chat.avatar,
                  unread: widget.chat.unread,
                  lastMsg: widget.chat.lastMsg,
                  time: widget.chat.time,
                  messages: List.from(widget.chat.messages),
                );
                newChat.messages[index].time = controller.text;
                _updateChat(newChat);
                Navigator.pop(context);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _cycleStatus(int index) {
    final msg = widget.chat.messages[index];
    if (msg.type != 'transfer') return;

    final statusMap = {'pending': 'completed', 'completed': 'refunded', 'refunded': 'pending'};
    final newChat = Chat(
      id: widget.chat.id,
      name: widget.chat.name,
      avatar: widget.chat.avatar,
      unread: widget.chat.unread,
      lastMsg: widget.chat.lastMsg,
      time: widget.chat.time,
      messages: List.from(widget.chat.messages),
    );
    newChat.messages[index].status = statusMap[msg.status] ?? 'pending';
    _updateChat(newChat);
  }

  void _addTransfer() {
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final newChat = Chat(
      id: widget.chat.id,
      name: widget.chat.name,
      avatar: widget.chat.avatar,
      unread: widget.chat.unread,
      lastMsg: widget.chat.lastMsg,
      time: widget.chat.time,
      messages: List.from(widget.chat.messages),
    );
    newChat.messages.add(Message(
      type: 'transfer',
      direction: 'incoming',
      amount: 99.99,
      time: time,
      status: 'pending',
      memo: '新转账',
    ));
    _updateChat(newChat);
  }

  void _deleteMessage(int index) {
    final newChat = Chat(
      id: widget.chat.id,
      name: widget.chat.name,
      avatar: widget.chat.avatar,
      unread: widget.chat.unread,
      lastMsg: widget.chat.lastMsg,
      time: widget.chat.time,
      messages: List.from(widget.chat.messages),
    );
    newChat.messages.removeAt(index);
    _updateChat(newChat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF007AFF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onDoubleTap: () {
            setState(() {
              _editMode = !_editMode;
            });
          },
          child: Row(
            children: [
              Text(widget.chat.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  color: _editMode ? const Color(0xFFFF9500) : const Color(0xFF34C759),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _editMode ? '编辑中' : '加密',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF007AFF)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.chat.messages.length,
              itemBuilder: (context, index) {
                final msg = widget.chat.messages[index];
                final isMe = msg.direction == 'outgoing';

                return GestureDetector(
                  onLongPress: _editMode ? () => _deleteMessage(index) : null,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!isMe) ...[
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFD0E8FF),
                            child: Text(widget.chat.avatar, style: const TextStyle(fontSize: 14)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFFD0E8FF) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF0F0F0), width: 0.5),
                            ),
                            child: msg.type == 'text'
                                ? Text(msg.content, style: const TextStyle(fontSize: 14))
                                : _buildTransferCard(msg, index),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.mic, color: Color(0xFF007AFF)),
                  onPressed: () {},
                ),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '输入消息...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined, color: Color(0xFF007AFF)),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.attach_money, color: Color(0xFFFF9500)),
                  onPressed: _addTransfer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferCard(Message msg, int index) {
    final statusMap = {'pending': '待收款', 'completed': '已收款', 'refunded': '已退还'};
    final statusColor = msg.status == 'pending'
        ? const Color(0xFFE8F5E9)
        : msg.status == 'completed'
            ? const Color(0xFFE3F2FD)
            : const Color(0xFFF5F5F5);
    final textColor = msg.status == 'pending'
        ? const Color(0xFF2E7D32)
        : msg.status == 'completed'
            ? const Color(0xFF0D47A1)
            : const Color(0xFF616161);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              msg.direction == 'incoming' ? '收到转账' : '转账',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6C6C70)),
            ),
            GestureDetector(
              onTap: _editMode ? () => _editTime(index) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  msg.time,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _editMode ? () => _editAmount(index) : null,
          child: Row(
            children: [
              const Text('¥', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              Text(
                msg.amount.toStringAsFixed(2),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              msg.memo,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6C6C70)),
            ),
            GestureDetector(
              onTap: _editMode ? () => _cycleStatus(index) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  statusMap[msg.status] ?? '待收款',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
//  我的页面
// ============================================================
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Widget _statItem(String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
        ],
      ),
    );
  }

  Widget _gridItem(String icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _menuItem(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 15)),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFC6C6C8)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('我的', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: Color(0xFF007AFF)), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF007AFF),
              child: Text('😎', style: TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 12),
            const Text('江浔', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const Text('ID:5746117', style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statItem('0', '关注'),
                _statItem('0', '粉丝'),
                _statItem('0', '好友'),
                _statItem('0', '访客'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF9500)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('👑 思语会员', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('每天低至0.8元，享22项高级特权', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text('立即开通', style: TextStyle(color: Color(0xFFFF9500), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _gridItem('🚀', '加速升级'),
                  _gridItem('🏆', '年V8'),
                  _gridItem('📈', '成长值'),
                  _gridItem('💕', '心动匹配\n40次'),
                  _gridItem('👀', '谁看过我'),
                  _gridItem('🌐', '聊天翻译'),
                  _gridItem('💎', '钻石商城\n余额：0'),
                  _gridItem('🛒', '立即购买'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _menuItem('📋 动态'),
            _menuItem('🎯 任务中心'),
            _menuItem('🔄 兑换中心'),
            _menuItem('👑 会员中心'),
            _menuItem('🏅 排行榜'),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('+ 发布动态', style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}