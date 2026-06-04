import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medbot_ai_app/utils/http_service.dart';
import 'package:medbot_ai_app/widgets/attachment_preview.dart';
import 'package:medbot_ai_app/widgets/system_feedback_section.dart';
import 'package:medbot_ai_app/widgets/toast_utils.dart';
import 'package:medbot_ai_app/generated/l10n.dart';

const _brandColor = Color(0xFF042A72);
const _accentColor = Color(0xFF12A594);
const _pageBackground = Color(0xFFE5E5E5);
const _textPrimary = Color(0xFF172033);
const _textSecondary = Color(0xFF697386);
const _borderColor = Color(0xFFD8DEE9);

class FeedbackDetail extends StatefulWidget {
  const FeedbackDetail({super.key});

  @override
  State<FeedbackDetail> createState() => _FeedbackDetailState();
}

// 产品选项将在 build 方法中动态生成

class _FeedbackDetailState extends State<FeedbackDetail> {
  late String issueId;
  Map<String, dynamic>? feedbackData;
  bool isLoading = true;

  List<Map<String, dynamic>> get productOptions {
    return [
      {"label": S.of(context).all, "value": "100"},
      {"label": S.of(context).tumaiMultiPort, "value": "101"},
      {"label": S.of(context).tumaiSinglePort, "value": "102"},
      {"label": S.of(context).dragonflyEye, "value": "103"},
      {"label": S.of(context).honghu, "value": "104"},
      {"label": S.of(context).rone, "value": "105"},
      {"label": S.of(context).monaLisa, "value": "106"},
      {"label": S.of(context).other, "value": "107"},
    ];
  }

  String getProductLabel(String productId) {
    return productOptions.firstWhere(
      (item) => item['value'] == productId,
      orElse: () => {'label': S.of(context).unknown},
    )['label'];
  }

  bool isImage(String url) {
    return url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.png') ||
        url.endsWith('.gif');
  }

