import 'package:flutter/material.dart';

/// 图标选择器，按分类展示 Material Icons，提供文字兜底选项。
/// 返回选中的图标 code（16 进制字符串）或文字图标的特殊标识。
class IconPicker extends StatefulWidget {
  /// 当前选中的图标 code（如 '0xe85d'）或文字标识（如 'text:跑'）
  final String currentCode;
  /// 任务名称，用于文字兜底预览
  final String taskName;

  const IconPicker({
    super.key,
    required this.currentCode,
    required this.taskName,
  });

  /// 弹出图标选择对话框，返回选中的 code，取消返回 null
  static Future<String?> show(
    BuildContext context, {
    required String currentCode,
    required String taskName,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        child: IconPicker(currentCode: currentCode, taskName: taskName),
      ),
    );
  }

  @override
  State<IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _categories = ['运动', '清单', '游戏', '文字'];

  // 运动类图标
  static const _sports = <int>[
    0xe532, // directions_run
    0xeb47, // fitness_center
    0xe533, // directions_walk
    0xea23, // pool
    0xea15, // sports_tennis
    0xea18, // sports_soccer
    0xea1d, // sports_basketball
    0xea1a, // sports_volleyball
    0xea1b, // sports_baseball
    0xea1f, // sports_golf
    0xea1e, // sports_hockey
    0xea1c, // sports_cricket
    0xe6f8, // hike
    0xea0c, // sports_martial_arts
    0xe52d, // directions_bike
    0xe536, // downhill_skiing
    0xe534, // directions_boat
    0xe531, // roller_skating
    0xe535, // kiteboarding
    0xea13, // sports_esports
  ];

  // 清单 / 日常类图标
  static const _checklist = <int>[
    0xe85d, // check
    0xe876, // check_circle
    0xe15b, // assignment
    0xe875, // check_box
    0xe2e7, // playlist_add_check
    0xe047, // event
    0xe88a, // alarm
    0xe8dc, // schedule
    0xe53a, // local_drink
    0xe538, // local_cafe
    0xe7f9, // fastfood
    0xe7f6, // cake
    0xe7f5, // brunch_dining
    0xe540, // local_florist
    0xe53f, // local_grocery_store
    0xe3c4, // library_books
    0xe02f, // book
    0xe865, // star
    0xe87d, // favorite
    0xf1b5, // music_note
    0xe3ad, // headset
    0xe8b4, // movie
    0xe417, // flight
    0xe530, // restaurant
  ];

  // 游戏类图标
  static const _games = <int>[
    0xe028, // videogame_asset
    0xe3fc, // sports_esports
    0xe3f3, // casino
    0xe3ef, // emoji_events
    0xe72a, // rocket_launch
    0xe711, // public
    0xe7ee, // work
    0xe6dd, // school
    0xe1dd, // create
    0xe3b8, // draw
    0xe398, // brush
    0xe878, // camera_alt
    0xe413, // photo_camera
    0xe3fa, // code
    0xe869, // terminal
    0xe7ee, // build
    0xe226, // memory
    0xe7f2, // extension
    0xe88f, // all_inclusive
    0xe70c, // psychology
  ];

  late List<List<int>> _iconGroups;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _iconGroups = [_sports, _checklist, _games, const []];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textChar = widget.taskName.isNotEmpty
        ? widget.taskName.characters.first
        : '?';
    return Container(
      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 480),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('选择图标',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _categories.map((c) => Tab(text: c)).toList(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _iconGrid(_sports),
                _iconGrid(_checklist),
                _iconGrid(_games),
                _textIconTab(textChar),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconGrid(List<int> icons) {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: icons.length,
      itemBuilder: (_, i) {
        final code = icons[i];
        final codeStr = '0x${code.toRadixString(16)}';
        final selected = codeStr == widget.currentCode;
        return InkResponse(
          onTap: () => Navigator.pop(context, codeStr),
          child: Container(
            decoration: BoxDecoration(
              color: selected ? Colors.blue.withValues(alpha: 0.15) : null,
              borderRadius: BorderRadius.circular(8),
              border: selected ? Border.all(color: Colors.blue) : null,
            ),
            child: Icon(IconData(code, fontFamily: 'MaterialIcons'), size: 28),
          ),
        );
      },
    );
  }

  Widget _textIconTab(String char) {
    final textCode = 'text:$char';
    final selected = widget.currentCode == textCode;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('用任务名首字作为图标',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          InkResponse(
            onTap: () => Navigator.pop(context, textCode),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: selected ? Colors.blue.withValues(alpha: 0.15) : null,
                borderRadius: BorderRadius.circular(16),
                border: selected ? Border.all(color: Colors.blue) : null,
              ),
              child: Center(
                child: Text(
                  char,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 统一渲染任务图标：支持 Material Icons 和文字兜底
class TaskIcon extends StatelessWidget {
  final String iconCode;
  final String taskName;
  final Color color;
  final double size;

  const TaskIcon({
    super.key,
    required this.iconCode,
    required this.taskName,
    required this.color,
    this.size = 32,
  });

  bool get _isTextIcon => iconCode.startsWith('text:');

  @override
  Widget build(BuildContext context) {
    if (_isTextIcon) {
      final char = taskName.isNotEmpty ? taskName.characters.first : '?';
      return Text(
        char,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: color,
          height: 1.1,
        ),
      );
    }
    final code = int.tryParse(iconCode) ?? 0xe85d;
    return Icon(IconData(code, fontFamily: 'MaterialIcons'),
        color: color, size: size);
  }
}
