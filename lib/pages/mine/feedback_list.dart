import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medbot_ai_app/generated/l10n.dart';
import 'package:medbot_ai_app/utils/http_service.dart';
import 'package:medbot_ai_app/utils/status_utils.dart';
import 'package:medbot_ai_app/widgets/toast_utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

const _brandColor = Color(0xFF042A72);
const _pageBackground = Color(0xFFF6F8FB);
const _textPrimary = Color(0xFF172033);
const _textSecondary = Color(0xFF697386);
const _borderColor = Color(0xFFD8DEE9);

class FeedbackListPage extends StatefulWidget {
  const FeedbackListPage({super.key});

  @override
  State<FeedbackListPage> createState() => _FeedbackListPageState();
}

class _FeedbackListPageState extends State<FeedbackListPage> {
  int selectedIndex = 0;
  int tabsIndex = 0;
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _ready = false;
  int page = 1;
  int pageSize = 10;
  int _total = 0;
  int _pages = 0;
  int _lastFetchCount = 0;

  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  List<Map<String, dynamic>> get productOptions => [
    {"label": S.of(context).all, "value": ""},
    {"label": S.of(context).tumaiMultiPort, "value": "101"},
    // {"label": S.of(context).tumaiSinglePort, "value": "102"},
    // {"label": S.of(context).dragonflyEye, "value": "103"},
    // {"label": S.of(context).honghu, "value": "104"},
    // {"label": S.of(context).rone, "value": "105"},
    // {"label": S.of(context).monaLisa, "value": "106"},
    // {"label": S.of(context).other, "value": "107"},
  ];

  List<String> get tabs => [
    S.of(context).all,
    S.of(context).defectFeedback,
    S.of(context).requirementFeedback,
    S.of(context).otherFeedback,
  ];
  List<int> tabCounts = [0, 0, 0, 0];
  List<Map<String, dynamic>> _dataList = [];

  @override
  void initState() {
    super.initState();
    _ensureUserInfo();
  }

