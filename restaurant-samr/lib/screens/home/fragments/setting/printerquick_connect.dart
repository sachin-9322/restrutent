import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:objectbox/objectbox.dart';
import 'package:splash_screen_03/model/entity_printer.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/raw_pritner_service.dart';

class BtPrinterQuickConnect extends StatelessWidget {
  const BtPrinterQuickConnect({super.key});

  @override
  Widget build(BuildContext context) {
    final kotSvc = Get.put(RawBtPrinterService(), tag: "KOT", permanent: true);
    final billSvc = Get.put(RawBtPrinterService(), tag: "BILL", permanent: true);
    final Box<EntityPrinter> printerBox = Get.find();
WidgetsBinding.instance.addPostFrameCallback((_) async {
  // Try to keep stable persistent connection state
  await Future.wait([
    kotSvc.autoReconnect("KOT"),
    billSvc.autoReconnect("BILL"),
  ]);

  // Delay ensures that status doesn’t flash back to “not connected”
  await Future.delayed(const Duration(milliseconds: 400));
  await kotSvc.refreshConnectionStatus();
  await billSvc.refreshConnectionStatus();
});

    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.print, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text(
                    "Bluetooth ESC/POS Printer Setup",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 🔹 KOT Printer Section
              _buildPrinterBlock(
                context,
                title: "KOT Printer",
                color: Colors.blueAccent,
                svc: kotSvc,
                onSave: (device) async {
                  await _saveBluetoothPrinter(
                    printerBox,
                    printerName: device.name,
                    macAddress: device.mac,
                    type: "KOT",
                  );
                },
              ),
              const SizedBox(height: 20),

              // 🔹 BILL Printer Section
              _buildPrinterBlock(
                context,
                title: "BILL Printer",
                color: Colors.green,
                svc: billSvc,
                onSave: (device) async {
                  await _saveBluetoothPrinter(
                    printerBox,
                    printerName: device.name,
                    macAddress: device.mac,
                    type: "BILL",
                  );
                },
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPrinterBlock(
    BuildContext context, {
    required String title,
    required Color color,
    required RawBtPrinterService svc,
    required Future<void> Function(BtPrinterDevice) onSave,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('Scan & Connect'),
                onPressed: () async {
                  final dialogContext = context;

                  // 🔹 Show loading immediately
                  showDialog(
                    context: dialogContext,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  // 🔹 Use cached list if available (instant open)
                  final list = await svc.scanBluetooth();

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext); // close loader

                  if (list.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('⚠️ No Bluetooth printers found.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  // 🔹 Show device dialog instantly
                  _showDeviceDialog(
                    dialogContext,
                    list,
                    onPick: (device) async {
                      final ok = await svc.connectBluetooth(device);
                      if (ok && dialogContext.mounted) {
                        await onSave(device);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                                '✅ ${device.name} connected as $title'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(dialogContext);
                      }
                    },
                  );
                },
              ),
              FilledButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Test Print'),
                onPressed: svc.connected.value
                    ? () => svc.testPrint(charsPerLine: 32)
                    : null,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.link_off),
                label: const Text('Disconnect'),
                onPressed: svc.connected.value
                    ? () async {
                        await svc.disconnect();
                        svc.connected.value = false;
                        svc.deviceLabel.value = '';
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Icon(
                svc.connected.value ? Icons.check_circle : Icons.cancel,
                color: svc.connected.value ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  svc.connected.value
                      ? 'Connected • ${svc.deviceLabel.value}'
                      : 'Not connected',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📡 Device Picker (AlertDialog)
  void _showDeviceDialog(
    BuildContext context,
    List<BtPrinterDevice> list, {
    required Function(BtPrinterDevice) onPick,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.bluetooth, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text("Select Bluetooth Printer"),
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 300,
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final d = list[i];
                return ListTile(
                  leading: const Icon(Icons.print, color: Colors.blueAccent),
                  title: Text(d.name),
                  subtitle: Text('MAC: ${d.mac}'),
                  onTap: () => onPick(d),
                );
              },
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  /// 💾 Save printer into ObjectBox
  Future<void> _saveBluetoothPrinter(
    Box<EntityPrinter> box, {
    required String printerName,
    required String macAddress,
    required String type,
  }) async {
    final q = box.query(EntityPrinter_.configType.equals(type)).build();
    final existing = q.find();
    for (final e in existing) {
      box.remove(e.id);
    }
    q.close();

    final printer = EntityPrinter(
      configType: type,
      printName: printerName,
      printUrl: 'bluetooth://$macAddress',
      printModel: 'Thermal Printer',
      printerSize: '58',
      printLocation: type == 'KOT' ? 'Kitchen' : 'Counter',
      printDefault: true,
      printIsAvailable: true,
      noOfCop: 1,
      createdBy: 'Admin',
      source: 'Captain App',
      createdOn: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    );

    box.put(printer);
    debugPrint('✅ Saved $type printer: ${printer.printName} (${printer.printUrl})');
  }
}
