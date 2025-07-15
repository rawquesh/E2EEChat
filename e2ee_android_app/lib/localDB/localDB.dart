import 'package:shared_preferences/shared_preferences.dart';

class LocalDB {
  final userIDKey = "dsjnsbhsjfdknefhj";
  final userNameKey = "dfkdgjurwjnfjadsnh";
  final userAgeKey = "dnjfsnsdfnjn";
  final userEmailKey = "fkdknjbfvnxmefjhv";
  final userMobileNumberKey = "fmkdfjdnsjnjabdsj";
  final userGenderKey = "dfdfdsknmjfjnnj";

  //userID
  Future<bool> saveUserID(String userID) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.setString(userIDKey, userID);
  }

  Future<String?> getUserID() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString(userIDKey);
  }

  Future<bool> removeUserID() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.remove(userIDKey);
  }

  // userName
  Future<bool> saveUserName(String userName) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.setString(userNameKey, userName);
  }

  Future<String?> getUserName() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString(userNameKey);
  }

  Future<bool> removeUserName() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.remove(userNameKey);
  }

  // userAge
  Future<bool> saveUserAge(int userAge) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.setInt(userAgeKey, userAge);
  }

  Future<int?> getUserAge() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getInt(userAgeKey);
  }

  Future<bool> removeUserAge() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.remove(userAgeKey);
  }

  // userEmail
  Future<bool> saveUserEmail(String userEmail) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.setString(userEmailKey, userEmail);
  }

  Future<String?> getUserEmail() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString(userEmailKey);
  }

  Future<bool> removeUserEmail() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.remove(userEmailKey);
  }

  // userMobile Number
  Future<bool> saveUserMobile(String userMobNum) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.setString(userMobileNumberKey, userMobNum);
  }

  Future<String?> getUserMobile() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString(userMobileNumberKey);
  }

  Future<bool> removeUserMobile() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.remove(userMobileNumberKey);
  }

  // Gender
  Future<bool> saveUserGender(String userGender) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.setString(userGenderKey, userGender);
  }

  Future<String?> getUserGender() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString(userGenderKey);
  }

  Future<bool> removeUserGender() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.remove(userGenderKey);
  }
}
