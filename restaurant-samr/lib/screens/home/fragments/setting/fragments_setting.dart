// lib/screens/home/fragments/setting/fragments_setting.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:splash_screen_03/captain/login/auth_service.dart';
import 'package:splash_screen_03/model/enum_printer_size.dart';
import 'package:splash_screen_03/repository/Base64.dart';
import 'package:splash_screen_03/screens/home/fragments/day/day_report.dart';
import 'package:splash_screen_03/screens/home/fragments/day/shift%20reports/close_day.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/printerquick_connect.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/raw_pritner_service.dart';
import 'package:splash_screen_03/screens/home/fragments/users/controller_user.dart';
import 'package:splash_screen_03/utils/app_routes.dart';
import '../../../../model/entity_printer.dart';
import 'controller_setting.dart';
import 'package:splash_screen_03/model/entity_user.dart';
import 'package:intl/intl.dart';
import 'package:splash_screen_03/model/enity_day_report.dart';

import 'package:splash_screen_03/repository/day_repo.dart';

/// ---------- GlassCard (reusable) ----------
/// Modernized glass card with adaptive blur, border and shadow.
/// You can tweak `blur`, `elevation`, and `gradientOpacity` to change look.
class GlassCard extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Widget child;
  final double blur;
  final double elevation;
  final double gradientOpacity;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.blur = 10.0,
    this.elevation = 8.0,
    this.gradientOpacity = 0.06,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color top = isDark
        ? Colors.white.withOpacity(0.02 + gradientOpacity)
        : Colors.white.withOpacity(0.6);
    final Color bottom = isDark
        ? Colors.white.withOpacity(0.01 + gradientOpacity / 2)
        : Colors.black.withOpacity(0.03);

    final borderColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.06);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [top, bottom],
            ),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.6)
                    : Colors.black.withOpacity(0.06),
                blurRadius: elevation,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// ---------- Main Fragment ----------
class FragmentsSetting extends StatelessWidget {
  const FragmentsSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final dayCtrl = Get.put(DayStatusController(), permanent: true);
    final authService = Get.find<AuthService>();

    final controller = Get.put(ControllerSetting());
    final userController = Get.put(ControllerUser());

