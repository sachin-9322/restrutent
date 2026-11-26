class ApiConstant {
  // 🌐 Always use your cloud server — ignore dropdown
  static const String baseUrl = "https://rhposs-server-latest.onrender.com";

  // 📦 API prefix (used for relative paths)
  static const String apiBase = "/api/v1";

  // 🔑 Auth
  static const String login = "$apiBase/auth/login";
  static const String logout = "$apiBase/auth/logout";
  static const String refreshToken = "$apiBase/auth/refresh";

  // 🔍 Restaurant
  static const String restaurantById = "$apiBase/restaurants";

  // 👤 Users
  static String getUsers(String restaurantId, {int page = 1, int limit = 10}) {
    return "$apiBase/users?page=$page&limit=$limit&restaurantId=$restaurantId";
  }

  // 🍽 **Tables**
  static String getTables(String restaurantId, {int page = 1, int limit = 10}) {
    return "$apiBase/tables?page=$page&limit=$limit&restaurantId=$restaurantId";
  }

  // 🗂 **Categories**
  static String getCategories(String restaurantId) {
    return "$apiBase/categories?restaurantId=$restaurantId";
  }

  // 🍔 **Menu Items**
  static String getMenuItems(
    String restaurantId, {
    int page = 1,
    int limit = 10,
  }) {
    return "$apiBase/menu-items?page=$page&limit=$limit&restaurantId=$restaurantId";
  }

  // 🛒 Order Types
  static const String orderTypes = "$apiBase/order-types";

  // 🧾 **Orders**
  static const String createOrder = "$apiBase/bills/save";

  // 💰 **Tax Product Groups**
  static String getTaxProductGroups(
    String restaurantId, {
    int page = 1,
    int limit = 10,
  }) {
    return "$apiBase/tax-product-groups?page=$page&limit=$limit&restaurantId=$restaurantId";
  }
}
