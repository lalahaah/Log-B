import 'package:flutter/material.dart';
import '../models/partner.dart';
import '../main.dart';

/// 파트너 추가/수정 다이얼로그
class AddPartnerDialog extends StatefulWidget {
  final Partner? partner; // null이면 새로 추가, 있으면 수정

  const AddPartnerDialog({super.key, this.partner});

  @override
  State<AddPartnerDialog> createState() => _AddPartnerDialogState();
}

class _AddPartnerDialogState extends State<AddPartnerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.partner != null) {
      _nameController.text = widget.partner!.name;
      _companyController.text = widget.partner!.company;
      _positionController.text = widget.partner!.position;
      _emailController.text = widget.partner!.email;
      _phoneController.text = widget.partner!.phone;
      _tags.addAll(widget.partner!.tags);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final partner = Partner(
        id: widget.partner?.id ?? '',
        name: _nameController.text.trim(),
        company: _companyController.text.trim(),
        position: _positionController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        tags: _tags,
        createdAt: widget.partner?.createdAt ?? DateTime.now(),
        updatedAt: widget.partner != null ? DateTime.now() : null,
      );
      Navigator.of(context).pop(partner);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? LogBTheme.slate900 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.partner == null ? '새 파트너 추가' : '파트너 수정',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : LogBTheme.slate900,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white54 : LogBTheme.slate500,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 스크롤 가능한 입력 필드
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 이름
                      _buildTextField(
                        controller: _nameController,
                        label: '이름',
                        icon: Icons.person,
                        validator: (value) =>
                            value?.isEmpty ?? true ? '이름을 입력하세요' : null,
                      ),
                      const SizedBox(height: 16),

                      // 회사
                      _buildTextField(
                        controller: _companyController,
                        label: '회사',
                        icon: Icons.business,
                        validator: (value) =>
                            value?.isEmpty ?? true ? '회사명을 입력하세요' : null,
                      ),
                      const SizedBox(height: 16),

                      // 직책
                      _buildTextField(
                        controller: _positionController,
                        label: '직책',
                        icon: Icons.work,
                      ),
                      const SizedBox(height: 16),

                      // 이메일
                      _buildTextField(
                        controller: _emailController,
                        label: '이메일',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // 전화번호
                      _buildTextField(
                        controller: _phoneController,
                        label: '전화번호',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),

                      // 태그 입력
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _tagController,
                              label: '태그 추가',
                              icon: Icons.label,
                              onSubmitted: (_) => _addTag(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addTag,
                            icon: const Icon(
                              Icons.add_circle,
                              color: LogBTheme.emerald600,
                            ),
                          ),
                        ],
                      ),

                      // 태그 목록
                      if (_tags.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tags
                              .map(
                                (tag) => Chip(
                                  label: Text(
                                    tag,
                                    style: const TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: LogBTheme.emerald600,
                                    ),
                                  ),
                                  deleteIcon: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: LogBTheme.emerald600,
                                  ),
                                  onDeleted: () => _removeTag(tag),
                                  backgroundColor: LogBTheme.emerald50,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : LogBTheme.slate500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LogBTheme.emerald600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      widget.partner == null ? '추가' : '수정',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: LogBTheme.emerald600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LogBTheme.slate500),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LogBTheme.emerald600, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
      ),
      validator: validator,
      keyboardType: keyboardType,
      onFieldSubmitted: onSubmitted,
    );
  }
}
