// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Flutter 应用`
  String get appTitle {
    return Intl.message('Flutter 应用', name: 'appTitle', desc: '', args: []);
  }

  /// `首页`
  String get home {
    return Intl.message('首页', name: 'home', desc: '', args: []);
  }

  /// `案例`
  String get casePage {
    return Intl.message('案例', name: 'casePage', desc: '', args: []);
  }

  /// `视频`
  String get videoPage {
    return Intl.message('视频', name: 'videoPage', desc: '', args: []);
  }

  /// `我的`
  String get profilePage {
    return Intl.message('我的', name: 'profilePage', desc: '', args: []);
  }

  /// `设置`
  String get settings {
    return Intl.message('设置', name: 'settings', desc: '', args: []);
  }

  /// `全部`
  String get all {
    return Intl.message('全部', name: 'all', desc: '', args: []);
  }

  /// `图迈多孔`
  String get tumaiMultiPort {
    return Intl.message('图迈多孔', name: 'tumaiMultiPort', desc: '', args: []);
  }

  /// `图迈单孔`
  String get tumaiSinglePort {
    return Intl.message('图迈单孔', name: 'tumaiSinglePort', desc: '', args: []);
  }

  /// `蜻蜓眼`
  String get dragonflyEye {
    return Intl.message('蜻蜓眼', name: 'dragonflyEye', desc: '', args: []);
  }

  /// `鸿鹄`
  String get honghu {
    return Intl.message('鸿鹄', name: 'honghu', desc: '', args: []);
  }

  /// `Rone`
  String get rone {
    return Intl.message('Rone', name: 'rone', desc: '', args: []);
  }

  /// `蒙娜丽莎`
  String get monaLisa {
    return Intl.message('蒙娜丽莎', name: 'monaLisa', desc: '', args: []);
  }

  /// `其他`
  String get other {
    return Intl.message('其他', name: 'other', desc: '', args: []);
  }

  /// `缺陷反馈`
  String get defectFeedback {
    return Intl.message('缺陷反馈', name: 'defectFeedback', desc: '', args: []);
  }

  /// `需求反馈`
  String get requirementFeedback {
    return Intl.message(
      '需求反馈',
      name: 'requirementFeedback',
      desc: '',
      args: [],
    );
  }

  /// `其他反馈`
  String get otherFeedback {
    return Intl.message('其他反馈', name: 'otherFeedback', desc: '', args: []);
  }

  /// `获取未读数失败`
  String get getUnreadCountFailed {
    return Intl.message(
      '获取未读数失败',
      name: 'getUnreadCountFailed',
      desc: '',
      args: [],
    );
  }

  /// `获取失败`
  String get getDataFailed {
    return Intl.message('获取失败', name: 'getDataFailed', desc: '', args: []);
  }

  /// `已标记为已读`
  String get markedAsRead {
    return Intl.message('已标记为已读', name: 'markedAsRead', desc: '', args: []);
  }

  /// `标记失败`
  String get markFailed {
    return Intl.message('标记失败', name: 'markFailed', desc: '', args: []);
  }

  /// `暂无数据`
  String get noData {
    return Intl.message('暂无数据', name: 'noData', desc: '', args: []);
  }

  /// `下拉可以刷新`
  String get pullToRefresh {
    return Intl.message('下拉可以刷新', name: 'pullToRefresh', desc: '', args: []);
  }

  /// `正在刷新...`
  String get refreshing {
    return Intl.message('正在刷新...', name: 'refreshing', desc: '', args: []);
  }

  /// `刷新完成`
  String get refreshCompleted {
    return Intl.message('刷新完成', name: 'refreshCompleted', desc: '', args: []);
  }

  /// `刷新失败`
  String get refreshFailed {
    return Intl.message('刷新失败', name: 'refreshFailed', desc: '', args: []);
  }

  /// `松开刷新`
  String get releaseToRefresh {
    return Intl.message('松开刷新', name: 'releaseToRefresh', desc: '', args: []);
  }

  /// `上拉加载更多`
  String get pullToLoadMore {
    return Intl.message('上拉加载更多', name: 'pullToLoadMore', desc: '', args: []);
  }

  /// `加载中...`
  String get loading {
    return Intl.message('加载中...', name: 'loading', desc: '', args: []);
  }

  /// `加载失败`
  String get loadFailed {
    return Intl.message('加载失败', name: 'loadFailed', desc: '', args: []);
  }

  /// `松手加载更多`
  String get releaseToLoadMore {
    return Intl.message(
      '松手加载更多',
      name: 'releaseToLoadMore',
      desc: '',
      args: [],
    );
  }

  /// `没有更多数据了`
  String get noMoreData {
    return Intl.message('没有更多数据了', name: 'noMoreData', desc: '', args: []);
  }

  /// `创建时间`
  String get createTime {
    return Intl.message('创建时间', name: 'createTime', desc: '', args: []);
  }

  /// `切换到键盘输入`
  String get switchToKeyboard {
    return Intl.message(
      '切换到键盘输入',
      name: 'switchToKeyboard',
      desc: '',
      args: [],
    );
  }

  /// `缺少 issueId`
  String get missingIssueId {
    return Intl.message(
      '缺少 issueId',
      name: 'missingIssueId',
      desc: '',
      args: [],
    );
  }

  /// `加载异常`
  String get loadException {
    return Intl.message('加载异常', name: 'loadException', desc: '', args: []);
  }

  /// `当前正在识别语音，请稍后...`
  String get currentlyRecognizing {
    return Intl.message(
      '当前正在识别语音，请稍后...',
      name: 'currentlyRecognizing',
      desc: '',
      args: [],
    );
  }

  /// `请选择反馈类型`
  String get pleaseSelectFeedbackType {
    return Intl.message(
      '请选择反馈类型',
      name: 'pleaseSelectFeedbackType',
      desc: '',
      args: [],
    );
  }

  /// `请选择产品类型`
  String get pleaseSelectProductType {
    return Intl.message(
      '请选择产品类型',
      name: 'pleaseSelectProductType',
      desc: '',
      args: [],
    );
  }

  /// `语音识别中~...`
  String get voiceRecognizing {
    return Intl.message(
      '语音识别中~...',
      name: 'voiceRecognizing',
      desc: '',
      args: [],
    );
  }

  /// `语音识别中，暂不可输入...`
  String get voiceRecognizingHint {
    return Intl.message(
      '语音识别中，暂不可输入...',
      name: 'voiceRecognizingHint',
      desc: '',
      args: [],
    );
  }

  /// `请输入内容`
  String get pleaseEnterContent {
    return Intl.message(
      '请输入内容',
      name: 'pleaseEnterContent',
      desc: '',
      args: [],
    );
  }

  /// `请输入邮箱`
  String get pleaseEnterAccount {
    return Intl.message(
      '请输入邮箱',
      name: 'pleaseEnterAccount',
      desc: '',
      args: [],
    );
  }

  /// `请输入密码`
  String get pleaseEnterPwd {
    return Intl.message('请输入密码', name: 'pleaseEnterPwd', desc: '', args: []);
  }

  /// `删除了文件`
  String get fileDeleted {
    return Intl.message('删除了文件', name: 'fileDeleted', desc: '', args: []);
  }

  /// `已从 _selectedMediaFiles 移除`
  String get removedFromSelected {
    return Intl.message(
      '已从 _selectedMediaFiles 移除',
      name: 'removedFromSelected',
      desc: '',
      args: [],
    );
  }

  /// `反馈类型`
  String get feedbackType {
    return Intl.message('反馈类型', name: 'feedbackType', desc: '', args: []);
  }

  /// `产品类型`
  String get productType {
    return Intl.message('产品类型', name: 'productType', desc: '', args: []);
  }

  /// `未知类型`
  String get unknownType {
    return Intl.message('未知类型', name: 'unknownType', desc: '', args: []);
  }

  /// `未知`
  String get unknown {
    return Intl.message('未知', name: 'unknown', desc: '', args: []);
  }

  /// `CEO直通Linkedin`
  String get ceoLinkedin {
    return Intl.message(
      'CEO直通Linkedin',
      name: 'ceoLinkedin',
      desc: '',
      args: [],
    );
  }

  /// `CEO直通Linkedin,是否继续前往?`
  String get ceoLinkedinConfirm {
    return Intl.message(
      'CEO直通Linkedin,是否继续前往?',
      name: 'ceoLinkedinConfirm',
      desc: '',
      args: [],
    );
  }

  /// `取消`
  String get cancel {
    return Intl.message('取消', name: 'cancel', desc: '', args: []);
  }

  /// `继续`
  String get continues {
    return Intl.message('继续', name: 'continues', desc: '', args: []);
  }

  /// `© 2025 Company. All rights reserved.`
  String get copyright {
    return Intl.message(
      '© 2025 Company. All rights reserved.',
      name: 'copyright',
      desc: '',
      args: [],
    );
  }

  /// `中文`
  String get chinese {
    return Intl.message('中文', name: 'chinese', desc: '', args: []);
  }

  /// `English`
  String get english {
    return Intl.message('English', name: 'english', desc: '', args: []);
  }

  /// `识别错误`
  String get recognitionError {
    return Intl.message('识别错误', name: 'recognitionError', desc: '', args: []);
  }

  /// `上传失败`
  String get uploadFailed {
    return Intl.message('上传失败', name: 'uploadFailed', desc: '', args: []);
  }

  /// `设备选择`
  String get deviceSelection {
    return Intl.message('设备选择', name: 'deviceSelection', desc: '', args: []);
  }

  /// `选择设备`
  String get selectDevice {
    return Intl.message('选择设备', name: 'selectDevice', desc: '', args: []);
  }

  /// `其他服务`
  String get otherService {
    return Intl.message('其他服务', name: 'otherService', desc: '', args: []);
  }

  /// `反馈与沟通`
  String get feedbackForm {
    return Intl.message('反馈与沟通', name: 'feedbackForm', desc: '', args: []);
  }

  /// `反馈列表`
  String get feedbackList {
    return Intl.message('反馈列表', name: 'feedbackList', desc: '', args: []);
  }

  /// `请选择您需要的反馈类型,我们会尽快为您处理。`
  String get feedbackInstruction {
    return Intl.message(
      '请选择您需要的反馈类型,我们会尽快为您处理。',
      name: 'feedbackInstruction',
      desc: '',
      args: [],
    );
  }

  /// `报告软件或产品中的缺陷问题`
  String get defectFeedbackDesc1 {
    return Intl.message(
      '报告软件或产品中的缺陷问题',
      name: 'defectFeedbackDesc1',
      desc: '',
      args: [],
    );
  }

  /// `帮助我们快速定位并修复错误`
  String get defectFeedbackDesc2 {
    return Intl.message(
      '帮助我们快速定位并修复错误',
      name: 'defectFeedbackDesc2',
      desc: '',
      args: [],
    );
  }

  /// `提出新功能和改进建议`
  String get requirementFeedbackDesc1 {
    return Intl.message(
      '提出新功能和改进建议',
      name: 'requirementFeedbackDesc1',
      desc: '',
      args: [],
    );
  }

  /// `帮助我们优化产品体验`
  String get requirementFeedbackDesc2 {
    return Intl.message(
      '帮助我们优化产品体验',
      name: 'requirementFeedbackDesc2',
      desc: '',
      args: [],
    );
  }

  /// `咨询产品相关服务`
  String get otherServiceDesc1 {
    return Intl.message(
      '咨询产品相关服务',
      name: 'otherServiceDesc1',
      desc: '',
      args: [],
    );
  }

  /// `获取更多帮助与支持`
  String get otherServiceDesc2 {
    return Intl.message(
      '获取更多帮助与支持',
      name: 'otherServiceDesc2',
      desc: '',
      args: [],
    );
  }

  /// `创建反馈`
  String get createFeedback {
    return Intl.message('创建反馈', name: 'createFeedback', desc: '', args: []);
  }

  /// `标题`
  String get title {
    return Intl.message('标题', name: 'title', desc: '', args: []);
  }

  /// `描述`
  String get description {
    return Intl.message('描述', name: 'description', desc: '', args: []);
  }

  /// `提交`
  String get submit {
    return Intl.message('提交', name: 'submit', desc: '', args: []);
  }

  /// `保存`
  String get save {
    return Intl.message('保存', name: 'save', desc: '', args: []);
  }

  /// `编辑`
  String get edit {
    return Intl.message('编辑', name: 'edit', desc: '', args: []);
  }

  /// `删除`
  String get delete {
    return Intl.message('删除', name: 'delete', desc: '', args: []);
  }

  /// `确认`
  String get confirm {
    return Intl.message('确认', name: 'confirm', desc: '', args: []);
  }

  /// `返回`
  String get back {
    return Intl.message('返回', name: 'back', desc: '', args: []);
  }

  /// `下一步`
  String get next {
    return Intl.message('下一步', name: 'next', desc: '', args: []);
  }

  /// `上一步`
  String get previous {
    return Intl.message('上一步', name: 'previous', desc: '', args: []);
  }

  /// `完成`
  String get finish {
    return Intl.message('完成', name: 'finish', desc: '', args: []);
  }

  /// `登录`
  String get login {
    return Intl.message('登录', name: 'login', desc: '', args: []);
  }

  /// `注册`
  String get register {
    return Intl.message('注册', name: 'register', desc: '', args: []);
  }

  /// `退出登录`
  String get logout {
    return Intl.message('退出登录', name: 'logout', desc: '', args: []);
  }

  /// `忘记密码`
  String get forgotPassword {
    return Intl.message('忘记密码', name: 'forgotPassword', desc: '', args: []);
  }

  /// `修改密码`
  String get changePassword {
    return Intl.message('修改密码', name: 'changePassword', desc: '', args: []);
  }

  /// `注销账户`
  String get destroyAccount {
    return Intl.message('注销账户', name: 'destroyAccount', desc: '', args: []);
  }

  /// `用户编辑`
  String get userEdit {
    return Intl.message('用户编辑', name: 'userEdit', desc: '', args: []);
  }

  /// `个人资料`
  String get profile {
    return Intl.message('个人资料', name: 'profile', desc: '', args: []);
  }

  /// `语言`
  String get language {
    return Intl.message('语言', name: 'language', desc: '', args: []);
  }

  /// `关于`
  String get about {
    return Intl.message('关于', name: 'about', desc: '', args: []);
  }

  /// `帮助`
  String get help {
    return Intl.message('帮助', name: 'help', desc: '', args: []);
  }

  /// `联系我们`
  String get contact {
    return Intl.message('联系我们', name: 'contact', desc: '', args: []);
  }

  /// `隐私政策`
  String get privacy {
    return Intl.message('隐私政策', name: 'privacy', desc: '', args: []);
  }

  /// `服务条款`
  String get terms {
    return Intl.message('服务条款', name: 'terms', desc: '', args: []);
  }

  /// `版本`
  String get version {
    return Intl.message('版本', name: 'version', desc: '', args: []);
  }

  /// `邮箱`
  String get email {
    return Intl.message('邮箱', name: 'email', desc: '', args: []);
  }

  /// `密码`
  String get password {
    return Intl.message('密码', name: 'password', desc: '', args: []);
  }

  /// `确认密码`
  String get confirmPassword {
    return Intl.message('确认密码', name: 'confirmPassword', desc: '', args: []);
  }

  /// `电话`
  String get phone {
    return Intl.message('电话', name: 'phone', desc: '', args: []);
  }

  /// `国家`
  String get country {
    return Intl.message('国家', name: 'country', desc: '', args: []);
  }

  /// `用户名`
  String get username {
    return Intl.message('用户名', name: 'username', desc: '', args: []);
  }

  /// `昵称`
  String get nickname {
    return Intl.message('昵称', name: 'nickname', desc: '', args: []);
  }

  /// `头像`
  String get avatar {
    return Intl.message('头像', name: 'avatar', desc: '', args: []);
  }

  /// `性别`
  String get gender {
    return Intl.message('性别', name: 'gender', desc: '', args: []);
  }

  /// `男`
  String get male {
    return Intl.message('男', name: 'male', desc: '', args: []);
  }

  /// `女`
  String get female {
    return Intl.message('女', name: 'female', desc: '', args: []);
  }

  /// `生日`
  String get birthday {
    return Intl.message('生日', name: 'birthday', desc: '', args: []);
  }

  /// `地址`
  String get address {
    return Intl.message('地址', name: 'address', desc: '', args: []);
  }

  /// `公司`
  String get company {
    return Intl.message('公司', name: 'company', desc: '', args: []);
  }

  /// `职位`
  String get position {
    return Intl.message('职位', name: 'position', desc: '', args: []);
  }

  /// `部门`
  String get department {
    return Intl.message('部门', name: 'department', desc: '', args: []);
  }

  /// `经理`
  String get manager {
    return Intl.message('经理', name: 'manager', desc: '', args: []);
  }

  /// `员工`
  String get employee {
    return Intl.message('员工', name: 'employee', desc: '', args: []);
  }

  /// `管理员`
  String get admin {
    return Intl.message('管理员', name: 'admin', desc: '', args: []);
  }

  /// `用户`
  String get user {
    return Intl.message('用户', name: 'user', desc: '', args: []);
  }

  /// `访客`
  String get guest {
    return Intl.message('访客', name: 'guest', desc: '', args: []);
  }

  /// `状态`
  String get status {
    return Intl.message('状态', name: 'status', desc: '', args: []);
  }

  /// `活跃`
  String get active {
    return Intl.message('活跃', name: 'active', desc: '', args: []);
  }

  /// `非活跃`
  String get inactive {
    return Intl.message('非活跃', name: 'inactive', desc: '', args: []);
  }

  /// `未处理`
  String get pending {
    return Intl.message('未处理', name: 'pending', desc: '', args: []);
  }

  /// `已批准`
  String get approved {
    return Intl.message('已批准', name: 'approved', desc: '', args: []);
  }

  /// `已拒绝`
  String get rejected {
    return Intl.message('已拒绝', name: 'rejected', desc: '', args: []);
  }

  /// `已完成`
  String get completed {
    return Intl.message('已完成', name: 'completed', desc: '', args: []);
  }

  /// `已评价`
  String get reviewed {
    return Intl.message('已评价', name: 'reviewed', desc: '', args: []);
  }

  /// `处理中`
  String get inProgress {
    return Intl.message('处理中', name: 'inProgress', desc: '', args: []);
  }

  /// `已取消`
  String get cancelled {
    return Intl.message('已取消', name: 'cancelled', desc: '', args: []);
  }

  /// `已过期`
  String get expired {
    return Intl.message('已过期', name: 'expired', desc: '', args: []);
  }

  /// `草稿`
  String get draft {
    return Intl.message('草稿', name: 'draft', desc: '', args: []);
  }

  /// `已发布`
  String get published {
    return Intl.message('已发布', name: 'published', desc: '', args: []);
  }

  /// `已归档`
  String get archived {
    return Intl.message('已归档', name: 'archived', desc: '', args: []);
  }

  /// `优先级`
  String get priority {
    return Intl.message('优先级', name: 'priority', desc: '', args: []);
  }

  /// `高`
  String get high {
    return Intl.message('高', name: 'high', desc: '', args: []);
  }

  /// `中`
  String get medium {
    return Intl.message('中', name: 'medium', desc: '', args: []);
  }

  /// `低`
  String get low {
    return Intl.message('低', name: 'low', desc: '', args: []);
  }

  /// `紧急`
  String get urgent {
    return Intl.message('紧急', name: 'urgent', desc: '', args: []);
  }

  /// `普通`
  String get normal {
    return Intl.message('普通', name: 'normal', desc: '', args: []);
  }

  /// `重要`
  String get important {
    return Intl.message('重要', name: 'important', desc: '', args: []);
  }

  /// `可选`
  String get optional {
    return Intl.message('可选', name: 'optional', desc: '', args: []);
  }

  /// `必填`
  String get required {
    return Intl.message('必填', name: 'required', desc: '', args: []);
  }

  /// `是`
  String get yes {
    return Intl.message('是', name: 'yes', desc: '', args: []);
  }

  /// `否`
  String get no {
    return Intl.message('否', name: 'no', desc: '', args: []);
  }

  /// `确定`
  String get ok {
    return Intl.message('确定', name: 'ok', desc: '', args: []);
  }

  /// `关闭`
  String get close {
    return Intl.message('关闭', name: 'close', desc: '', args: []);
  }

  /// `打开`
  String get open {
    return Intl.message('打开', name: 'open', desc: '', args: []);
  }

  /// `刷新`
  String get refresh {
    return Intl.message('刷新', name: 'refresh', desc: '', args: []);
  }

  /// `重新加载`
  String get reload {
    return Intl.message('重新加载', name: 'reload', desc: '', args: []);
  }

  /// `搜索`
  String get search {
    return Intl.message('搜索', name: 'search', desc: '', args: []);
  }

  /// `筛选`
  String get filter {
    return Intl.message('筛选', name: 'filter', desc: '', args: []);
  }

  /// `排序`
  String get sort {
    return Intl.message('排序', name: 'sort', desc: '', args: []);
  }

  /// `升序`
  String get ascending {
    return Intl.message('升序', name: 'ascending', desc: '', args: []);
  }

  /// `降序`
  String get descending {
    return Intl.message('降序', name: 'descending', desc: '', args: []);
  }

  /// `无`
  String get none {
    return Intl.message('无', name: 'none', desc: '', args: []);
  }

  /// `全选`
  String get selectAll {
    return Intl.message('全选', name: 'selectAll', desc: '', args: []);
  }

  /// `清除`
  String get clear {
    return Intl.message('清除', name: 'clear', desc: '', args: []);
  }

  /// `重置`
  String get reset {
    return Intl.message('重置', name: 'reset', desc: '', args: []);
  }

  /// `应用`
  String get apply {
    return Intl.message('应用', name: 'apply', desc: '', args: []);
  }

  /// `预览`
  String get preview {
    return Intl.message('预览', name: 'preview', desc: '', args: []);
  }

  /// `下载`
  String get download {
    return Intl.message('下载', name: 'download', desc: '', args: []);
  }

  /// `上传`
  String get upload {
    return Intl.message('上传', name: 'upload', desc: '', args: []);
  }

  /// `分享`
  String get share {
    return Intl.message('分享', name: 'share', desc: '', args: []);
  }

  /// `复制`
  String get copy {
    return Intl.message('复制', name: 'copy', desc: '', args: []);
  }

  /// `粘贴`
  String get paste {
    return Intl.message('粘贴', name: 'paste', desc: '', args: []);
  }

  /// `剪切`
  String get cut {
    return Intl.message('剪切', name: 'cut', desc: '', args: []);
  }

  /// `撤销`
  String get undo {
    return Intl.message('撤销', name: 'undo', desc: '', args: []);
  }

  /// `重做`
  String get redo {
    return Intl.message('重做', name: 'redo', desc: '', args: []);
  }

  /// `选择`
  String get select {
    return Intl.message('选择', name: 'select', desc: '', args: []);
  }

  /// `取消选择`
  String get deselect {
    return Intl.message('取消选择', name: 'deselect', desc: '', args: []);
  }

  /// `展开`
  String get expand {
    return Intl.message('展开', name: 'expand', desc: '', args: []);
  }

  /// `收起`
  String get collapse {
    return Intl.message('收起', name: 'collapse', desc: '', args: []);
  }

  /// `显示`
  String get show {
    return Intl.message('显示', name: 'show', desc: '', args: []);
  }

  /// `隐藏`
  String get hide {
    return Intl.message('隐藏', name: 'hide', desc: '', args: []);
  }

  /// `启用`
  String get enable {
    return Intl.message('启用', name: 'enable', desc: '', args: []);
  }

  /// `禁用`
  String get disable {
    return Intl.message('禁用', name: 'disable', desc: '', args: []);
  }

  /// `开启`
  String get on {
    return Intl.message('开启', name: 'on', desc: '', args: []);
  }

  /// `关闭`
  String get off {
    return Intl.message('关闭', name: 'off', desc: '', args: []);
  }

  /// `开始`
  String get start {
    return Intl.message('开始', name: 'start', desc: '', args: []);
  }

  /// `停止`
  String get stop {
    return Intl.message('停止', name: 'stop', desc: '', args: []);
  }

  /// `暂停`
  String get pause {
    return Intl.message('暂停', name: 'pause', desc: '', args: []);
  }

  /// `继续`
  String get resume {
    return Intl.message('继续', name: 'resume', desc: '', args: []);
  }

  /// `播放`
  String get play {
    return Intl.message('播放', name: 'play', desc: '', args: []);
  }

  /// `录制`
  String get record {
    return Intl.message('录制', name: 'record', desc: '', args: []);
  }

  /// `听取`
  String get listen {
    return Intl.message('听取', name: 'listen', desc: '', args: []);
  }

  /// `说话`
  String get speak {
    return Intl.message('说话', name: 'speak', desc: '', args: []);
  }

  /// `输入`
  String get type {
    return Intl.message('输入', name: 'type', desc: '', args: []);
  }

  /// `语音`
  String get voice {
    return Intl.message('语音', name: 'voice', desc: '', args: []);
  }

  /// `文本`
  String get text {
    return Intl.message('文本', name: 'text', desc: '', args: []);
  }

  /// `图片`
  String get image {
    return Intl.message('图片', name: 'image', desc: '', args: []);
  }

  /// `视频`
  String get video {
    return Intl.message('视频', name: 'video', desc: '', args: []);
  }

  /// `音频`
  String get audio {
    return Intl.message('音频', name: 'audio', desc: '', args: []);
  }

  /// `文件`
  String get file {
    return Intl.message('文件', name: 'file', desc: '', args: []);
  }

  /// `文件夹`
  String get folder {
    return Intl.message('文件夹', name: 'folder', desc: '', args: []);
  }

  /// `文档`
  String get document {
    return Intl.message('文档', name: 'document', desc: '', args: []);
  }

  /// `附件`
  String get attachment {
    return Intl.message('附件', name: 'attachment', desc: '', args: []);
  }

  /// `链接`
  String get link {
    return Intl.message('链接', name: 'link', desc: '', args: []);
  }

  /// `网址`
  String get url {
    return Intl.message('网址', name: 'url', desc: '', args: []);
  }

  /// `日期`
  String get date {
    return Intl.message('日期', name: 'date', desc: '', args: []);
  }

  /// `时间`
  String get time {
    return Intl.message('时间', name: 'time', desc: '', args: []);
  }

  /// `日期时间`
  String get datetime {
    return Intl.message('日期时间', name: 'datetime', desc: '', args: []);
  }

  /// `今天`
  String get today {
    return Intl.message('今天', name: 'today', desc: '', args: []);
  }

  /// `昨天`
  String get yesterday {
    return Intl.message('昨天', name: 'yesterday', desc: '', args: []);
  }

  /// `明天`
  String get tomorrow {
    return Intl.message('明天', name: 'tomorrow', desc: '', args: []);
  }

  /// `本周`
  String get thisWeek {
    return Intl.message('本周', name: 'thisWeek', desc: '', args: []);
  }

  /// `上周`
  String get lastWeek {
    return Intl.message('上周', name: 'lastWeek', desc: '', args: []);
  }

  /// `下周`
  String get nextWeek {
    return Intl.message('下周', name: 'nextWeek', desc: '', args: []);
  }

  /// `本月`
  String get thisMonth {
    return Intl.message('本月', name: 'thisMonth', desc: '', args: []);
  }

  /// `上月`
  String get lastMonth {
    return Intl.message('上月', name: 'lastMonth', desc: '', args: []);
  }

  /// `下月`
  String get nextMonth {
    return Intl.message('下月', name: 'nextMonth', desc: '', args: []);
  }

  /// `今年`
  String get thisYear {
    return Intl.message('今年', name: 'thisYear', desc: '', args: []);
  }

  /// `去年`
  String get lastYear {
    return Intl.message('去年', name: 'lastYear', desc: '', args: []);
  }

  /// `明年`
  String get nextYear {
    return Intl.message('明年', name: 'nextYear', desc: '', args: []);
  }

  /// `上午`
  String get morning {
    return Intl.message('上午', name: 'morning', desc: '', args: []);
  }

  /// `下午`
  String get afternoon {
    return Intl.message('下午', name: 'afternoon', desc: '', args: []);
  }

  /// `晚上`
  String get evening {
    return Intl.message('晚上', name: 'evening', desc: '', args: []);
  }

  /// `夜间`
  String get night {
    return Intl.message('夜间', name: 'night', desc: '', args: []);
  }

  /// `工作日`
  String get weekday {
    return Intl.message('工作日', name: 'weekday', desc: '', args: []);
  }

  /// `周末`
  String get weekend {
    return Intl.message('周末', name: 'weekend', desc: '', args: []);
  }

  /// `周一`
  String get monday {
    return Intl.message('周一', name: 'monday', desc: '', args: []);
  }

  /// `周二`
  String get tuesday {
    return Intl.message('周二', name: 'tuesday', desc: '', args: []);
  }

  /// `周三`
  String get wednesday {
    return Intl.message('周三', name: 'wednesday', desc: '', args: []);
  }

  /// `周四`
  String get thursday {
    return Intl.message('周四', name: 'thursday', desc: '', args: []);
  }

  /// `周五`
  String get friday {
    return Intl.message('周五', name: 'friday', desc: '', args: []);
  }

  /// `周六`
  String get saturday {
    return Intl.message('周六', name: 'saturday', desc: '', args: []);
  }

  /// `周日`
  String get sunday {
    return Intl.message('周日', name: 'sunday', desc: '', args: []);
  }

  /// `一月`
  String get january {
    return Intl.message('一月', name: 'january', desc: '', args: []);
  }

  /// `二月`
  String get february {
    return Intl.message('二月', name: 'february', desc: '', args: []);
  }

  /// `三月`
  String get march {
    return Intl.message('三月', name: 'march', desc: '', args: []);
  }

  /// `四月`
  String get april {
    return Intl.message('四月', name: 'april', desc: '', args: []);
  }

  /// `五月`
  String get may {
    return Intl.message('五月', name: 'may', desc: '', args: []);
  }

  /// `六月`
  String get june {
    return Intl.message('六月', name: 'june', desc: '', args: []);
  }

  /// `七月`
  String get july {
    return Intl.message('七月', name: 'july', desc: '', args: []);
  }

  /// `八月`
  String get august {
    return Intl.message('八月', name: 'august', desc: '', args: []);
  }

  /// `九月`
  String get september {
    return Intl.message('九月', name: 'september', desc: '', args: []);
  }

  /// `十月`
  String get october {
    return Intl.message('十月', name: 'october', desc: '', args: []);
  }

  /// `十一月`
  String get november {
    return Intl.message('十一月', name: 'november', desc: '', args: []);
  }

  /// `十二月`
  String get december {
    return Intl.message('十二月', name: 'december', desc: '', args: []);
  }

  /// `错误`
  String get error {
    return Intl.message('错误', name: 'error', desc: '', args: []);
  }

  /// `松开结束`
  String get releaseToEnd {
    return Intl.message('松开结束', name: 'releaseToEnd', desc: '', args: []);
  }

  /// `长按说话`
  String get longPressToSpeak {
    return Intl.message('长按说话', name: 'longPressToSpeak', desc: '', args: []);
  }

  /// `思考中▍`
  String get thinking {
    return Intl.message('思考中▍', name: 'thinking', desc: '', args: []);
  }

  /// `Medbot-AI 助手`
  String get medbotAiAssistant {
    return Intl.message(
      'Medbot-AI 助手',
      name: 'medbotAiAssistant',
      desc: '',
      args: [],
    );
  }

  /// `内容为空，请重新录入`
  String get contentEmptyPleaseReenter {
    return Intl.message(
      '内容为空，请重新录入',
      name: 'contentEmptyPleaseReenter',
      desc: '',
      args: [],
    );
  }

  /// `请选择时间`
  String get pleaseSelectTime {
    return Intl.message('请选择时间', name: 'pleaseSelectTime', desc: '', args: []);
  }

  /// `从图库选择`
  String get selectFromGallery {
    return Intl.message('从图库选择', name: 'selectFromGallery', desc: '', args: []);
  }

  /// `拍照`
  String get takePhoto {
    return Intl.message('拍照', name: 'takePhoto', desc: '', args: []);
  }

  /// `录像`
  String get recordVideo {
    return Intl.message('录像', name: 'recordVideo', desc: '', args: []);
  }

  /// `成功`
  String get success {
    return Intl.message('成功', name: 'success', desc: '', args: []);
  }

  /// `反馈已成功提交！`
  String get feedbackSubmittedSuccessfully {
    return Intl.message(
      '反馈已成功提交！',
      name: 'feedbackSubmittedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `提交失败`
  String get submitFailed {
    return Intl.message('提交失败', name: 'submitFailed', desc: '', args: []);
  }

  /// `提交成功`
  String get submitSuccess {
    return Intl.message('提交成功', name: 'submitSuccess', desc: '', args: []);
  }

  /// `已选择视频`
  String get videoSelected {
    return Intl.message('已选择视频', name: 'videoSelected', desc: '', args: []);
  }

  /// `问题标题`
  String get problemTitle {
    return Intl.message('问题标题', name: 'problemTitle', desc: '', args: []);
  }

  /// `请输入问题标题`
  String get pleaseEnterProblemTitle {
    return Intl.message(
      '请输入问题标题',
      name: 'pleaseEnterProblemTitle',
      desc: '',
      args: [],
    );
  }

  /// `请输入标题`
  String get pleaseEnterTitle {
    return Intl.message('请输入标题', name: 'pleaseEnterTitle', desc: '', args: []);
  }

  /// `标题录音`
  String get titleRecording {
    return Intl.message('标题录音', name: 'titleRecording', desc: '', args: []);
  }

  /// `问题描述`
  String get problemDescription {
    return Intl.message('问题描述', name: 'problemDescription', desc: '', args: []);
  }

  /// `请输入问题内容`
  String get pleaseEnterProblemContent {
    return Intl.message(
      '请输入问题内容',
      name: 'pleaseEnterProblemContent',
      desc: '',
      args: [],
    );
  }

  /// `描述录音`
  String get descriptionRecording {
    return Intl.message(
      '描述录音',
      name: 'descriptionRecording',
      desc: '',
      args: [],
    );
  }

  /// `发生时间`
  String get occurTime {
    return Intl.message('发生时间', name: 'occurTime', desc: '', args: []);
  }

  /// `上传附件`
  String get uploadAttachment {
    return Intl.message('上传附件', name: 'uploadAttachment', desc: '', args: []);
  }

  /// `点击上传图片或视频`
  String get clickToUpload {
    return Intl.message('点击上传图片或视频', name: 'clickToUpload', desc: '', args: []);
  }

  /// `错误代码`
  String get errorCode {
    return Intl.message('错误代码', name: 'errorCode', desc: '', args: []);
  }

  /// `解析结果异常`
  String get parseResultException {
    return Intl.message(
      '解析结果异常',
      name: 'parseResultException',
      desc: '',
      args: [],
    );
  }

  /// `WebSocket连接关闭`
  String get webSocketConnectionClosed {
    return Intl.message(
      'WebSocket连接关闭',
      name: 'webSocketConnectionClosed',
      desc: '',
      args: [],
    );
  }

  /// `WebSocket错误`
  String get webSocketError {
    return Intl.message(
      'WebSocket错误',
      name: 'webSocketError',
      desc: '',
      args: [],
    );
  }

  /// `CEO直通Linkedin、Medbot Linkedin`
  String get ceoLinkedinAndMedbotLinkedin {
    return Intl.message(
      'CEO直通Linkedin、Medbot Linkedin',
      name: 'ceoLinkedinAndMedbotLinkedin',
      desc: '',
      args: [],
    );
  }

  /// `识别二维码`
  String get recognizeQRCode {
    return Intl.message('识别二维码', name: 'recognizeQRCode', desc: '', args: []);
  }

  /// `已检测到二维码。是否前往公司官网？`
  String get qrCodeDetectedGoToWebsite {
    return Intl.message(
      '已检测到二维码。是否前往公司官网？',
      name: 'qrCodeDetectedGoToWebsite',
      desc: '',
      args: [],
    );
  }

  /// `跳转到公司官网...`
  String get redirectingToWebsite {
    return Intl.message(
      '跳转到公司官网...',
      name: 'redirectingToWebsite',
      desc: '',
      args: [],
    );
  }

  /// `点击识别二维码，查看公司官网信息`
  String get clickToRecognizeQRCode {
    return Intl.message(
      '点击识别二维码，查看公司官网信息',
      name: 'clickToRecognizeQRCode',
      desc: '',
      args: [],
    );
  }

  /// `服务邮箱：Medbotpresident@microport.com`
  String get serviceEmail {
    return Intl.message(
      '服务邮箱：Medbotpresident@microport.com',
      name: 'serviceEmail',
      desc: '',
      args: [],
    );
  }

  /// `无法正常跳转`
  String get cannotRedirect {
    return Intl.message('无法正常跳转', name: 'cannotRedirect', desc: '', args: []);
  }

  /// `无法打开网页`
  String get cannotOpenWebpage {
    return Intl.message(
      '无法打开网页',
      name: 'cannotOpenWebpage',
      desc: '',
      args: [],
    );
  }

  /// `密码修改成功`
  String get passwordChangeSuccess {
    return Intl.message(
      '密码修改成功',
      name: 'passwordChangeSuccess',
      desc: '',
      args: [],
    );
  }

  /// `修改失败`
  String get changeFailed {
    return Intl.message('修改失败', name: 'changeFailed', desc: '', args: []);
  }

  /// `请填写以下信息`
  String get pleaseFillInfo {
    return Intl.message('请填写以下信息', name: 'pleaseFillInfo', desc: '', args: []);
  }

  /// `原密码`
  String get oldPassword {
    return Intl.message('原密码', name: 'oldPassword', desc: '', args: []);
  }

  /// `请输入原密码`
  String get pleaseEnterOldPassword {
    return Intl.message(
      '请输入原密码',
      name: 'pleaseEnterOldPassword',
      desc: '',
      args: [],
    );
  }

  /// `新密码`
  String get newPassword {
    return Intl.message('新密码', name: 'newPassword', desc: '', args: []);
  }

  /// `请输入新密码`
  String get pleaseEnterNewPassword {
    return Intl.message(
      '请输入新密码',
      name: 'pleaseEnterNewPassword',
      desc: '',
      args: [],
    );
  }

  /// `密码至少6位`
  String get passwordAtLeast6 {
    return Intl.message('密码至少6位', name: 'passwordAtLeast6', desc: '', args: []);
  }

  /// `确认新密码`
  String get confirmNewPassword {
    return Intl.message(
      '确认新密码',
      name: 'confirmNewPassword',
      desc: '',
      args: [],
    );
  }

  /// `两次密码不一致`
  String get passwordsNotMatch {
    return Intl.message(
      '两次密码不一致',
      name: 'passwordsNotMatch',
      desc: '',
      args: [],
    );
  }

  /// `提交中...`
  String get submitting {
    return Intl.message('提交中...', name: 'submitting', desc: '', args: []);
  }

  /// `提交修改`
  String get submitChange {
    return Intl.message('提交修改', name: 'submitChange', desc: '', args: []);
  }

  /// `请输入有效的邮箱`
  String get pleaseEnterValidEmail {
    return Intl.message(
      '请输入有效的邮箱',
      name: 'pleaseEnterValidEmail',
      desc: '',
      args: [],
    );
  }

  /// `验证码已发送到`
  String get codeSentTo {
    return Intl.message('验证码已发送到', name: 'codeSentTo', desc: '', args: []);
  }

  /// `验证码发送失败`
  String get codeSendFailed {
    return Intl.message('验证码发送失败', name: 'codeSendFailed', desc: '', args: []);
  }

  /// `确认注销`
  String get confirmDestroy {
    return Intl.message('确认注销', name: 'confirmDestroy', desc: '', args: []);
  }

  /// `确定要注销账号吗？此操作将永久删除您的数据。`
  String get confirmDestroyMessage {
    return Intl.message(
      '确定要注销账号吗？此操作将永久删除您的数据。',
      name: 'confirmDestroyMessage',
      desc: '',
      args: [],
    );
  }

  /// `账号注销成功`
  String get accountDestroyedSuccess {
    return Intl.message(
      '账号注销成功',
      name: 'accountDestroyedSuccess',
      desc: '',
      args: [],
    );
  }

  /// `注销失败`
  String get destroyFailed {
    return Intl.message('注销失败', name: 'destroyFailed', desc: '', args: []);
  }

  /// `注销账号将永久删除您的所有数据，此操作不可恢复。请确认您的账号信息，并验证身份后继续。`
  String get destroyAccountWarning {
    return Intl.message(
      '注销账号将永久删除您的所有数据，此操作不可恢复。请确认您的账号信息，并验证身份后继续。',
      name: 'destroyAccountWarning',
      desc: '',
      args: [],
    );
  }

  /// `请输入邮箱`
  String get pleaseEnterEmail {
    return Intl.message('请输入邮箱', name: 'pleaseEnterEmail', desc: '', args: []);
  }

  /// `验证码`
  String get verificationCode {
    return Intl.message('验证码', name: 'verificationCode', desc: '', args: []);
  }

  /// `请输入验证码`
  String get pleaseEnterCode {
    return Intl.message('请输入验证码', name: 'pleaseEnterCode', desc: '', args: []);
  }

  /// `发送验证码`
  String get sendCode {
    return Intl.message('发送验证码', name: 'sendCode', desc: '', args: []);
  }

  /// `验证码已发送`
  String get codeSentSuccess {
    return Intl.message('验证码已发送', name: 'codeSentSuccess', desc: '', args: []);
  }

  /// `发送失败`
  String get sendFailed {
    return Intl.message('发送失败', name: 'sendFailed', desc: '', args: []);
  }

  /// `网络异常，发送失败`
  String get networkErrorSendFailed {
    return Intl.message(
      '网络异常，发送失败',
      name: 'networkErrorSendFailed',
      desc: '',
      args: [],
    );
  }

  /// `注册成功`
  String get registerSuccess {
    return Intl.message('注册成功', name: 'registerSuccess', desc: '', args: []);
  }

  /// `注册失败`
  String get registerFailed {
    return Intl.message('注册失败', name: 'registerFailed', desc: '', args: []);
  }

  /// `注册请求失败，请检查网络或稍后重试`
  String get registerRequestFailed {
    return Intl.message(
      '注册请求失败，请检查网络或稍后重试',
      name: 'registerRequestFailed',
      desc: '',
      args: [],
    );
  }

  /// `请输入`
  String get pleaseEnter {
    return Intl.message('请输入', name: 'pleaseEnter', desc: '', args: []);
  }

  /// `请选择一个选项`
  String get pleaseSelectAnOption {
    return Intl.message(
      '请选择一个选项',
      name: 'pleaseSelectAnOption',
      desc: '',
      args: [],
    );
  }

  /// `请选择国家`
  String get pleaseSelectCountry {
    return Intl.message(
      '请选择国家',
      name: 'pleaseSelectCountry',
      desc: '',
      args: [],
    );
  }

  /// `获取验证码`
  String get getCode {
    return Intl.message('获取验证码', name: 'getCode', desc: '', args: []);
  }

  /// `秒`
  String get seconds {
    return Intl.message('秒', name: 'seconds', desc: '', args: []);
  }

  /// `请输入注册邮箱`
  String get pleaseEnterRegisteredEmail {
    return Intl.message(
      '请输入注册邮箱',
      name: 'pleaseEnterRegisteredEmail',
      desc: '',
      args: [],
    );
  }

  /// `邮箱不能为空`
  String get emailCannotBeEmpty {
    return Intl.message(
      '邮箱不能为空',
      name: 'emailCannotBeEmpty',
      desc: '',
      args: [],
    );
  }

  /// `请稍后`
  String get pleaseWait {
    return Intl.message('请稍后', name: 'pleaseWait', desc: '', args: []);
  }

  /// `获取验证码并下一步`
  String get getCodeAndNext {
    return Intl.message(
      '获取验证码并下一步',
      name: 'getCodeAndNext',
      desc: '',
      args: [],
    );
  }

  /// `异常`
  String get statusException {
    return Intl.message('异常', name: 'statusException', desc: '', args: []);
  }

  /// `更新成功！`
  String get updateSuccess {
    return Intl.message('更新成功！', name: 'updateSuccess', desc: '', args: []);
  }

  /// `更新失败`
  String get updateFailed {
    return Intl.message('更新失败', name: 'updateFailed', desc: '', args: []);
  }

  /// `编辑用户`
  String get editUser {
    return Intl.message('编辑用户', name: 'editUser', desc: '', args: []);
  }

  /// `机构选择`
  String get institutionSelection {
    return Intl.message(
      '机构选择',
      name: 'institutionSelection',
      desc: '',
      args: [],
    );
  }

  /// `医院`
  String get hospital {
    return Intl.message('医院', name: 'hospital', desc: '', args: []);
  }

  /// `现有代理商`
  String get existingAgent {
    return Intl.message('现有代理商', name: 'existingAgent', desc: '', args: []);
  }

  /// `潜在合作伙伴`
  String get potentialPartner {
    return Intl.message('潜在合作伙伴', name: 'potentialPartner', desc: '', args: []);
  }

  /// `请选择一个机构类型`
  String get pleaseSelectInstitutionType {
    return Intl.message(
      '请选择一个机构类型',
      name: 'pleaseSelectInstitutionType',
      desc: '',
      args: [],
    );
  }

  /// `身份角色`
  String get identityRole {
    return Intl.message('身份角色', name: 'identityRole', desc: '', args: []);
  }

  /// `角色选择`
  String get roleSelection {
    return Intl.message('角色选择', name: 'roleSelection', desc: '', args: []);
  }

  /// `医生`
  String get doctor {
    return Intl.message('医生', name: 'doctor', desc: '', args: []);
  }

  /// `护士`
  String get nurse {
    return Intl.message('护士', name: 'nurse', desc: '', args: []);
  }

  /// `医院技术工程师`
  String get hospitalTechEngineer {
    return Intl.message(
      '医院技术工程师',
      name: 'hospitalTechEngineer',
      desc: '',
      args: [],
    );
  }

  /// `厂家技术工程师`
  String get manufacturerTechEngineer {
    return Intl.message(
      '厂家技术工程师',
      name: 'manufacturerTechEngineer',
      desc: '',
      args: [],
    );
  }

  /// `厂家临床专家`
  String get manufacturerClinicalExpert {
    return Intl.message(
      '厂家临床专家',
      name: 'manufacturerClinicalExpert',
      desc: '',
      args: [],
    );
  }

  /// `请选择一个角色类型`
  String get pleaseSelectRoleType {
    return Intl.message(
      '请选择一个角色类型',
      name: 'pleaseSelectRoleType',
      desc: '',
      args: [],
    );
  }

  /// `请输入具体角色`
  String get pleaseEnterSpecificRole {
    return Intl.message(
      '请输入具体角色',
      name: 'pleaseEnterSpecificRole',
      desc: '',
      args: [],
    );
  }

  /// `选择国家`
  String get selectCountry {
    return Intl.message('选择国家', name: 'selectCountry', desc: '', args: []);
  }

  /// `获取失败`
  String get getFailed {
    return Intl.message('获取失败', name: 'getFailed', desc: '', args: []);
  }

  /// `系统已收到您的问题，会在24小时内联系沟通解决.`
  String get systemFeedbackMessage {
    return Intl.message(
      '系统已收到您的问题，会在24小时内联系沟通解决.',
      name: 'systemFeedbackMessage',
      desc: '',
      args: [],
    );
  }

  /// `无法加载反馈详情`
  String get cannotLoadFeedbackDetail {
    return Intl.message(
      '无法加载反馈详情',
      name: 'cannotLoadFeedbackDetail',
      desc: '',
      args: [],
    );
  }

  /// `系统反馈`
  String get systemFeedback {
    return Intl.message('系统反馈', name: 'systemFeedback', desc: '', args: []);
  }

  /// `暂无反馈`
  String get noFeedback {
    return Intl.message('暂无反馈', name: 'noFeedback', desc: '', args: []);
  }

  /// `反馈时间`
  String get feedbackTime {
    return Intl.message('反馈时间', name: 'feedbackTime', desc: '', args: []);
  }

  /// `评论成功`
  String get commentSuccess {
    return Intl.message('评论成功', name: 'commentSuccess', desc: '', args: []);
  }

  /// `点击上传图片或视频`
  String get clickToUploadImageOrVideo {
    return Intl.message(
      '点击上传图片或视频',
      name: 'clickToUploadImageOrVideo',
      desc: '',
      args: [],
    );
  }

  /// `附件信息异常`
  String get attachmentInfoException {
    return Intl.message(
      '附件信息异常',
      name: 'attachmentInfoException',
      desc: '',
      args: [],
    );
  }

  /// `删除成功`
  String get deleteSuccess {
    return Intl.message('删除成功', name: 'deleteSuccess', desc: '', args: []);
  }

  /// `删除失败`
  String get deleteFailed {
    return Intl.message('删除失败', name: 'deleteFailed', desc: '', args: []);
  }

  /// `邮箱验证码`
  String get emailVerificationCode {
    return Intl.message(
      '邮箱验证码',
      name: 'emailVerificationCode',
      desc: '',
      args: [],
    );
  }

  /// `联系方式`
  String get contactInfo {
    return Intl.message('联系方式', name: 'contactInfo', desc: '', args: []);
  }

  /// `评分：`
  String get rating {
    return Intl.message('评分：', name: 'rating', desc: '', args: []);
  }

  /// `请先选择评分`
  String get pleaseSelectRating {
    return Intl.message(
      '请先选择评分',
      name: 'pleaseSelectRating',
      desc: '',
      args: [],
    );
  }

  /// `暂无建议`
  String get noSuggestion {
    return Intl.message('暂无建议', name: 'noSuggestion', desc: '', args: []);
  }

  /// `请填写建议（可选）`
  String get pleaseFillSuggestion {
    return Intl.message(
      '请填写建议（可选）',
      name: 'pleaseFillSuggestion',
      desc: '',
      args: [],
    );
  }

  /// `正在压缩视频...`
  String get videoCompressing {
    return Intl.message(
      '正在压缩视频...',
      name: 'videoCompressing',
      desc: '',
      args: [],
    );
  }

  /// `视频压缩完成`
  String get videoCompressed {
    return Intl.message('视频压缩完成', name: 'videoCompressed', desc: '', args: []);
  }

  /// `压缩失败`
  String get compressionFailed {
    return Intl.message('压缩失败', name: 'compressionFailed', desc: '', args: []);
  }

  /// `视频压缩失败，是否使用原始文件？`
  String get compressionFailedMessage {
    return Intl.message(
      '视频压缩失败，是否使用原始文件？',
      name: 'compressionFailedMessage',
      desc: '',
      args: [],
    );
  }

  /// `使用原文件`
  String get useOriginal {
    return Intl.message('使用原文件', name: 'useOriginal', desc: '', args: []);
  }

  /// `正在上传`
  String get uploading {
    return Intl.message('正在上传', name: 'uploading', desc: '', args: []);
  }

  /// `正在上传 {count} 个文件`
  String uploadingFiles(int count) {
    return Intl.message(
      '正在上传 $count 个文件',
      name: 'uploadingFiles',
      desc: '',
      args: [count],
    );
  }

  /// `需要录音权限才能使用语音功能`
  String get microphonePermissionRequired {
    return Intl.message(
      '需要录音权限才能使用语音功能',
      name: 'microphonePermissionRequired',
      desc: '',
      args: [],
    );
  }

  /// `录音启动失败`
  String get recordingStartFailed {
    return Intl.message(
      '录音启动失败',
      name: 'recordingStartFailed',
      desc: '',
      args: [],
    );
  }

  /// `音频文件不存在`
  String get audioFileNotFound {
    return Intl.message(
      '音频文件不存在',
      name: 'audioFileNotFound',
      desc: '',
      args: [],
    );
  }

  /// `播放失败`
  String get playbackFailed {
    return Intl.message('播放失败', name: 'playbackFailed', desc: '', args: []);
  }

  /// `识别二维码查看公司信息`
  String get checkCode {
    return Intl.message('识别二维码查看公司信息', name: 'checkCode', desc: '', args: []);
  }

  /// `CEO直通Medbot Linkedin`
  String get checkLinkCode {
    return Intl.message(
      'CEO直通Medbot Linkedin',
      name: 'checkLinkCode',
      desc: '',
      args: [],
    );
  }

  /// `版本信息`
  String get versionInfo {
    return Intl.message('版本信息', name: 'versionInfo', desc: '', args: []);
  }

  /// `当前版本`
  String get currentVersion {
    return Intl.message('当前版本', name: 'currentVersion', desc: '', args: []);
  }

  /// `语音反馈`
  String get voiceInputTitle {
    return Intl.message('语音反馈', name: 'voiceInputTitle', desc: '', args: []);
  }

  /// `说出您遇到的问题,我们会帮您整理成反馈`
  String get voiceInputSubtitle {
    return Intl.message(
      '说出您遇到的问题,我们会帮您整理成反馈',
      name: 'voiceInputSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `这只是初步识别,后续会通过 AI 更精准分析`
  String get voicePreliminaryHint {
    return Intl.message(
      '这只是初步识别,后续会通过 AI 更精准分析',
      name: 'voicePreliminaryHint',
      desc: '',
      args: [],
    );
  }

  /// `点击或长按说话`
  String get tapOrHoldToSpeak {
    return Intl.message(
      '点击或长按说话',
      name: 'tapOrHoldToSpeak',
      desc: '',
      args: [],
    );
  }

  /// `长按说话,松手自动结束`
  String get holdToSpeakReleaseToFinish {
    return Intl.message(
      '长按说话,松手自动结束',
      name: 'holdToSpeakReleaseToFinish',
      desc: '',
      args: [],
    );
  }

  /// `点击开始,再次点击结束`
  String get tapToStartTapToStop {
    return Intl.message(
      '点击开始,再次点击结束',
      name: 'tapToStartTapToStop',
      desc: '',
      args: [],
    );
  }

  /// `正在聆听…`
  String get listening {
    return Intl.message('正在聆听…', name: 'listening', desc: '', args: []);
  }

  /// `AI 分析中…`
  String get analyzing {
    return Intl.message('AI 分析中…', name: 'analyzing', desc: '', args: []);
  }

  /// `继续补充`
  String get continueSupplement {
    return Intl.message('继续补充', name: 'continueSupplement', desc: '', args: []);
  }

  /// `没有识别到内容,请重试`
  String get voiceEmptyHint {
    return Intl.message(
      '没有识别到内容,请重试',
      name: 'voiceEmptyHint',
      desc: '',
      args: [],
    );
  }

  /// `AI 分析失败,已按原文填入`
  String get analyzeFailedFallback {
    return Intl.message(
      'AI 分析失败,已按原文填入',
      name: 'analyzeFailedFallback',
      desc: '',
      args: [],
    );
  }

  /// `识别内容`
  String get transcriptLabel {
    return Intl.message('识别内容', name: 'transcriptLabel', desc: '', args: []);
  }

  /// `重录`
  String get reRecord {
    return Intl.message('重录', name: 'reRecord', desc: '', args: []);
  }

  /// `跳过,直接文字输入`
  String get skipToTextInput {
    return Intl.message(
      '跳过,直接文字输入',
      name: 'skipToTextInput',
      desc: '',
      args: [],
    );
  }

  /// `{seconds} 秒后将自动停止`
  String autoStopCountdown(Object seconds) {
    return Intl.message(
      '$seconds 秒后将自动停止',
      name: 'autoStopCountdown',
      desc: '',
      args: [seconds],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'zh'),
      Locale.fromSubtags(languageCode: 'en'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
