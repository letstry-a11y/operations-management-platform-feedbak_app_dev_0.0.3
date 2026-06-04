import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medbot_ai_app/providers/user_provider.dart';
import 'package:medbot_ai_app/utils/http_service.dart';
// import 'package:medbot_ai_app/widgets/dropdown_selector.dart';
import 'package:medbot_ai_app/widgets/loading_button.dart';
import 'package:medbot_ai_app/widgets/toast_utils.dart';
import 'package:medbot_ai_app/generated/l10n.dart';
import 'package:provider/provider.dart';
import 'package:medbot_ai_app/data/constants/user_options.dart';

const _brandColor = Color(0xFF042A72);
const _selectorTextPrimaryColor = Color(0xFF172033);
const _selectorTextSecondaryColor = Color(0xFF697386);

class UserEditPage extends StatefulWidget {
  const UserEditPage({super.key});

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _customRoleController = TextEditingController();

  // Store ids (numeric strings). '0' for other role.
  String? _selectedOrganization;
  String? _selectedRole;
  // Reserved: custom role kept in controller, no separate field needed
  String? _id;
  bool _isLoading = false;

  // List<String> get _roleOptions {
  //   return [
  //     S.of(context).doctor,
  //     S.of(context).nurse,
  //     S.of(context).hospitalTechEngineer,
  //     S.of(context).manufacturerTechEngineer,
  //     S.of(context).manufacturerClinicalExpert,
  //     S.of(context).other,
  //   ];
  // }
  // Options are provided by UserOptions


  @override
  void dispose() {
    _customRoleController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserProvider>(context);
    final userInfo = user.profile ?? {};

    // Try to parse saved organization/role as id; if label stored, map to id
    final identities = UserOptions.identityOptions(context);
    final roles = UserOptions.roleOptions(context);

    final savedOrg = userInfo["organization"]?.toString();
    if (_selectedOrganization == null && savedOrg != null) {
      // if already id
      if (identities.any((e) => e['id'] == savedOrg)) {
        _selectedOrganization = savedOrg;
      } else {
        // map label -> id
        final match = identities.firstWhere(
          (e) => e['label'] == savedOrg,
          orElse: () => {},
        );
        _selectedOrganization = match['id'];
      }
    }

    final savedRole = userInfo["role"]?.toString();
    if (_selectedRole == null && savedRole != null) {
      if (roles.any((e) => e['id'] == savedRole)) {
        _selectedRole = savedRole;
      } else if (roles.any((e) => e['label'] == savedRole)) {
        _selectedRole = roles.firstWhere((e) => e['label'] == savedRole)['id'];
      } else {
        // treat as custom role
        _selectedRole = '0';
        _customRoleController.text = savedRole;
      }
    }

    _id ??= int.tryParse(userInfo["id"]?.toString() ?? '')?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).editUser)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
               Text(
                S.of(context).institutionSelection,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              _UserEditSelectorField(
                selectedValue: _selectedOrganization,
                label: '${S.of(context).institutionSelection} *',
                options: UserOptions.identityOptions(context),
                isIOS: isIOS,
                onChanged: (val) => setState(() => _selectedOrganization = val),
                validatorCallback:
                    (val) =>
                        val == null
                            ? S.of(context).pleaseSelectInstitutionType
                            : null,
              ),

              const SizedBox(height: 16),
               Text(
                S.of(context).identityRole,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _UserEditSelectorField(
                selectedValue: _selectedRole,
                label: '${S.of(context).roleSelection} *',
                options: UserOptions.roleOptions(context),
                isIOS: isIOS,
                onChanged: (val) {
                  setState(() {
                    _selectedRole = val;
                    if (val != '0') {
                      _customRoleController.clear();
                    }
                  });
                },
                validatorCallback: (val) {
                  if (val == null) return S.of(context).pleaseSelectRoleType;
                  if (val == '0' && (_customRoleController.text.isEmpty)) {
                    return S.of(context).pleaseEnterSpecificRole;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              if (_selectedRole == '0')
                TextFormField(
                  controller: _customRoleController,
                  decoration: InputDecoration(
                    labelText: S.of(context).pleaseEnterSpecificRole,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon:
                        _customRoleController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _customRoleController.clear();
                                });
                              },
                            )
                            : null,
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                  validator: (val) {
                    if (_selectedRole == '0' && (val == null || val.isEmpty)) {
                      return S.of(context).pleaseEnterSpecificRole;
                    }
                    return null;
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LoadingButton(
          loading: _isLoading,
          label: S.of(context).submit,
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              final l10n = S.of(context);
              setState(() => _isLoading = true);
              final roleToSubmit = _selectedRole == '0'
                  ? _customRoleController.text
                  : _selectedRole;

              try {
                final response = await HttpService().post(
                  'user/update',
                  body: {
                    'organization': _selectedOrganization,
                    'role': roleToSubmit,
                    'id': _id,
                  },
                );

                if (!context.mounted) return;
                final result = jsonDecode(response.body);
                print('object; $result');
                if (result["status"] == 200) {
                  await ToastUtils.showSuccess(
                    context,
                    l10n.updateSuccess,
                    duration: const Duration(seconds: 1),
                  ).closed;
                  if (!context.mounted) return;
                  final userInfo = userProvider.profile ?? {};
                  userInfo["organization"] = _selectedOrganization;
                  userInfo["role"] = roleToSubmit;
                  userInfo["id"] = _id.toString();
                  userProvider.updateFromMap(userInfo);
                  setState(() => _isLoading = false);
                  Navigator.pop(context);
                } else {
                  ToastUtils.showError(
                    context,
                    result['message'] ?? l10n.updateFailed,
                  );
                  setState(() => _isLoading = false);
                }
              } catch (e) {
                if (!context.mounted) return;
                ToastUtils.handleHttpException(e, context);
                setState(() => _isLoading = false);
              }
            }
          },
        ),
      ),
    );
  }
}

