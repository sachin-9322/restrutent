import 'package:get/get.dart';
import 'package:splash_screen_03/captain/home/activity_captain_home.dart';
import 'package:splash_screen_03/captain/login/activity_login.dart';
import 'package:splash_screen_03/captain/login/resume_session.dart';
import 'package:splash_screen_03/captain/serverList/activity_server_selection.dart';
import 'package:splash_screen_03/kds/fragment/fragment_home.dart';
import 'package:splash_screen_03/screens/home/fragments/order/fragment_order.dart';
import 'package:splash_screen_03/screens/food_type_form/activity_food_form.dart';
import 'package:splash_screen_03/screens/table_type_form/activity_table_form.dart';
import 'package:splash_screen_03/screens/tax_type_form/activity_tax_form.dart';

import '../screens/category_type_form/activity_category_type_form.dart';
import '../screens/home/activity_home.dart';
import '../screens/order_type_form/activity_order_form.dart';
import '../screens/room_type_form/activity_room_form.dart';
import '../screens/user_form/activity_user_form.dart';

class AppRoutes {
  //AppRoutes.activityHome

  static const activityHome = "/home";
  static const roomTypeForm = "/roomTypeForm";
  static const orderTypeForm = "/orderTypeForm";
  static const categoryTypeForm = "/categoryTypeForm";
  static const foodTypeForm = "/foodTypeForm";
  static const tableTypeForm = "/tableTypeForm";
  static const userForm = "/userForm";
  static const categoryFood = "/categoryFood";
  static const login = "/login";
  static const serverSelection = "/serverSelection";
  static const captainPull = "/captainPull";
  static const taxTypeForm = "/TaxTypeForm";
  static const captainHome = "/captainHome";
  static const captainMobile = "/captainMobile";
  static const activityHomed = "/activityHomed";
    static const activity_resume = "/activity_resume";


  static final List<GetPage> listPages = [
    GetPage(
      name: activityHome,
      page: () {
        return ActivityHome();
      },
    ),
    GetPage(
      name: roomTypeForm,
      page: () {
        return ActivityRoomForm();
      },
    ),
    GetPage(
      name: activityHomed,
      page: () {
        return ActivityKDSHome(serverIp: '', serverPort: 4040);
      },
    ),
    GetPage(
      name: orderTypeForm,
      page: () {
        return ActivityOrderForm();
      },
    ),

    GetPage(
      name: categoryTypeForm,
      page: () {
        return ActivityCategoryForm();
      },
    ),
    GetPage(
      name: foodTypeForm,
      page: () {
        return ActivityFoodForm();
      },
    ),

    GetPage(
      name: tableTypeForm,
      page: () {
        return ActivityTableForm();
      },
    ),

    GetPage(
      name: categoryFood,
      page: () {
        return ActivityCategoryFood();
      },
    ),

    GetPage(
      name: userForm,
      page: () {
        return ActivityUserForm();
      },
    ),
    GetPage(
      name: login,
      page: () {
        return ActivityLogin();
      },
    ),
    GetPage(
      name: serverSelection,
      page: () => ActivityServerSelection(
        username: Get.arguments['username'],
        password: Get.arguments['password'],
      ),
    ),
     GetPage(
      name: activity_resume,
      page: () {
        return ResumeSessionPage();
      },
    ),
    // GetPage(
    //   name: captainPull,
    //   page: () {
    //   },
    // ),
    GetPage(
      name: captainHome,
      page: () {
        return ActivityCaptainHome(serverIp: '', serverPort: 4040);
      },
    ),
    GetPage(
      name: taxTypeForm,
      page: () {
        return ActivityTaxForm();
      },
    ),
  ];
}