    final storage = controller.box;
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Background gradient container for subtle depth
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF07080A), const Color(0xFF0E1113)]
                  : [const Color(0xFFF7F9FB), const Color(0xFFF0F3F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              // Top Tab Bar with glass strip
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.02)
                      : Colors.white.withOpacity(0.6),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withOpacity(0.06),
                    ),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TabBar(
                            labelColor: theme.colorScheme.primary,
                            unselectedLabelColor:
                                theme.colorScheme.onSurfaceVariant,
                            indicator: UnderlineTabIndicator(
                              borderSide: BorderSide(
                                width: 3.0,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            tabs: const [
                              Tab(text: 'Profile'),
                              Tab(text: 'Settings'),
                              Tab(text: 'Printer'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  children: [
                    // ---------------- Profile ----------------
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Obx(() {
                        final EntityUser? currentUser =
                            authService.currentUser.value;

                        if (currentUser == null) {
                          authService.fetchUserProfile();
                        }

                        final storageLocal = StorageRepository();

                        // Fallbacks for API-based login
                        final storedUsername = storageLocal.username.isNotEmpty
                            ? storageLocal.username
                            : 'Guest User';
                        final storedToken = storageLocal.accessToken;

                        final String displayName =
                            (currentUser?.first?.isNotEmpty == true)
                            ? '${currentUser?.first ?? ''} ${currentUser?.last ?? ''}'
                                  .trim()
                            : (currentUser?.userName?.isNotEmpty == true
                                  ? currentUser?.userName ?? 'Guest User'
                                  : storedUsername);

                        final String displayRole =
                            currentUser?.userType ?? 'Online User';
                        final String displayPhone =
                            currentUser?.mobile ?? 'Not set';

                        // Generate initials
                        final initials =
                            (displayName
                                    .split(' ')
                                    .map((s) => s.isNotEmpty ? s[0] : '')
                                    .take(2)
                                    .join())
                                .toUpperCase();

                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 980,
                            ), // wide
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 8),
                                // top info card
                                GlassCard(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 20,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 44,
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.12),
                                            child: Text(
                                              initials,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.copyWith(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  displayName,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  displayRole,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.phone,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      displayPhone,
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodyMedium,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // logout button
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 18,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: () async {
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text(
                                                    'Logout Confirmation',
                                                  ),
                                                  content: const Text(
                                                    'Are you sure you want to log out?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(false),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(true),
                                                      child: const Text(
                                                        'Logout',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirmed == true) {
                                                await authService
                                                    .logout(); // 🔥 CLEAN + API LOGOUT + NAVIGATE
                                              }
                                            },

                                            icon: const Icon(
                                              Icons.logout_rounded,
                                            ),
                                            label: const Text('Logout'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Day card + actions
                                GlassCard(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 18,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // ✅ FIX: Wrap the card call in Obx to listen for changes
                                      Obx(() {
                                        return dayStatusCard(
                                          context,
                                          open: dayCtrl
                                              .openReport
                                              .value, // Pass the observable value
                                        );
                                      }),
                                      const SizedBox(height: 12),
                                      DayStartCloseButtons(
                                        showStart: true,
                                        onAfterAction: () async {
                                          await dayCtrl.refreshOpen();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),

                    // ---------------- Settings ----------------
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              buildSettingsGroup(
                                context,
                                title: "Localization",
                                children: [
                                  buildTwoColumnRow(
                                    context,
                                    "Country",
                                    controller.country,
                                    controller.countryList,
                                    "Timezone",
                                    controller.timezone,
                                    controller.timezoneList,
                                    controller,
                                  ),
                                  const SizedBox(height: 16),
                                  buildTwoColumnRow(
                                    context,
                                    "Language",
                                    controller.language,
                                    controller.languageList
                                        .map((e) => e['name'] as String)
                                        .toList(),
                                    "Currency",
                                    controller.currency,
                                    controller.currencyList,
                                    controller,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              buildSettingsGroup(
                                context,
                                title: "Business Hours & Reset",
                                children: [
                                  buildTwoColumnRow(
                                    context,
                                    "Start Day Time",
                                    controller.startDayTime,
                                    null,
                                    "Close Day Time",
                                    controller.closeDayTime,
                                    null,
                                    controller,
                                  ),
                                  const SizedBox(height: 16),
                                  buildTwoColumnRow(
                                    context,
                                    "Next Reset Bill",
                                    controller.resetBillType,
                                    controller.resetBillOptions,
                                    "Next Reset KOT",
                                    controller.resetKotType,
                                    controller.resetKotOptions,
                                    controller,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Obx(
                                () => GlassCard(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  child: SwitchListTile(
                                    title: const Text(
                                      'Show bill actions on table cards',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    value: Get.find<ControllerSetting>()
                                        .billActionsOnTableEnabled
                                        .value,
                                    onChanged: (v) =>
                                        Get.find<ControllerSetting>()
                                            .setShowBillIconsOnTable(v),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              buildSettingsGroup(
                                context,
                                title: "Preferences",
                                children: [
                                  buildTwoColumnRow(
                                    context,
                                    "Save Order Type",
                                    controller.saveOrderTypeEnabled,
                                    null,
                                    "Default Order Type",
                                    controller.defaultOrderType,
                                    controller.orderTypes,
                                    controller,
                                  ),
                                  const SizedBox(height: 12),
                                  Obx(
                                    () => SwitchListTile(
                                      title: const Text("Show Order Type"),
                                      value:
                                          controller.saveOrderTypeEnabled.value,
                                      onChanged: (v) {
                                        controller.saveOrderTypeEnabled.value =
                                            v;
                                        controller.saveSettings();
                                      },
                                    ),
                                  ),
                                  Obx(
                                    () => SwitchListTile(
                                      title: const Text("Dark Mode"),
                                      value: controller.isDarkMode.value,
                                      onChanged: (v) {
                                        controller.toggleDarkMode(v);
                                        Get.changeThemeMode(
                                          v ? ThemeMode.dark : ThemeMode.light,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () {
                                    controller.saveSettings();
                                    final selectedLang =
                                        controller.language.value;
                                    final langMap = controller.languageList
                                        .firstWhere(
                                          (l) => l['name'] == selectedLang,
                                          orElse: () =>
                                              controller.languageList.first,
                                        );
                                    Get.updateLocale(langMap['locale']);
                                    controller.showSnackBar(
                                      "settings_saved".tr,
                                      "settings_updated".tr,
                                    );
                                  },
                                  child: Text(
                                    "Save Settings".tr,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    //----- Printer TAB -------
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const BtPrinterQuickConnect(),
                              const SizedBox(height: 12),
                              GlassCard(
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        "Printer Configuration",
                                        style: theme.textTheme.titleLarge,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Center(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 22,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(Icons.print_sharp),
                                        label: Text(
                                          'add printer configuration'.tr,
                                        ),
                                        onPressed: () =>
                                            showAddPrinterDialog(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              GlassCard(
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "KOT Printer Configuration",
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    showPrinterList(
                                      context,
                                      controller.kotPrinterDatabaseList,
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              GlassCard(
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "BILL Printer Configuration",
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    showPrinterList(
                                      context,
                                      controller.billPrinterDatabaseList,
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ---------------- Modern group card (kept for backwards compatibility)
  Widget buildSettingsGroup(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  /// ---------------- Responsive Row ----------------
  Widget buildTwoColumnRow(
    BuildContext context,
    String label1,
    Rx value1,
    List<String>? options1,
    String label2,
    Rx value2,
    List<String>? options2,
    ControllerSetting controller,
  ) {
    final width = MediaQuery.of(context).size.width;
    final bool isNarrow = width < 760;
    final bool isVeryWide = width > 1000;

    // On wide screens, add extra spacing
    if (isNarrow) {
      return Column(
        children: [
          buildField(context, label1, value1, options1, controller),
          const SizedBox(height: 12),
          buildField(context, label2, value2, options2, controller),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: buildField(context, label1, value1, options1, controller),
        ),
        SizedBox(width: isVeryWide ? 28 : 16),
        Expanded(
          child: buildField(context, label2, value2, options2, controller),
        ),
      ],
    );
  }

  /// ---------------- Field Builder ----------------
  Widget buildField(
    BuildContext context,
    String label,
    Rx value,
    List<String>? options,
    ControllerSetting controller,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 8),
        Obx(() {
          if (options != null) {
            return DropdownButtonFormField<String>(
              value: value.value is String ? value.value as String : null,
              items: options
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (newValue) {
                if (newValue == null) return;
                if (label.toLowerCase().contains("language")) {
                  controller.setLanguage(newValue);
                } else {
                  value.value = newValue;
                  controller.saveSettings();
                }
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.01)
                    : Colors.white,
              ),
            );
          }

          if (value is Rx<TimeOfDay>) {
            return TextFormField(
              readOnly: true,
              controller: TextEditingController(
                text: value.value.format(context),
              ),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.01)
                    : Colors.white,
              ),
              onTap: () async {
                TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: value.value,
                );
                if (picked != null) {
                  value.value = picked;
                  controller.saveSettings();
                }
              },
            );
          }

          if (value is RxBool) {
            return Switch(
              value: value.value,
              onChanged: (v) {
                value.value = v;
                controller.saveSettings();
              },
            );
          }

          return Text(
            value.value?.toString() ?? '',
            style: theme.textTheme.bodyMedium,
          );
        }),
      ],
    );
  }
}

/// ---------------- Add Printer Dialog ----------------
void showAddPrinterDialog(BuildContext context) {
  final ControllerSetting controller = Get.put(ControllerSetting());
  final formKey = GlobalKey<FormState>();

  // Refresh printer data
  controller.fetchKotPrinterFromDatabase();
  controller.fetchBillPrinterFromDatabase();

  showDialog(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Add Printer Configuration",
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Select Configure",
                        border: OutlineInputBorder(),
                      ),
                      value:
                          controller
                              .textEditingControllerConfigType
                              .text
                              .isEmpty
                          ? null
                          : controller.textEditingControllerConfigType.text,
                      items: ['KOT', 'BILL']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          controller.textEditingControllerConfigType.text =
                              val ?? '',
                      validator: (v) => v == null || v.isEmpty
                          ? "Select Configure type"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    Obx(() {
                      final allPrinters = <dynamic>{
                        ...controller.printerSystemList,
                        ...controller.kotPrinterDatabaseList,
                        ...controller.billPrinterDatabaseList,
                      }.toList();

                      return DropdownButtonFormField<EntityPrinter>(
                        decoration: const InputDecoration(
                          labelText: "Select Printer",
                          border: OutlineInputBorder(),
                        ),
                        value: controller.selectedPrinter.value,
                        items: allPrinters.map((printer) {
                          final name = printer.printName ?? 'Unnamed Printer';
                          final mac = printer.printUrl ?? '';
                          return DropdownMenuItem<EntityPrinter>(
                            value: printer,
                            child: Text(
                              '$name  (${mac.replaceAll("bluetooth://", "")})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (printer) {
                          controller.selectedPrinter.value = printer;
                        },
                        validator: (v) => v == null ? "Select a printer" : null,
                      );
                    }),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Select Source",
                        border: OutlineInputBorder(),
                      ),
                      value: controller.textControllerUserType.text.isEmpty
                          ? null
                          : controller.textControllerUserType.text,
                      items: ['POS', 'Server', 'KDS', 'Captain']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          controller.textControllerUserType.text = val ?? '',
                      validator: (v) =>
                          v == null || v.isEmpty ? "Select Source type" : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Order Type",
                        border: OutlineInputBorder(),
                      ),
                      value: controller.textControllerOrderType.text.isEmpty
                          ? null
                          : controller.textControllerOrderType.text,
                      items:
                          [
                                'Default',
                                'Dine in',
                                'Pickup',
                                'Quick Bill',
                                'Delivery',
                              ]
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                      onChanged: (val) =>
                          controller.textControllerOrderType.text = val ?? '',
                      validator: (v) =>
                          v == null || v.isEmpty ? "Select Order Type" : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<EnumPrinterSize>(
                      decoration: const InputDecoration(
                        labelText: "Printer Size",
                        border: OutlineInputBorder(),
                      ),
                      value: controller.selectedSizeEnum.value,
                      items: EnumPrinterSize.values
                          .map(
                            (size) => DropdownMenuItem(
                              value: size,
                              child: Text(size.label),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          controller.selectedSizeEnum.value = val!,
                      validator: (v) =>
                          v == null ? "Select printer size" : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      initialValue: controller.copies.value.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Number of Copies",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) =>
                          controller.copies.value = int.tryParse(val) ?? 1,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return "Enter number of copies";
                        final n = int.tryParse(v);
                        if (n == null || n <= 0) return "Must be > 0";
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              controller.saveAllPrinterDetails();
                              Navigator.pop(ctx);
                            }
                          },
                          child: const Text("Save"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// ---------------- Printer List Table ----------------
Widget showPrinterList(BuildContext context, List<EntityPrinter> printerList) {
  ControllerSetting controller = Get.put(ControllerSetting());

  final theme = Theme.of(context);

  return Obx(() {
    if (printerList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text(
          "No printers configured.",
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    // Make table responsive & modern
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.resolveWith(
              (states) => theme.colorScheme.secondaryContainer.withAlpha(40),
            ),
            dataRowHeight: 56,
            columnSpacing: 20.0,
            columns: const [
              DataColumn(label: Text('Printer Name')),
              DataColumn(label: Text('URL')),
              DataColumn(label: Text('Model')),
              DataColumn(label: Text('IsAvailable')),
              DataColumn(label: Text('Default')),
              DataColumn(label: Text('Comment')),
              DataColumn(label: Text('Size')),
              DataColumn(label: Text('Copies')),
              DataColumn(label: Text('Actions')),
            ],
            rows: printerList.map((printer) {
              return DataRow(
                cells: [
                  DataCell(SelectableText(printer.printName ?? 'N/A')),
                  DataCell(SelectableText(printer.printUrl ?? 'N/A')),
                  DataCell(Text(printer.printModel ?? 'N/A')),
                  DataCell(
                    Row(
                      children: [
                        Icon(
                          printer.printIsAvailable == true
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: printer.printIsAvailable == true
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(printer.printIsAvailable == true ? 'Yes' : 'No'),
                      ],
                    ),
                  ),
                  DataCell(Text(printer.printDefault == true ? 'Yes' : 'No')),
                  DataCell(Text(printer.printComment ?? 'N/A')),
                  DataCell(Text(printer.printerSize ?? 'N/A')),
                  DataCell(Text(printer.noOfCop.toString())),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            showEditPrinterDialog(context, printer);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Printer'),
                                content: Text(
                                  'Are you sure you want to delete this ${printer.printName} printer?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.error,
                                      foregroundColor:
                                          theme.colorScheme.onError,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              controller.removePrinterAtIndex(printer);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  });
}

/// ---------------- Edit Printer Dialog ----------------
void showEditPrinterDialog(BuildContext context, EntityPrinter printer) {
  ControllerSetting controller = Get.put(ControllerSetting());
  final formKey = GlobalKey<FormState>();

  // Pre-fill fields
  controller.textEditingControllerConfigType.text = printer.configType ?? '';
  controller.textControllerUserType.text = printer.source ?? '';
  controller.textControllerOrderType.text = printer.orderType ?? '';
  controller.selectedPrinter.value = printer;
  controller.selectedSizeEnum.value = EnumPrinterSize.values.firstWhere(
    (e) => e.label == printer.printerSize,
    orElse: () => EnumPrinterSize.mm80,
  );
  controller.copies.value = printer.noOfCop;

  showDialog(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Edit Printer Configuration",
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Select Configure",
                        border: OutlineInputBorder(),
                      ),
                      value: controller.textEditingControllerConfigType.text,
                      items: ['KOT', 'BILL']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          controller.textEditingControllerConfigType.text =
                              val ?? '',
                      validator: (v) => v == null || v.isEmpty
                          ? "Select Configure type"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Select Printer",
                        border: OutlineInputBorder(),
                      ),
                      value: controller.selectedPrinter.value?.printName,
                      items: controller.printerSystemList.map((p) {
                        return DropdownMenuItem<String>(
                          value: p.printName,
                          child: Text(p.printName ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) {
                        final selected = controller.printerSystemList
                            .firstWhere(
                              (p) => p.printName == val,
                              orElse: () => EntityPrinter(),
                            );
                        controller.selectedPrinter.value = selected;
                      },
                      validator: (v) =>
                          v == null || v.isEmpty ? "Select printer" : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Select Source",
                        border: OutlineInputBorder(),
                      ),
                      value: controller.textControllerUserType.text,
                      items: ['POS', 'Server', 'KDS', 'Captain']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          controller.textControllerUserType.text = val ?? '',
                      validator: (v) =>
                          v == null || v.isEmpty ? "Select User type" : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Order Type",
                        border: OutlineInputBorder(),
                      ),
                      value: controller.textControllerOrderType.text,
                      items:
                          [
                                'Default',
                                'Dine in',
                                'Pickup',
                                'Quick Bill',
                                'Delivery',
                              ]
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                      onChanged: (val) =>
                          controller.textControllerOrderType.text = val ?? '',
                      validator: (v) =>
                          v == null || v.isEmpty ? "Select Order type" : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<EnumPrinterSize>(
                      decoration: const InputDecoration(
                        labelText: "Printer Size",
                        border: OutlineInputBorder(),
                      ),
                      value: controller.selectedSizeEnum.value,
                      items: EnumPrinterSize.values
                          .map(
                            (size) => DropdownMenuItem(
                              value: size,
                              child: Text(size.label),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          controller.selectedSizeEnum.value = val!,
                      validator: (v) =>
                          v == null ? "Select printer size" : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      initialValue: controller.copies.value.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Number of Copies",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) =>
                          controller.copies.value = int.tryParse(val) ?? 1,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return "Enter number of copies";
                        final n = int.tryParse(v);
                        if (n == null || n <= 0) return "Must be > 0";
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              controller.updatePrinter(printer);
                              Navigator.pop(ctx);
                            }
                          },
                          child: const Text("Update"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// ---------------- Day status card (keeps existing content, wrapped by GlassCard earlier) ----------------
Widget dayStatusCard(BuildContext context, {required EntityDayReport? open}) {
  final theme = Theme.of(context);
  final df = DateFormat('yyyy-MM-dd hh:mm:ss a');

  final isOpen = open != null;
  final title = isOpen ? 'Close Day' : 'Start Day';
  final subtitle = isOpen
      ? 'Start Date: ${df.format(open.openedAt)}'
      : 'No active day';

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.meeting_room_outlined,
        size: 42,
        color: theme.colorScheme.secondary,
      ),
      const SizedBox(height: 10),
      Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class DayStartCloseButtons extends StatelessWidget {
  const DayStartCloseButtons({
    super.key,
    this.onAfterAction,
    this.showStart = true,
  });

  final Future<void> Function()? onAfterAction;
  final bool showStart;

  @override
  Widget build(BuildContext context) {
    final dayCtrl = Get.find<DayStatusController>();
    final theme = Theme.of(context);

    return Obx(() {
      final open = dayCtrl.openReport.value; // if null → day not started

      final bool dayIsOpen = open != null;

      final buttons = <Widget>[];

      // ---------------------------------------------------------
      // ⭐ START DAY BUTTON – WILL SHOW ONLY IF DAY IS NOT STARTED
      // ---------------------------------------------------------
      if (showStart && !dayIsOpen) {
        buttons.add(
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Open Start Day & Shift'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await ShiftStartDialog.show(); // opens dialog
              await dayCtrl.refreshOpen(); // ⭐ updates UI state
              if (onAfterAction != null) await onAfterAction!();
            },
          ),
        );
        buttons.add(const SizedBox(width: 12));
      }

      // ---------------------------------------------------------
      // ⭐ CLOSE DAY BUTTON – SHOW ONLY WHEN DAY IS OPEN
      // ---------------------------------------------------------
      if (dayIsOpen) {
        buttons.add(
          ElevatedButton.icon(
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Close Day & Shift'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await CloseShiftDialog.show();
              await dayCtrl.refreshOpen(); // ⭐ day becomes closed
              if (onAfterAction != null) await onAfterAction!();
            },
          ),
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons,
      );
    });
  }
}