  Future<void> _ensureUserInfo() async {
    try {
      final res = await HttpService().get('user/info');
      final jsonResponse = jsonDecode(res.body);
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _ready = jsonResponse["status"] == 200;
        });
        if (_ready) {
          // 用户信息验证成功后，立即加载列表和未读数
          await _getList();
          await _fetchUnreadCounts();
        } else {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text(S.of(context).getFailed)),
          // );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _ready = false;
        });
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text(S.of(context).getFailed)),
        // );
      }
    }
  }

  /// read 状态
  Future<void> _fetchUnreadCounts() async {
    if (!_ready && _isInitializing) return; // 等待初始化完成
    try {
      final productId = productOptions[selectedIndex]['value'] as String;
      final response = await HttpService().get(
        'feedback/unread-count',
        params: productId.isEmpty ? null : {"product_id": productId},
      );
      if (!mounted) return;

      final jsonResponse = jsonDecode(response.body);
      print("feedback/unread-count: $jsonResponse");
      if (jsonResponse["status"] == 200) {
        int asInt(dynamic value) {
          if (value is int) return value;
          if (value is num) return value.toInt();
          return int.tryParse(value?.toString() ?? '') ?? 0;
        }

        final data = jsonResponse["data"];
        if (data is! Map<String, dynamic>) {
          if (mounted) {
            ToastUtils.showError(context, S.of(context).getUnreadCountFailed);
          }
          return;
        }

        final items = data['items'];
        final rawItems = items is List ? items.whereType<Map>() : const <Map>[];
        final List<int> newTabCounts = List.filled(tabs.length, 0);

        int total = 0;
        int defect = 0;
        int requirement = 0;
        int other = 0;

        if (productId.isEmpty) {
          total = asInt(data['total']);
          int sumCount = 0;
          for (final item in rawItems) {
            sumCount += asInt(item['count']);
            defect += asInt(item['countDefect']);
            requirement += asInt(item['countRequirement']);
            other += asInt(item['countOther']);
          }
          if (total == 0) total = sumCount;
        } else {
          Map? matched;
          for (final item in rawItems) {
            if (item['deviceType']?.toString() == productId) {
              matched = item;
              break;
            }
          }
          if (matched != null) {
            total = asInt(matched['count']);
            defect = asInt(matched['countDefect']);
            requirement = asInt(matched['countRequirement']);
            other = asInt(matched['countOther']);
          }
        }

        newTabCounts[0] = total;
        if (tabs.length > 1) newTabCounts[1] = defect;
        if (tabs.length > 2) newTabCounts[2] = requirement;
        if (tabs.length > 3) newTabCounts[3] = other;
        print("newTabCounts: $newTabCounts");
        if (mounted) {
          setState(() {
            tabCounts = newTabCounts;
          });
        }
      } else {
        if (mounted) {
          ToastUtils.showError(
            context,
            jsonResponse["message"] ?? S.of(context).getUnreadCountFailed,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.handleHttpException(e, context);
      }
    }
  }

  int? getFeedbackTypeFromIndex(int index) {
    if (index == 0) return null; // “全部”不传 type
    return index; // 1, 2, 3 分别为缺陷、需求、其他
  }

  /*
   获取Feedback- list 
  */
  Future<void> _getList({int pageNum = 1}) async {
    if (!_ready && _isInitializing) return; // 等待初始化完成
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }
      final deviceType = productOptions[selectedIndex]['value'] as String;
      final params = {
        "current": pageNum.toString(),
        "size": pageSize.toString(),
      };

      final type = getFeedbackTypeFromIndex(tabsIndex);
      if (type != null) {
        params["feedbackType"] = type.toString();
      }

      if (deviceType.isNotEmpty) {
        params["deviceType"] = deviceType;
      }

      print('params: $params');
      final response = await HttpService().post('feedback/page', body: params);

      final result = jsonDecode(response.body);
      if (!mounted) return;

      if (result["status"] == 200) {
        final data = result["data"];
        final items =
            data is Map<String, dynamic>
                ? (data['items'] as List? ?? const [])
                : const [];
        final pagination =
            data is Map<String, dynamic>
                ? (data['pagination'] as Map<String, dynamic>? ?? const {})
                : const <String, dynamic>{};

        final List<Map<String, dynamic>> newList =
            items.whereType<Map>().map<Map<String, dynamic>>((raw) {
              final item = Map<String, dynamic>.from(raw);
              final feedbackNo = item['feedbackNo'];
              final normalizedId =
                  feedbackNo == null
                      ? (item['id']?.toString() ?? '')
                      : feedbackNo.toString();
              return {
                ...item,
                'id': normalizedId,
                'description': item['description'] ?? '',
                'occurTime':
                    item['feedbackTime']?.toString() ??
                    item['occurTime']?.toString() ??
                    '',
                'hasUnreadReply': item['hasUnreadReply'] ?? false,
              };
            }).toList();
        setState(() {
          if (pageNum == 1) {
            _dataList = newList;
          } else {
            _dataList.addAll(newList);
          }
          final totalValue = pagination['total'];
          _total =
              totalValue is int
                  ? totalValue
                  : int.tryParse(totalValue?.toString() ?? '') ?? 0;
          final pagesValue = pagination['pages'];
          _pages =
              pagesValue is int
                  ? pagesValue
                  : int.tryParse(pagesValue?.toString() ?? '') ?? 0;
          _lastFetchCount = newList.length;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ToastUtils.showError(
            context,
            result["message"] ?? S.of(context).getDataFailed,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastUtils.handleHttpException(e, context);
      }
    }
  }

  void _onRefresh() async {
    setState(() {
      page = 1;
    });

    await _getList(pageNum: page); // 拉取第一页
    await _fetchUnreadCounts();

    _refreshController.resetNoData(); // ✅ 恢复“还有更多”的标记
    _refreshController.refreshCompleted(); // ✅ 告知刷新完成
  }

  void _onLoading() async {
    if (_isLoading) return; // 防止重复请求

    setState(() {
      page += 1; // 下一页
    });

    await _getList(pageNum: page);
    await _fetchUnreadCounts();

    // 根据是否还有更多数据，决定调用 loadComplete 还是 loadNoData
    if (_hasMoreData()) {
      _refreshController.loadComplete();
    } else {
      _refreshController.loadNoData();
    }
  }

  bool _hasMoreData() {
    if (_pages > 0) return page < _pages;
    if (_total > 0) return _dataList.length < _total;
    return _lastFetchCount >= pageSize;
  }

  // 新增：标记某条反馈为已读
  Future<void> _markFeedbackAsRead(String feedbackId) async {
    print('Marking feedback $feedbackId as read');
    try {
      final response = await HttpService().put(
        'feedback/$feedbackId/read',
        // body: {"id": feedbackId, 'is_read': 1},
      );

      final jsonResponse = jsonDecode(response.body);
      print('Mark as read response: $jsonResponse');
      if (!mounted) return;
      if (jsonResponse["status"] == 200) {
        ToastUtils.showSuccess(context, S.of(context).markedAsRead);
        // 标记成功后刷新未读数和列表
        await _fetchUnreadCounts();
        // page = 1;
        setState(() {
          final index = _dataList.indexWhere(
            (item) => item["id"] == feedbackId,
          );
          if (index != -1) {
            _dataList[index]["is_read"] = "1"; // 更新本地状态
            // _dataList[index]["status"] = 2; // 假设status 2=已读/已处理
          }
        });
        // await _getList(pageNum: page);
      } else {
        ToastUtils.showError(
          context,
          jsonResponse["message"] ?? S.of(context).markFailed,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtils.handleHttpException(e, context);
    }
  }

  void _selectProduct(int index) {
    if (!_ready && _isInitializing) return;
    setState(() {
      selectedIndex = index;
      page = 1;
      _dataList.clear();
      _isLoading = true;
    });
    _getList();
    _fetchUnreadCounts();
  }

  void _selectTab(int index) {
    if (!_ready && _isInitializing) return;
    setState(() {
      tabsIndex = index;
      page = 1;
      _dataList.clear();
      _isLoading = true;
    });
    _getList();
    _refreshController.resetNoData();
    _refreshController.refreshCompleted();
  }

  Future<void> _openFeedbackDetail(Map<String, dynamic> item) async {
    final id = item["id"]?.toString();
    if (id == null || id.isEmpty) return;

    if (item["hasUnreadReply"]) {
      await _markFeedbackAsRead(id);
    }
    if (!mounted) return;

    Navigator.pushNamed(
      context,
      '/feedback_detail',
      arguments: {'issueId': id},
    );
  }

  int _statusFrom(Map<String, dynamic> item) {
    return int.tryParse(item["status"]?.toString() ?? '') ?? 0;
  }

  Widget _refreshHeader(BuildContext context, RefreshStatus? mode) {
    Widget body;
    if (mode == RefreshStatus.idle) {
      body = Text(S.of(context).pullToRefresh);
    } else if (mode == RefreshStatus.refreshing) {
      body = _RefreshInline(text: S.of(context).refreshing);
    } else if (mode == RefreshStatus.completed) {
      body = Text(S.of(context).refreshCompleted);
    } else if (mode == RefreshStatus.failed) {
      body = Text(S.of(context).refreshFailed);
    } else {
      body = Text(S.of(context).releaseToRefresh);
    }
    return SizedBox(height: 60, child: Center(child: body));
  }

  Widget _refreshFooter(BuildContext context, LoadStatus? mode) {
    Widget body;
    if (mode == LoadStatus.idle) {
      body = Text(S.of(context).pullToLoadMore);
    } else if (mode == LoadStatus.loading) {
      body = _RefreshInline(text: S.of(context).loading);
    } else if (mode == LoadStatus.failed) {
      body = Text(S.of(context).loadFailed);
    } else if (mode == LoadStatus.canLoading) {
      body = Text(S.of(context).releaseToLoadMore);
    } else {
      body = Text(S.of(context).noMoreData);
    }
    return SizedBox(height: 60, child: Center(child: body));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 420 ? 16.0 : 24.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FeedbackListHeader(
                  title: S.of(context).feedbackList,
                  subtitle: '${_dataList.length}/$_total',
                  horizontalPadding: horizontalPadding,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                _ProductFilterBar(
                  products: productOptions,
                  selectedIndex: selectedIndex,
                  horizontalPadding: horizontalPadding,
                  onSelected: _selectProduct,
                ),
                const SizedBox(height: 8),
                _FeedbackTabBar(
                  tabs: tabs,
                  counts: tabCounts,
                  selectedIndex: tabsIndex,
                  horizontalPadding: horizontalPadding,
                  onSelected: _selectTab,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child:
                      _isInitializing || (_isLoading && _dataList.isEmpty)
                          ? const Center(child: CircularProgressIndicator())
                          : _dataList.isEmpty
                          ? _EmptyState(text: S.of(context).noData)
                          : SmartRefresher(
                            controller: _refreshController,
                            enablePullDown: true,
                            enablePullUp: true,
                            onRefresh: _onRefresh,
                            onLoading: _onLoading,
                            header: CustomHeader(builder: _refreshHeader),
                            footer: CustomFooter(builder: _refreshFooter),
                            child: ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                10,
                                horizontalPadding,
                                96,
                              ),
                              itemCount: _dataList.length,
                              separatorBuilder:
                                  (context, index) =>
                                      const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = _dataList[index];
                                final status = _statusFrom(item);
                                return _FeedbackListCard(
                                  item: item,
                                  status: status,
                                  // isUnread: item["is_read"]?.toString() == "0",
                                  isUnread: item["hasUnreadReply"],
                                  createTimeLabel: S.of(context).createTime,
                                  onTap: () => _openFeedbackDetail(item),
                                );
                              },
                            ),
                          ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacementNamed(context, "/");
        },
        backgroundColor: _brandColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FeedbackListHeader extends StatelessWidget {
  const _FeedbackListHeader({
    required this.title,
    required this.subtitle,
    required this.horizontalPadding,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final double horizontalPadding;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 6, horizontalPadding, 8),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  isIOS ? Icons.arrow_back_ios_new : Icons.arrow_back_rounded,
                  color: _brandColor,
                  size: isIOS ? 20 : 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductFilterBar extends StatelessWidget {
  const _ProductFilterBar({
    required this.products,
    required this.selectedIndex,
    required this.horizontalPadding,
    required this.onSelected,
  });

  final List<Map<String, dynamic>> products;
  final int selectedIndex;
  final double horizontalPadding;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          final label = products[index]["label"]?.toString() ?? '';

          return _FilterChipButton(
            label: label,
            isSelected: isSelected,
            onTap: () => onSelected(index),
          );
        },
      ),
    );
  }
}

class _FeedbackTabBar extends StatelessWidget {
  const _FeedbackTabBar({
    required this.tabs,
    required this.counts,
    required this.selectedIndex,
    required this.horizontalPadding,
    required this.onSelected,
  });

  final List<String> tabs;
  final List<int> counts;
  final int selectedIndex;
  final double horizontalPadding;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          final count = index < counts.length ? counts[index] : 0;

          return _FilterChipButton(
            label: tabs[index],
            count: count,
            isSelected: isSelected,
            onTap: () => onSelected(index),
          );
        },
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count = 0,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? _brandColor : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? _brandColor : _borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : _textPrimary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFFD64545),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? _brandColor : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackListCard extends StatelessWidget {
  const _FeedbackListCard({
    required this.item,
    required this.status,
    required this.isUnread,
    required this.createTimeLabel,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final int status;
  final bool isUnread;
  final String createTimeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = StatusUtils.getStatusColor(status);
    final title = item["title"]?.toString() ?? '';
    final description = item["description"]?.toString() ?? '';
    final id = item["id"]?.toString() ?? '';
    final occurTime = item["occurTime"]?.toString() ?? '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusBadge(status: status, color: statusColor),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (isUnread) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD64545),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '$createTimeLabel: $occurTime',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final int status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        StatusUtils.getStatusText(context, status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: _textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefreshInline extends StatelessWidget {
  const _RefreshInline({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(text),
      ],
    );
  }
}