class _UserEditSelectorField extends FormField<String> {
  _UserEditSelectorField({
    required this.label,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
    required this.validatorCallback,
    required this.isIOS,
  }) : super(
         initialValue: selectedValue,
         validator: validatorCallback,
         builder: (state) {
           final borderColor =
               isIOS ? const Color(0xFFE7EBF3) : const Color(0xFFD8DEE9);
           final selected = options.firstWhere(
             (item) => item['id'] == state.value,
             orElse: () => const {},
           );
           final selectedLabel = selected['label'];

           Future<void> showSelector() async {
             final picked = await showModalBottomSheet<String>(
               context: state.context,
               backgroundColor: Colors.transparent,
               isScrollControlled: false,
               builder:
                   (context) => _UserEditSelectorSheet(
                     title: label.replaceAll(' *', ''),
                     options: options,
                     selectedValue: state.value,
                     isIOS: isIOS,
                   ),
             );

             if (picked != null) {
               if (!state.context.mounted) return;
               state.didChange(picked);
               onChanged(picked);
             }
           }

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Material(
                 color: Colors.transparent,
                 child: InkWell(
                   onTap: showSelector,
                   borderRadius: BorderRadius.circular(isIOS ? 18 : 16),
                   child: Ink(
                     padding: const EdgeInsets.symmetric(
                       horizontal: 16,
                       vertical: 16,
                     ),
                     decoration: BoxDecoration(
                       color: isIOS ? const Color(0xFFF7F9FD) : Colors.white,
                       borderRadius: BorderRadius.circular(isIOS ? 18 : 16),
                       border: Border.all(
                         color:
                             state.hasError
                                 ? Theme.of(state.context).colorScheme.error
                                 : borderColor,
                         width: state.hasError ? 1.2 : 1,
                       ),
                     ),
                     child: Row(
                       children: [
                         Icon(
                           isIOS
                               ? CupertinoIcons.square_grid_2x2
                               : Icons.unfold_more_rounded,
                           color: _brandColor,
                           size: 20,
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 label,
                                 style: const TextStyle(
                                   fontSize: 12,
                                   fontWeight: FontWeight.w600,
                                   color: _selectorTextSecondaryColor,
                                 ),
                               ),
                               const SizedBox(height: 4),
                               Text(
                                 selectedLabel?.isNotEmpty == true
                                     ? selectedLabel!
                                     : label.replaceAll(' *', ''),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                                 style: TextStyle(
                                   fontSize: 15,
                                   fontWeight:
                                       selectedLabel?.isNotEmpty == true
                                           ? FontWeight.w600
                                           : FontWeight.w500,
                                   color:
                                       selectedLabel?.isNotEmpty == true
                                           ? _selectorTextPrimaryColor
                                           : _selectorTextSecondaryColor,
                                 ),
                               ),
                             ],
                           ),
                         ),
                         const SizedBox(width: 8),
                         Icon(
                           isIOS
                               ? CupertinoIcons.chevron_up_chevron_down
                               : Icons.keyboard_arrow_down_rounded,
                           color: _selectorTextSecondaryColor,
                           size: 18,
                         ),
                       ],
                     ),
                   ),
                 ),
               ),
               if (state.hasError) ...[
                 const SizedBox(height: 6),
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 12),
                   child: Text(
                     state.errorText ?? '',
                     style: TextStyle(
                       color: Theme.of(state.context).colorScheme.error,
                       fontSize: 12,
                     ),
                   ),
                 ),
               ],
             ],
           );
         },
       );

  final String label;
  final String? selectedValue;
  final List<Map<String, String>> options;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String> validatorCallback;
  final bool isIOS;
}

class _UserEditSelectorSheet extends StatelessWidget {
  const _UserEditSelectorSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.isIOS,
  });

  final String title;
  final List<Map<String, String>> options;
  final String? selectedValue;
  final bool isIOS;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD6DCE7),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _selectorTextPrimaryColor,
              ),
            ),
            const SizedBox(height: 10),
            ...options.map((item) {
              final selected = item['id'] == selectedValue;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(item['id']),
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['label'] ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color:
                                  selected
                                      ? _brandColor
                                      : _selectorTextPrimaryColor,
                            ),
                          ),
                        ),
                        if (selected)
                          Icon(
                            isIOS
                                ? CupertinoIcons.check_mark_circled_solid
                                : Icons.check_circle_rounded,
                            size: 20,
                            color: _brandColor,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