  bool isVideo(String url) {
    return url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.webm');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic> && args.containsKey('issueId')) {
      issueId = args['issueId'];
      fetchFeedbackDetail(issueId); // 开始加载详情
      markIsRead(issueId);
    } else {
      Navigator.pop(context); // 返回上一页或提示
    }
  }

  Future<void> fetchFeedbackDetail(String id) async {
    try {
      // ✅ 这里用模拟网络请求，你可以替换为 Dio、http 包等调用接口
      final response = await HttpService().get(
        'feedback/$id',
        // params: {'id': id},
      );
      if (!mounted) return;
      final result = jsonDecode(response.body);
      print('feedback detail: $result');
      if (result["status"] == 200) {
        setState(() {
          feedbackData = result['data'];
          isLoading = false;
        });
      } else {
        // 错误码处理
        ToastUtils.showError(
          context,
          result["message"] ?? S.of(context).getFailed,
        );
        setState(() {
          feedbackData = null;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch feedback detail failed: $e");
      if (!mounted) return;
      ToastUtils.showError(context, S.of(context).getFailed);
      setState(() {
        feedbackData = null;
        isLoading = false;
      });
    }
  }

  // 编辑已读
  // Future<void> markAsRead(String id) async {
  //   try {
  //     // ✅ 这里用模拟网络请求，你可以替换为 Dio、http 包等调用接口
  //     final response = await HttpService().get(
  //       'issus/detail',
  //       params: {'issueId': id},
  //     );
  //     final result = jsonDecode(response.body);
  //     if (result["code"] != -1) {
  //       setState(() {
  //         feedbackData = result['data'];
  //         isLoading = false;
  //       });
  //     } else {
  //       // 错误码处理
  //       ToastUtils.showError(context, result["message"] ?? "获取失败");
  //     }
  //   } catch (e) {
  //     print("加载失败: $e");
  //     // TODO: 错误处理
  //   }
  // }

  Future<void> markIsRead(String id) async {
    try {
      final response = await HttpService().put('feedback/$id/read');
      jsonDecode(response.body);
      // if (result["code"] != -1) {
      //   setState(() {
      //     feedbackData = result['data'];
      //     isLoading = false;
      //   });
      // } else {
      //   // 错误码处理
      //   ToastUtils.showError(context, result["message"] ?? "获取失败");
      // }
    } catch (e) {
      debugPrint("Mark feedback read failed: $e");
      // TODO: 错误处理
    }
  }

  // String? systemFeedback = "系统已收到您的问题，我们正在处理中。";
  String? systemFeedback;
  bool isAdmin = true; // 模拟管理员权限

  void handleFeedbackSubmit(String newFeedback) {
    setState(() {
      systemFeedback = newFeedback;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 初始化 systemFeedback
    systemFeedback ??= S.of(context).systemFeedbackMessage;

    if (isLoading) {
      return Scaffold(
        backgroundColor: _pageBackground,
        body: SafeArea(
          child: Column(
            children: [
              _FeedbackDetailHeader(
                title: S.of(context).loading,
                subtitle: '',
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }

    if (feedbackData == null) {
      return Scaffold(
        backgroundColor: _pageBackground,
        body: SafeArea(
          child: Column(
            children: [
              _FeedbackDetailHeader(
                title: S.of(context).loadFailed,
                subtitle: '',
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    S.of(context).cannotLoadFeedbackDetail,
                    style: const TextStyle(color: _textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final title = feedbackData!['title'];
    final feedbackType =
        int.tryParse(feedbackData!['feedbackType']?.toString() ?? '') ?? 0;

    String feedbackTypeText = '';
    switch (feedbackType) {
      case 1:
        feedbackTypeText = S.of(context).defectFeedback;
        break;
      case 2:
        feedbackTypeText = S.of(context).requirementFeedback;
        break;
      case 3:
        feedbackTypeText = S.of(context).otherFeedback;
        break;
      default:
        feedbackTypeText = S.of(context).unknownType;
    }
    final productId = feedbackData!['deviceType']?.toString() ?? '';
    final product = getProductLabel(productId);
    final deviceId = feedbackData!['deviceUdi']?.toString().trim() ?? '';
    final time = feedbackData!['occurTime']?.toString() ?? '';
    final status = feedbackData!['status'];
    final description = feedbackData!['description'];
    final comments = feedbackData!['comments'];
    final rating = feedbackData!['rating'];
    final advice = feedbackData!['advice'];
    final titleAudioId = feedbackData!['titleAudio']?.toString().trim() ?? '';
    final descriptionAudioId =
        feedbackData!['descriptionAudio']?.toString().trim() ?? '';
    final excludedAttachmentIds = <String>{
      if (titleAudioId.isNotEmpty) titleAudioId,
      if (descriptionAudioId.isNotEmpty) descriptionAudioId,
    };
    final attachmentsRaw = feedbackData!['attachments'];
    final attachments =
        attachmentsRaw is List
            ? attachmentsRaw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .map<Map<String, dynamic>>((item) {
                  final rawUrl = item['presignedUrl']?.toString();
                  final url = rawUrl == null ? '' : rawUrl.replaceAll('`', '').trim();
                  final filename = item['filename']?.toString() ?? '';
                  final fileTypeValue = item['fileType'];
                  final fileType =
                      fileTypeValue is int
                          ? fileTypeValue
                          : int.tryParse(fileTypeValue?.toString() ?? '');
                  String extOf(String value) {
                    final withoutQuery = value.split('?').first.trim();
                    final last = withoutQuery.split('/').last;
                    final dot = last.lastIndexOf('.');
                    return dot == -1 ? '' : last.substring(dot + 1).toLowerCase();
                  }

                  final ext = extOf(url).isNotEmpty ? extOf(url) : extOf(filename);
                  final isImageExt = const {'jpg', 'jpeg', 'png', 'gif', 'heic'}.contains(ext);
                  final isVideoExt = const {'mp4', 'mov', 'avi', 'webm'}.contains(ext);
                  final isAudioExt = const {'wav', 'aac', 'm4a'}.contains(ext);

                  final mappedType =
                      fileType == 1
                          ? 'image'
                          : fileType == 2
                          ? 'audio'
                          : fileType == 3
                          ? 'video'
                          : isImageExt
                          ? 'image'
                          : isVideoExt
                          ? 'video'
                          : isAudioExt
                          ? 'audio'
                          : 'file';
                  return {
                    'id': item['id'],
                    'file_type': mappedType,
                    'file_url': url,
                    'filename': filename,
                  };
                })
                .where((item) => item['file_type'] != 'audio')
                .where((item) => (item['file_url']?.toString() ?? '').isNotEmpty)
                .where(
                  (item) => !excludedAttachmentIds.contains(
                    item['id']?.toString().trim() ?? '',
                  ),
                )
                .toList()
            : <Map<String, dynamic>>[];
    final subtitleParts =
        <String>[
          product.toString(),
          feedbackTypeText,
          time,
        ].where((e) => e.trim().isNotEmpty).toList();

    final pageSubtitle = subtitleParts.join(' · ');

    String? systemReplyText;
    String systemReplyTime = '';
    if (comments is List && comments.isNotEmpty) {
      final last = comments.last;
      if (last is Map) {
        final text =
            last['content'] ??
            last['comment'] ??
            last['message'] ??
            last['text'];
        final timeValue =
            last['createTime'] ??
            last['createdAt'] ??
            last['updateTime'] ??
            last['time'];
        final normalizedText = text?.toString().trim();
        if (normalizedText != null && normalizedText.isNotEmpty) {
          systemReplyText = normalizedText;
        }
        systemReplyTime = timeValue?.toString() ?? '';
      }
    }

    final bool showEditButton = status?.toString() == "0";

    return Scaffold(
      backgroundColor: _pageBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _FeedbackDetailHeader(
              title: title?.toString() ?? S.of(context).unknown,
              subtitle: pageSubtitle,
              onBack: () => Navigator.of(context).maybePop(),
              trailing: buildStatusTag(status?.toString() ?? ''),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                children: [
                  _ContextHeader(
                    productText: product.toString(),
                    feedbackTypeText: feedbackTypeText,
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: '设备 ID',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.qr_code_2_rounded,
                          size: 18,
                          color: _textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            deviceId.isEmpty ? '--' : deviceId,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: S.of(context).problemTitle,
                    child: Text(
                      title?.toString() ?? '',
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: S.of(context).problemDescription,
                    child: Text(
                      description?.toString() ?? '',
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: S.of(context).occurTime,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_available_outlined,
                          size: 18,
                          color: _textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            time,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: S.of(context).uploadAttachment,
                    child:
                        attachments.isEmpty
                            ? Text(
                              S.of(context).noFeedback,
                              style: const TextStyle(color: _textSecondary),
                            )
                            : AttachmentPreview(attachments: attachments),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: S.of(context).systemFeedback,
                    titleTrailing: buildStatusTag(status?.toString() ?? ''),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          systemReplyText ??
                              systemFeedback ??
                              S.of(context).noFeedback,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                        if (systemReplyTime.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${S.of(context).feedbackTime}: $systemReplyTime',
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (status?.toString() != "0") ...[
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: S.of(context).pleaseFillSuggestion,
                      child: SystemFeedbackSection(
                        initialValue:
                            rating == null
                                ? null
                                : {
                                  "rating": rating.toString(),
                                  "comment": advice?.toString() ?? '',
                                },
                        showInput: rating == null,
                        onSubmit: (rating, suggestion) async {
                          final l10n = S.of(context);
                          try {
                            final response = await HttpService().post(
                              'feedback/$issueId/evaluate',
                              body: {
                                "rating": rating,
                                "advice": suggestion,
                              },
                            );
                            if (!context.mounted) return;
                            final result = jsonDecode(response.body);
                            if (result["status"] == 200) {
                              await fetchFeedbackDetail(issueId);
                              if (!context.mounted) return;
                              ToastUtils.showSuccess(context, l10n.commentSuccess);
                            } else {
                              ToastUtils.showError(
                                context,
                                result["message"] ?? l10n.getFailed,
                              );
                            }
                          } catch (e) {
                            debugPrint("Submit review failed: $e");
                            if (!context.mounted) return;
                            ToastUtils.showError(context, l10n.getFailed);
                          }
                        },
                      ),
                    ),
                  ],
                  if (showEditButton) const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          showEditButton
              ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit),
                      label: Text(
                        S.of(context).edit,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          "/feedback_edit",
                          arguments: issueId,
                        );
                      },
                    ),
                  ),
                ),
              )
              : null,
    );
  }

  Widget buildStatusTag(String status) {
    String text;
    Color bgColor;
    Color textColor;

    switch (status) {
      case "0":
        text = S.of(context).pending;
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        break;
      case "1":
        text = S.of(context).inProgress;
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case "2":
        text = S.of(context).completed;
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case "3":
        text = S.of(context).reviewed;
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      default:
        text = S.of(context).unknown;
        bgColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 13)),
    );
  }
}

class _FeedbackDetailHeader extends StatelessWidget {
  const _FeedbackDetailHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(12),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

class _ContextHeader extends StatelessWidget {
  const _ContextHeader({
    required this.productText,
    required this.feedbackTypeText,
  });

  final String productText;
  final String feedbackTypeText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.rate_review_outlined, color: _brandColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(text: productText, color: _brandColor),
                _InfoChip(text: feedbackTypeText, color: _accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.titleTrailing,
  });

  final String title;
  final Widget child;
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (titleTrailing != null) ...[
                const SizedBox(width: 10),
                titleTrailing!,
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
