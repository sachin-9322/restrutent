// screens/home/fragments/order/widget/app_windowListerner.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';
import 'package:window_manager/window_manager.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';

class AppWindowListener with WindowListener {
  @override
  void onWindowClose() async {
    // If preventClose is not enabled (e.g., on web/mobile), let it close.
    final prevent = await windowManager.isPreventClose();
    if (!prevent) return;

    // Avoid opening multiple dialogs if user clicks close repeatedly.
    if (Get.isDialogOpen == true) return;

    final order = Get.isRegistered<ControllerOrder>()
        ? Get.find<ControllerOrder>()
        : null;

    // If no order controller, close app directly.
    if (order == null) {
      await windowManager.setPreventClose(false);
      await windowManager.close();
      return;
    }

    // Requires these helpers in ControllerOrder:
    // - List<EntityOrder> getAllOpenBills()
    // - Map<String, int> openBillCountsByTable()
    // - Future<void> settleAllOpenBills()
    final openBills = order.getAllOpenBills();

    // If nothing open anywhere, close app.
    if (openBills.isEmpty) {
      await windowManager.setPreventClose(false);
      await windowManager.close();
      return;
    }

    final counts = order.openBillCountsByTable();
    await Get.dialog(
      Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              GlasssCard(
                borderRadius: 22,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),

                      Icon(
                        Icons.warning_amber_rounded,
                        size: 60,
                        color: Colors.amber,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Are you sure?",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.95),
                          decoration: TextDecoration.none, // ⭐ FIX
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Some bills are still open. If you exit now, they will remain unsettled.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.75),
                          decoration: TextDecoration.none, // ⭐ FIX
                        ),
                      ),

                      const SizedBox(height: 16),

                      // if (counts.isNotEmpty)
                      //   Column(
                      //     children: counts.entries.map((e) {
                      //       return Padding(
                      //         padding: const EdgeInsets.symmetric(vertical: 4),
                      //         child: Row(
                      //           mainAxisAlignment: MainAxisAlignment.center,
                      //           children: [
                      //             Icon(
                      //               Icons.table_restaurant,
                      //               size: 18,
                      //               color: Colors.white.withOpacity(0.8),
                      //             ),
                      //             const SizedBox(width: 8),
                      //             // Text(
                      //             //   "Table ${e.key}  •  Bills: ${e.value}",
                      //             //   style: TextStyle(
                      //             //     fontSize: 15,
                      //             //     fontWeight: FontWeight.w500,
                      //             //     color: Colors.white.withOpacity(0.85),
                      //             //     decoration: TextDecoration.none, // ⭐ FIX
                      //             //   ),
                      //             // ),
                      //           ],
                      //         ),
                      //       );
                      //     }).toList(),
                      //   ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white.withOpacity(0.8),
                              ),
                              onPressed: () async {
                                if (Get.isDialogOpen ?? false) Get.back();
                                await windowManager.setPreventClose(false);
                                await windowManager.close();
                              },
                              child: const Text(
                                "Exit Anyway",
                                style: TextStyle(
                                  decoration: TextDecoration.none, // ⭐ FIX
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Expanded(
                          //   child: ElevatedButton(
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: Colors.black.withOpacity(0.55),
                          //       foregroundColor: Colors.white,
                          //       elevation: 0,
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(30),
                          //       ),
                          //       padding: const EdgeInsets.symmetric(
                          //         vertical: 12,
                          //         horizontal: 8,
                          //       ),
                          //     ),
                          //     onPressed: () async {
                          //       await order.settleAllOpenBills();
                          //       if (Get.isDialogOpen ?? false) Get.back();
                          //       await windowManager.setPreventClose(false);
                          //       await windowManager.close();
                          //     },
                          //     child: const Text(
                          //       "Settle All & Exit",
                          //       style: TextStyle(
                          //         fontWeight: FontWeight.bold,
                          //         decoration: TextDecoration.none, // ⭐ FIX
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),

                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              Positioned(
                right: 12,
                top: 12,
                child: GestureDetector(
                  onTap: () {
                    if (Get.isDialogOpen ?? false) Get.back();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
