import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/emergency_contacts_provider.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar_utils.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  bool _isModalVisible = false;
  bool _isDeleteModalVisible = false;
  bool _isEditing = false;
  String _errorMessage = '';
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /* ----------  业务方法 ---------- */

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );
      if (pickedFile != null && mounted) {
          final provider = context.read<EmergencyContactsProvider>();
          await provider.saveAvatar(pickedFile.path);
          SnackBarUtils.showSnackBar('头像已更新', context);
        }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar('选择图片失败: $e', context);
      }
    }
  }

  void _openContactModal({String? name, String? phone}) {
    _nameController.text = name ?? '';
    _phoneController.text = phone ?? '';
    _isEditing = name != null;
    setState(() {
      _isModalVisible = true;
      _errorMessage = '';
    });
  }

  void _closeModal() {
    setState(() {
      _isModalVisible = false;
      _isDeleteModalVisible = false;
    });
  }

  void _handleSaveContact() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      setState(() => _errorMessage = '请填写完整信息');
      return;
    }
    if (phone.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      setState(() => _errorMessage = '请输入有效的11位手机号码');
      return;
    }
    setState(() => _errorMessage = '');
    context.read<EmergencyContactsProvider>().saveContact(name, phone);
    _closeModal();
  }

  /* ----------  UI ---------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildPageContent(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width),
          if (_isModalVisible) _buildContactModal(),
          if (_isDeleteModalVisible) _buildDeleteConfirmModal(),
        ],
      ),
    );
  }

  Widget _buildPageContent(double screenHeight, double screenWidth) {
    // 使用固定像素值，保持界面一致性
    const topBarTopPadding = 20.0;
    const topBarBottomPadding = 26.0;
    const topBarHorizontalPadding = 20.0;
    const securityTipPadding = 16.0;
    const securityTipIconSize = 32.0;
    const mainCardPadding = 24.0;
    const buttonHeight = 48.0;
    const buttonVerticalPadding = 12.0;

    return Consumer<EmergencyContactsProvider>(
      builder: (_, provider, __) {
        final has = provider.hasContact;
        return Column(
          children: [
            /* 顶部栏 */
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16.0, 48.0, 16.0, 16.0), // 调整顶部内边距，适配刘海屏
              decoration: const BoxDecoration(color: Color(0xFF1E88E5)),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Image.asset('assets/images/return.png',
                        width: 20.0,
                        height: 20.0,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.arrow_back,
                                color: Colors.white, size: 20)),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 12.0),
                  const Text('紧急联系人',
                      style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            /* 安全提示 */
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              padding: EdgeInsets.all(securityTipPadding),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF9DB), Color(0xFFFFF3BF)]),
                borderRadius: BorderRadius.circular(16),
                border: const Border(
                    left: BorderSide(color: Color(0xFFFBBF24), width: 5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/images/exclamation_point(2).png',
                          width: securityTipIconSize,
                          height: securityTipIconSize,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.warning,
                                  size: securityTipIconSize,
                                  color: Color(0xFFFBBF24))),
                      const SizedBox(width: 16.0),
                      const Text('安全提示',
                          style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E))),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  const Text(
                      '在设置紧急联系人后，您可以一键拨打电话',
                      style: TextStyle(
                          fontSize: 14.0,
                          color: Color(0xFF92400E),
                          height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            /* 主卡片区域 - 滚动 */
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0),
                  padding: EdgeInsets.all(mainCardPadding),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: has
                      ? _buildContactCard(provider)
                      : _buildEmptyState(),
                ),
              ),
            ),

            /* 底部按钮 */
            if (!has)
              Container(
                padding: EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                    top: 16.0,
                    bottom: 16.0 + MediaQuery.of(context).padding.bottom),
                child: ElevatedButton.icon(
                  onPressed: () => _openContactModal(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      padding: EdgeInsets.symmetric(vertical: buttonVerticalPadding),
                      minimumSize: Size(double.infinity, buttonHeight),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  icon: Image.asset('assets/images/add.png',
                      width: 20.0,
                      height: 20.0,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.add, color: Colors.white)),
                  label: const Text('添加联系人',
                      style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildContactCard(EmergencyContactsProvider p) {
    final contact = p.contact!;
    final avatarPath = contact['avatarPath'];

    // 使用固定像素值
    const avatarSize = 96.0;
    const statusTagHorizontalPadding = 20.0;
    const statusTagVerticalPadding = 6.0;
    const statusTagFontSize = 14.0;
    const nameFontSize = 24.0;
    const phoneFontSize = 20.0;
    const buttonVerticalPadding = 12.0;
    const buttonFontSize = 16.0;

    // 间距的固定值
    const spacingXL = 32.0;
    const spacingL = 24.0;
    const spacingM = 12.0;
    const spacingS = 8.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /* 状态标签 - 百分比适配 */
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: statusTagHorizontalPadding,
              vertical: statusTagVerticalPadding),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/images/shield(emergency).png',
                width: 16.0,
                height: 16.0,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.shield_outlined,
                        size: 16.0,
                        color: Color(0xFF1E293B))),
            const SizedBox(width: 6.0),
            Text('安全已启用',
                style: TextStyle(
                    fontSize: statusTagFontSize,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)))
          ]),
        ),
        SizedBox(height: spacingXL),

        /* 头像居中 + 信息 - 百分比适配 */
        Column(
          children: [
            /* 头像居中 - 百分比尺寸 */
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFD0EBFF), Color(0xFFA5D8FF)]),
                    borderRadius: BorderRadius.circular(avatarSize / 2),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF2563EF).withAlpha(38),
                          blurRadius: 10,
                          offset: const Offset(0, 5))
                    ],
                  ),
                  child: avatarPath != null && avatarPath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(avatarSize / 2),
                          child: Image.file(File(avatarPath),
                              width: avatarSize,
                              height: avatarSize,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _defaultAvatar()),
                        )
                      : _defaultAvatar(),
                ),
              ),
            ),
            SizedBox(height: spacingL),
            /* 姓名 - 百分比字体 */
            Center(
              child: Text(contact['name'] ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: nameFontSize,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
            ),
            SizedBox(height: spacingM),
            /* 电话号码 - 百分比字体 */
            Center(
              child: Text(p.formatPhone(contact['phone'] ?? ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: phoneFontSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B).withAlpha(178))),
            ),
          ],
        ),
        SizedBox(height: spacingXL),

        /* 操作按钮 - 百分比适配 */
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                    borderRadius: BorderRadius.circular(10)),
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isDeleteModalVisible = true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: buttonVerticalPadding),
                      minimumSize: Size(120, 0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0),
                  icon: Image.asset('assets/images/del.png',
                width: 18.0,
                height: 18.0,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.delete,
                        size: 18.0,
                        color: Colors.white)),
                  label: Text('删除',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: buttonFontSize)),
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E88E5), Color(0xFF1A75D4)]),
                    borderRadius: BorderRadius.circular(10)),
                child: ElevatedButton.icon(
                  onPressed: () => _openContactModal(
                      name: contact['name'], phone: contact['phone']),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: buttonVerticalPadding),
                      minimumSize: const Size(120, 0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0),
                  icon: Image.asset('assets/images/change.png',
                      width: 18.0,
                      height: 18.0,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.edit,
                              size: 18.0,
                              color: Colors.white)),
                  label: Text('更改',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: buttonFontSize)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _defaultAvatar() {
    const iconSize = 64.0;
    return Transform.scale(
      scale: 0.6,
      child: Image.asset('assets/images/btx.png',
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.person, size: iconSize, color: Color(0xFF2563EF))),
    );
  }

  Widget _buildEmptyState() {
    // 空状态的固定尺寸
    const avatarSize = 80.0;
    const titleFontSize = 20.0;
    const descFontSize = 14.0;

    // 空状态的间距
    const spacingL = 20.0;
    const spacingM = 16.0;
    const spacingS = 12.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFD0EBFF), Color(0xFFA5D8FF)]),
                borderRadius: BorderRadius.circular(avatarSize / 2)),
            child: Center(
              child: Image.asset('assets/images/profile.png',
                  width: avatarSize * 0.5,
                  height: avatarSize * 0.5,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person,
                          size: avatarSize * 0.5,
                          color: Color(0xFF2563EF))),
            ),
          ),
          SizedBox(height: spacingL),
          const Text('尚未设置紧急联系人',
              style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          SizedBox(height: spacingM),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
                '添加紧急联系人后，当您处于危险情况时，支持一键拨打电话',
                style: TextStyle(fontSize: descFontSize, color: Color(0xFF1E293B)),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildContactModal() {
    // 弹窗相关的固定常量
    const modalMargin = 20.0;
    const modalPadding = 20.0;
    const modalBorderRadius = 16.0;
    const titleFontSize = 18.0;
    const closeIconSize = 20.0;

    // 间距固定值
    const spacingXL = 20.0;
    const spacingL = 16.0;
    const spacingM = 12.0;
    const spacingS = 8.0;

    // 错误提示相关
    const errorMsgHorizontalPadding = 12.0;
    const errorMsgVerticalPadding = 8.0;
    const errorMsgBorderRadius = 8.0;
    const errorIconSize = 16.0;
    const errorTextFontSize = 14.0;

    // 输入框相关
    const inputBorderWidth = 1.0;
    const prefixIconSize = 20.0;
    const inputLabelFontSize = 16.0;

    // 按钮相关
    const buttonVerticalPadding = 12.0;
    const buttonBorderRadius = 12.0;
    const buttonFontSize = 16.0;

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: EdgeInsets.all(modalMargin),
          padding: EdgeInsets.all(modalPadding),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(modalBorderRadius)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_isEditing ? '更改紧急联系人' : '添加紧急联系人',
                    style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                IconButton(
                    onPressed: _closeModal,
                    icon: Icon(Icons.close,
                        color: AppTheme.textSecondary,
                        size: closeIconSize)),
              ],
            ),
            SizedBox(height: spacingXL),
            if (_errorMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: errorMsgHorizontalPadding,
                    vertical: errorMsgVerticalPadding),
                margin: EdgeInsets.only(bottom: spacingM),
                decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(errorMsgBorderRadius),
                    border: Border.all(
                        color: const Color(0xFFFCA5A5),
                        width: inputBorderWidth)),
                child: Row(children: [
                  Icon(Icons.error_outline,
                      size: errorIconSize,
                      color: Color(0xFFDC2626)),
                  SizedBox(width: spacingS),
                  Expanded(
                      child: Text(_errorMessage,
                          style: TextStyle(
                              fontSize: errorTextFontSize,
                              color: Color(0xFFDC2626))))
                ]),
              ),
            // 姓名输入
            TextField(
                controller: _nameController,
                decoration: InputDecoration(
                    labelText: '联系人姓名',
                    labelStyle: TextStyle(
                        color: Colors.black,
                        fontSize: inputLabelFontSize),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(width: inputBorderWidth)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color(0xFF1E88E5),
                            width: inputBorderWidth * 2)),
                    prefixIcon: Transform.scale(
                      scale: 0.6,
                      child: Image.asset('assets/images/emergency_human.png',
                          width: prefixIconSize,
                          height: prefixIconSize,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.person, size: prefixIconSize)),
                    ))),
            SizedBox(height: spacingM),
            // 手机号输入
            TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: InputDecoration(
                    labelText: '手机号码',
                    labelStyle: TextStyle(
                        color: Colors.black,
                        fontSize: inputLabelFontSize),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(width: inputBorderWidth)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color(0xFF1E88E5),
                            width: inputBorderWidth * 2)),
                    prefixIcon: Transform.scale(
                      scale: 0.6,
                      child: Image.asset('assets/images/tel.png',
                          width: prefixIconSize,
                          height: prefixIconSize,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.phone, size: prefixIconSize)),
                    ),
                    counterText: '')),
            SizedBox(height: spacingXL),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                    onPressed: _closeModal,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: AppTheme.textSecondary,
                        padding: EdgeInsets.symmetric(
                            vertical: buttonVerticalPadding),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(buttonBorderRadius))),
                    child: Text('取消',
                        style: TextStyle(fontSize: buttonFontSize))),
              ),
              SizedBox(width: spacingM),
              Expanded(
                child: ElevatedButton(
                    onPressed: _handleSaveContact,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        padding: EdgeInsets.symmetric(
                            vertical: buttonVerticalPadding),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(buttonBorderRadius))),
                    child: Text('保存',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: buttonFontSize))),
              ),
            ])
          ]),
        ),
      ),
    );
  }

  Widget _buildDeleteConfirmModal() {
    // 删除弹窗相关的固定常量
    const modalMarginHorizontal = 20.0;
    const modalPadding = 20.0;
    const modalBorderRadius = 16.0;

    // 图标容器相关
    const iconContainerSize = 60.0;
    const iconContainerBorderRadius = iconContainerSize / 2;
    const iconSize = iconContainerSize * 0.8;
    const iconMarginBottom = 20.0;

    // 文字相关
    const titleFontSize = 18.0;
    const descFontSize = 14.0;
    const buttonFontSize = 16.0;

    // 间距相关
    const spacingL = 10.0;
    const spacingXL = 32.0;
    const spacingM = 16.0;

    // 按钮相关
    const buttonBorderRadius = 8.0;
    const buttonBorderWidth = 1.0;

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: modalMarginHorizontal),
          padding: EdgeInsets.all(modalPadding),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(modalBorderRadius)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              margin: EdgeInsets.only(bottom: iconMarginBottom),
              decoration: BoxDecoration(
                  color: AppTheme.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(iconContainerBorderRadius)),
              child: Transform.scale(
                scale: 0.6,
                child: Image.asset('assets/images/删除项目.png',
                    width: iconSize,
                    height: iconSize,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.warning_amber_outlined,
                            size: iconSize,
                            color: AppTheme.error)),
              ),
            ),
            const Text('删除紧急联系人？',
                style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            SizedBox(height: spacingL),
            const Text(
                '删除后，当您处于危险情况时，系统将无法通知此联系人。确定要删除吗？',
                style: TextStyle(
                    fontSize: descFontSize,
                    color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
            SizedBox(height: spacingXL),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                    onPressed: _closeModal,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F5F5),
                        foregroundColor: const Color(0xFF666666),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(buttonBorderRadius),
                            side: BorderSide(
                                color: Color(0xFFE0E0E0),
                                width: buttonBorderWidth))),
                    child: const Text('取消',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: buttonFontSize))),
              ),
              SizedBox(width: spacingM),
              Expanded(
                child: ElevatedButton(
                    onPressed: () {
                      context.read<EmergencyContactsProvider>().deleteContact();
                      _closeModal();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(buttonBorderRadius))),
                    child: const Text('确认删除',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: buttonFontSize,
                            color: Colors.white))),
              ),
            ])
          ]),
        ),
      ),
    );
  }
}