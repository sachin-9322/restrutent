import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splash_screen_03/model/entity_user.dart';
import 'controller_user_form.dart';

class ActivityUserForm extends StatelessWidget {
  const ActivityUserForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ControllerUserForm());

    final EntityUser? arguments = Get.arguments as EntityUser?;
    final isNew = arguments == null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? Colors.grey.shade900 : Colors.white;
    final Color inputFill = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    if (!isNew) {
      // Populate all fields for editing, including restaurant and address
      controller.textControllerName.text = arguments.userName ?? '';
      controller.textControllerPassword.text = arguments.userPassword ?? '';
      controller.textControllerType.text = arguments.userType ?? '';
      controller.textControllerFirst.text = arguments.first ?? '';
      controller.textControllerLast.text = arguments.last ?? '';
      controller.textControllerCountryCode.text = arguments.countryCode ?? '';
      controller.textControllerMobile.text = arguments.mobile ?? '';
      controller.textControllerDob.text = arguments.dob ?? '';
      controller.textControllerGender.text = arguments.gender ?? '';
      controller.textControllerIdProofKey.text = arguments.idProofKey ?? '';
      controller.textControllerIdProofValue.text = arguments.idProofValue ?? '';
      controller.editingUser = arguments;
    }

    InputDecoration buildInputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: isDark ? Colors.tealAccent : Colors.teal),
        filled: true,
        fillColor: inputFill,
        labelStyle: TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.tealAccent : Colors.teal),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isNew ? "New User" : "Update User",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.teal,
        elevation: 0,
      ),
      body: Container(
        color: isDark ? Colors.black : Colors.grey.shade50,
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            color: cardBg,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
              width: 800,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              
                              // First + Last Name
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: controller.textControllerFirst,
                                      decoration: buildInputDecoration("First Name", Icons.account_circle),
                                      validator: (v) => v == null || v.isEmpty ? "Please enter first name" : null,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: TextFormField(
                                      controller: controller.textControllerLast,
                                      decoration: buildInputDecoration("Last Name (Optional)", Icons.account_circle_outlined),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              // Username
                              TextFormField(
                                controller: controller.textControllerName,
                                decoration: buildInputDecoration(
                                    isNew ? "Enter Username" : "Username", Icons.person),
                                validator: (v) => v == null || v.isEmpty ? "Please enter username" : null,
                              ),
                              const SizedBox(height: 15),

                              // Password
                              TextFormField(
                                controller: controller.textControllerPassword,
                                decoration: buildInputDecoration(
                                    isNew ? "Enter Password" : "Password", Icons.lock),
                                obscureText: true,
                                validator: (v) => v == null || v.isEmpty ? "Please enter password" : null,
                              ),
                              const SizedBox(height: 15),

                              // User Type
                              DropdownButtonFormField<String>(
                                decoration: buildInputDecoration("User Type", Icons.person),
                                value: controller.textControllerType.text.isEmpty
                                    ? null
                                    : controller.textControllerType.text,
                                items: ['Server', 'POS', 'KDS', 'Captain', 'Waiter']
                                    .map((type) => DropdownMenuItem(
                                          value: type,
                                          child: Text(type, style: TextStyle(color: textPrimary)),
                                        ))
                                    .toList(),
                                onChanged: (val) => controller.textControllerType.text = val ?? '',
                                validator: (v) => v == null || v.isEmpty ? "Please select user type" : null,
                              ),
                              const SizedBox(height: 15),

                              // Country Code + Mobile
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: controller.textControllerCountryCode,
                                      decoration: buildInputDecoration("Country Code", Icons.flag),
                                      validator: (v) => v == null || v.isEmpty ? "Enter code" : null,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    flex: 4,
                                    child: TextFormField(
                                      controller: controller.textControllerMobile,
                                      decoration: buildInputDecoration("Mobile", Icons.phone),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return "Enter mobile number";
                                        if (v.length != 10) return "Enter 10 digit number";
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              // DOB
                              TextFormField(
                                controller: controller.textControllerDob,
                                readOnly: true,
                                decoration: buildInputDecoration("Date of Birth (Optional)", Icons.calendar_today),
                                onTap: () async {
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                    helpText: 'Select your Date of Birth',
                                  );
                                  if (picked != null) {
                                    controller.textControllerDob.text =
                                        DateFormat("dd-MMM-yyyy").format(picked);
                                  }
                                },
                              ),
                              const SizedBox(height: 15),

                              // // Gender
                              // DropdownButtonFormField<String>(
                              //   decoration: buildInputDecoration("Gender", Icons.people),
                              //   value: controller.textControllerGender.text.isEmpty
                              //       ? null
                              //       : controller.textControllerGender.text,
                              //   items: ['Male', 'Female', 'Other']
                              //       .map((g) => DropdownMenuItem(
                              //             value: g,
                              //             child: Text(g, style: TextStyle(color: textPrimary)),
                              //           ))
                              //       .toList(),
                              //   onChanged: (val) => controller.textControllerGender.text = val ?? '',
                              //   validator: (v) => v == null || v.isEmpty ? "Please select gender" : null,
                              // ),
                              // const SizedBox(height: 15),

                              // ID Proof Type + Value
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      decoration: buildInputDecoration("ID Proof Type (Optional)", Icons.perm_identity),
                                      value: controller.textControllerIdProofKey.text.isEmpty
                                          ? null
                                          : controller.textControllerIdProofKey.text,
                                      items: ["Aadhar Card", "PAN Card", "Other"]
                                          .map((p) => DropdownMenuItem(
                                                value: p,
                                                child: Text(p, style: TextStyle(color: textPrimary)),
                                              ))
                                          .toList(),
                                      onChanged: (val) =>
                                          controller.textControllerIdProofKey.text = val ?? '',
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: controller.textControllerIdProofValue,
                                      decoration: buildInputDecoration(
                                          "${controller.textControllerIdProofKey.text.isEmpty ? 'ID Number' : controller.textControllerIdProofKey.text} (Optional)",
                                          Icons.confirmation_number),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                        
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Save/Update button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: isDark ? Colors.tealAccent.shade700 : Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => controller.submitUser(),
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: Text(
                            isNew ? "Save User" : "Update User",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}