import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:splash_screen_03/kds/fragment/controller_kds.dart';
import 'package:splash_screen_03/kds/fragment/widget/menu_configuartion.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';
import 'package:splash_screen_03/utils/app_routes.dart';

class KdsHome extends StatefulWidget {
  const KdsHome({super.key});

  @override
  State<KdsHome> createState() => _KdsHomeState();
}

class _KdsHomeState extends State<KdsHome> {
  bool showSettings = false;
  final kotController = Get.put(KOTController());
  // Reactive variables for interval values
  RxInt firstStart = 0.obs;
  RxInt firstEnd = 5.obs;
  RxInt secondStart = 5.obs;
  RxInt secondEnd = 10.obs;
  RxInt thirdStart = 10.obs;
  RxInt thirdEnd = 15.obs;

  Color getKotColorByIndex(int index) {
    if (index >= firstStart.value && index < firstEnd.value) return Colors.teal;
    if (index >= secondStart.value && index < secondEnd.value)
      return Colors.orange;
    if (index >= thirdStart.value && index < thirdEnd.value) return Colors.red;
    return Colors.grey;
  }

  @override
  void initState() {
    super.initState();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ControllerSetting());

    final storage = controller.box;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("RH POS KDS"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildTopHeader(),
        ),
        actions: [
          Obx(
            () => Row(
              children: [
                Switch(
                  value: kotController.tokenViewMode.value,
                  onChanged: (val) {
                    kotController.tokenViewMode.value = val;
                  },
                  activeColor: Colors.white,
                  inactiveThumbColor: Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.28,
        child: Drawer(
          child: showSettings ? _buildSettingsDrawer() : _buildMainDrawer(),
        ),
      ),
      body: Obx(() {
        final filteredKots = kotController.kotList.where((kot) {
          final orderTypeMatch =
              kotController.orderType.value == "All" ||
              kot.orderType.toLowerCase() ==
                  kotController.orderType.value.toLowerCase();
          final statusMatch =
              kotController.kotStatus.value == "All" ||
              kot.status == kotController.kotStatus.value;
          return orderTypeMatch && statusMatch;
        }).toList();

        if (kotController.tokenViewMode.value) {
        // _buildGridMode()
return GridView.builder(
  padding: const EdgeInsets.all(16),
  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 380,
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    childAspectRatio: 1.25,
  ),
  itemCount: kotController.kotList.length,
  itemBuilder: (context, index) {
    final kot = kotController.kotList[index];
    return _buildKOTCard(kot, index);
  },
);
        } else {
          // For status columns view
          final placedKots = filteredKots
              .where((k) => k.status == "Placed")
              .toList();
          final preparingKots = filteredKots
              .where((k) => k.status == "Preparing")
              .toList();
          final readyKots = filteredKots
              .where((k) => k.status == "Ready")
              .toList();

          return Row(
            children: [
              _buildStatusColumn(
                "Placed",
                Colors.yellow.shade200,
                placedKots,
                headerColor: Colors.black,
              ),
              _buildStatusColumn(
                "Preparing",
                Colors.orange.shade200,
                preparingKots,
                headerColor: Colors.black,
              ),
              _buildStatusColumn(
                "Ready",
                Colors.green.shade200,
                readyKots,
                headerColor: Colors.black,
              ),
            ],
          );
        }
      }),
    );
  }

  Widget _buildGridMode() {
    if (kotController.kotList.isEmpty) {
      return const Center(child: Text("No KOTs yet"));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: kotController.kotList.length,
      itemBuilder: (context, index) {
        final kot = kotController.kotList[index];
        return _buildKOTCard(kot, index);
      },
    );
  }

  /// Main Drawer
  Widget _buildMainDrawer() {
    return Column(
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: Colors.teal),
          child: Row(
            children: [
              const Icon(Icons.store, size: 40, color: Colors.white),
              const SizedBox(width: 12),
              const Text(
                "RH POS",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.menu_book),
          title: const Text("Menu Configuration"),
          onTap: () {
            Get.to(() => MenuConfigurationScreen());
          },
        ),

        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text("Settings"),
          onTap: () {
            setState(() {
              showSettings = true;
            });
          },
        ),
        const Spacer(),
        ListTile(
          leading: const Icon(Icons.power_settings_new, color: Colors.red),
          title: const Text("Logout"),
          onTap: () {
            // 1️⃣ Clear saved login info
            final box = GetStorage();
            box.erase(); // removes all keys or use remove('isLoggedIn') if you want selective

            // 2️⃣ Remove stored KDS server info
            if (Get.isRegistered<Map<String, dynamic>>(tag: 'kdsServer')) {
              Get.delete<Map<String, dynamic>>(tag: 'kdsServer');
            }

            // 3️⃣ Navigate to login and remove all previous routes
            Get.offAllNamed(AppRoutes.login);
          },
        ),
      ],
    );
  }

  /// Settings Drawer
  Widget _buildSettingsDrawer() {
    return Column(
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: Colors.teal),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    showSettings = false;
                  });
                },
              ),
              const SizedBox(width: 12),
              const Text(
                "KDS Settings",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // Settings Content
        Expanded(
          child: Obx(
            () => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // First interval
                Row(
                  children: [
                    Container(width: 16, height: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text("First interval"),
                    const Spacer(),
                    _intervalBox(
                      firstStart.value.toString(),
                      onChanged: (val) {
                        firstStart.value =
                            int.tryParse(val) ?? firstStart.value;
                      },
                    ),
                    const Text("to"),
                    _intervalBox(
                      firstEnd.value.toString(),
                      onChanged: (val) {
                        firstEnd.value = int.tryParse(val) ?? firstEnd.value;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Second interval
                Row(
                  children: [
                    Container(width: 16, height: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text("Second interval"),
                    const Spacer(),
                    _intervalBox(
                      secondStart.value.toString(),
                      onChanged: (val) {
                        secondStart.value =
                            int.tryParse(val) ?? secondStart.value;
                      },
                    ),
                    const Text("to"),
                    _intervalBox(
                      secondEnd.value.toString(),
                      onChanged: (val) {
                        secondEnd.value = int.tryParse(val) ?? secondEnd.value;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Third interval
                Row(
                  children: [
                    Container(width: 16, height: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text("Third interval"),
                    const Spacer(),
                    _intervalBox(
                      thirdStart.value.toString(),
                      onChanged: (val) {
                        thirdStart.value =
                            int.tryParse(val) ?? thirdStart.value;
                      },
                    ),
                    const Text("to"),
                    _intervalBox(
                      thirdEnd.value.toString(),
                      onChanged: (val) {
                        thirdEnd.value = int.tryParse(val) ?? thirdEnd.value;
                      },
                    ),
                  ],
                ),

                const Divider(height: 32),

                // 🔹 Switch options
                _buildSwitch("Display Category and Item Count", false),
                _buildSwitch(
                  "Plated for Dine-IN & Parcel for Pickup and Delivery",
                  false,
                ),
                _buildSwitch("Display KOT in Full Size", true),
                _buildSwitch("Display KOT in Chain View", false),
                _buildSwitch("Place New KOT Next to Existing KOT", false),
                _buildSwitch("Show Latest KOT First", true),

                const SizedBox(height: 20),
                Divider(),
                // 🔹 Printer settings
                const Text(
                  "KOTS Printer Settings",
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _dropdownBox("Select...")),
                    const SizedBox(width: 8),
                    Expanded(child: _dropdownBox("Select...")),
                    const SizedBox(width: 8),
                    Expanded(child: _dropdownBox("Qty")),
                  ],
                ),
                const SizedBox(height: 20),

                // 🔹 Buttons
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text("Add"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text("Clear"),
                    ),
                  ],
                ),
                Divider(),
                Divider(),
                const Text(
                  "Token Management Settings",
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 12),

                // 1. Token Display Mode
                const Text(
                  "1. Token Display Mode",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Obx(
                  () => SwitchListTile(
                    value: kotController.onlyTokenNumber.value,
                    onChanged: (val) =>
                        kotController.onlyTokenNumber.value = val,
                    title: const Text("a. Only Token Number"),
                  ),
                ),
                Obx(
                  () => SwitchListTile(
                    value: kotController.enhancedTokenView.value,
                    onChanged: (val) =>
                        kotController.enhancedTokenView.value = val,
                    title: const Text("b. Enhanced Token View"),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => SwitchListTile(
                          value: kotController.displayLogo.value,
                          onChanged: (val) =>
                              kotController.displayLogo.value = val,
                          title: const Text("I. Display Logo"),
                        ),
                      ),
                      Obx(
                        () => SwitchListTile(
                          value: kotController.displayBrandName.value,
                          onChanged: (val) =>
                              kotController.displayBrandName.value = val,
                          title: const Text("II. Display Brand Name"),
                        ),
                      ),
                      Obx(
                        () => SwitchListTile(
                          value: kotController.displayCustomerName.value,
                          onChanged: (val) =>
                              kotController.displayCustomerName.value = val,
                          title: const Text("III. Display Customer Name"),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Order Status Display Rules
                const Text(
                  "2. Order Status Display Rules",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                // Obx(
                //   () => SwitchListTile(
                //     value: kotController.placedStatus.value,
                //     onChanged: (val) => kotController.placedStatus.value = val,
                //     title: const Text("a. Placed"),
                //     secondary: const Icon(Icons.edit),
                //   ),
                // ),
                // Obx(
                //   () => SwitchListTile(
                //     value: kotController.preparingStatus.value,
                //     onChanged: (val) => kotController.preparingStatus.value = val,
                //     title: const Text("b. Preparing"),
                //     secondary: const Icon(Icons.edit),
                //   ),
                // ),
                // Obx(
                //   () => SwitchListTile(
                //     value: kotController.readyStatus.value,
                //     onChanged: (val) => kotController.readyStatus.value = val,
                //     title: const Text("c. Ready"),
                //     secondary: const Icon(Icons.edit),
                //   ),
                // ),
                // ElevatedButton(
                //   onPressed: () {
                //     // You can handle save logic here
                //     Get.snackbar("Settings", "Order Status Updated");
                //   },
                //   child: const Text("Update"),
                // ),

                // const SizedBox(height: 16),

                // // 3. Repeated Order Number Announcements
                // const Text(
                //   "3. Repeated Order Number Announcements",
                //   style: TextStyle(fontWeight: FontWeight.bold),
                // ),
                // Obx(
                //   () => SwitchListTile(
                //     value: kotController.repeatedAnnouncements.value,
                //     onChanged: (val) =>
                //         kotController.repeatedAnnouncements.value = val,
                //     title: const Text("Enable Repeated Announcements"),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Obx(() {
        return Row(
          children: [
            // 🔄 Recall Button

            // 🔴 Pending Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                border: Border.all(color: Colors.teal.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Text(
                    "Pending KOTs:",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      kotController.pendingCount.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButton<String>(
                value: kotController.orderType.value,
                onChanged: (val) => kotController.orderType.value = val!,
                underline: const SizedBox(),
                dropdownColor: Colors.white,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
                style: const TextStyle(color: Colors.black87), // 🔹 Text color
                items: ["All", "Dine-In", "Takeaway", "Delivery"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
              ),
            ),
            const SizedBox(width: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButton<String>(
                value: kotController.kotStatus.value,
                onChanged: (val) => kotController.kotStatus.value = val!,
                underline: const SizedBox(),
                dropdownColor: Colors.white,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
                style: const TextStyle(color: Colors.black87), // 🔹 Text color
                items: ["All", "Placed", "Preparing", "Ready", "Settled"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
              ),
            ),

            // const Spacer(),

            // Row(
            //   children: [
            //     Switch(
            //       value: kotController.chefMode.value,
            //       onChanged: (val) => kotController.chefMode.value = val,
            //       activeColor: Colors.teal,
            //     ),
            //   ],
            // ),
          ],
        );
      }),
    );
  }

  Widget _buildKOTCard(KOT kot, int index) {
    final statusOptions = ["Preparing", "Ready", "Served"];
    if (!statusOptions.contains(kot.status)) {
      statusOptions.insert(0, kot.status);
    }
    print("KOT #${kot.kotNumber} at index $index color: $getKotColorByIndex");

    return Obx(
      () => Card(
        color: getKotColorByIndex(index),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            // 🔼 Header Section
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.shade700,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "KOT #${kot.kotNumber} (${kot.origin.toUpperCase()})",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Table ${kot.table}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            // 🔹 Items List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Items:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView(
                        children: kot.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              item,
                              style: TextStyle(color: Colors.black),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔽 Footer strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal.shade800,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    "Qty: ${kot.qty}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  Icon(Icons.print),
                  const SizedBox(width: 10),

                  // 🔹 Replace Text with DropdownButton
                  DropdownButton<String>(
                    value: kot.status,
                    dropdownColor: Colors.teal.shade700,
                    iconEnabledColor: Colors.white,
                    underline: const SizedBox(),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        kotController.updateKOTStatus(kot.kotNumber, newValue);
                      }
                    },
                    items: statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(
                          status,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusColumn(
    String title,
    Color bgColor,
    List<KOT> kotList, {
    Color? headerColor,
    Color? textColor,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: headerColor ?? Colors.black87,
                  ),
                ),
              ),
            ),
            Expanded(
              child: kotList.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, color: Colors.grey, size: 40),
                          SizedBox(height: 6),
                          Text("No data", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: kotList.length,
                      itemBuilder: (context, index) {
                        final kot = kotList[index];
                        return _buildKOTStatusDropdown(kot, textColor);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKOTStatusDropdown(KOT kot, Color? textColor) {
    final isExpanded = false.obs;

    return Obx(
      () => Column(
        children: [
          GestureDetector(
            onTap: () => isExpanded.value = !isExpanded.value,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "KOT #${kot.kotNumber}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor ?? Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        kot.status,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isExpanded.value
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded.value)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Table: ${kot.table}",
                    style: TextStyle(color: textColor ?? Colors.black87),
                  ),
                  Text(
                    "Qty: ${kot.qty}",
                    style: TextStyle(color: textColor ?? Colors.black87),
                  ),
                  Text(
                    "Origin: ${kot.origin}",
                    style: TextStyle(color: textColor ?? Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  ...kot.items.map(
                    (item) => Text(
                      item,
                      style: TextStyle(color: textColor ?? Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}";
  }
}

Widget _intervalBox(
  String initialValue, {
  required ValueChanged<String> onChanged,
}) {
  return SizedBox(
    width: 40,
    height: 30,
    child: TextField(
      controller: TextEditingController(text: initialValue),
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
      onChanged: onChanged,
    ),
  );
}

Widget _buildSwitch(String label, bool value) {
  return SwitchListTile(
    value: value,
    onChanged: (val) {},
    activeColor: Colors.teal,
    title: Text(label, style: const TextStyle(color: Colors.white)),
  );
}

Widget _dropdownBox(String hint) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white30),
      borderRadius: BorderRadius.circular(6),
      color: Colors.grey.shade900,
    ),
    child: Text(hint, style: const TextStyle(color: Colors.white70)),
  );
}