import '../../../utils/my_utils.dart';
import '../../../utils/parsing_helper.dart';

class UserModel {
  String userId;
  String firstName;
  String lastName;
  String displayName;
  String mobileNumber;
  String email;
  String password;
  String notificationToken;
  String profilePicture;
  String profileCover;
  String gender;
  String authenticationMode;
  int age;
  bool enabled;
  bool isDeleted;
  String country;
  String preferredContentGender;
  bool isCreator;
  String creatorUsername;
  String contentVisibleTo;
  String creatorCategory;
  String creatorHeadline;
  String creatorStatus;
  bool hasCompletedStripeOnboarding;
  String bio;
  String introVideoUrl;

  UserModel({
    this.userId = "",
    this.firstName = "",
    this.lastName = "",
    this.displayName = "",
    this.mobileNumber = "",
    this.email = "",
    this.password = "",
    this.notificationToken = "",
    this.profilePicture = "",
    this.profileCover = "",
    this.gender = "",
    this.authenticationMode = "",
    this.age = 0,
    this.enabled = true,
    this.isDeleted = false,
    this.country = "",
    this.preferredContentGender = "",
    this.isCreator = false,
    this.creatorUsername = "",
    this.contentVisibleTo = "",
    this.creatorCategory = "",
    this.creatorHeadline = "",
    this.creatorStatus = "",
    this.hasCompletedStripeOnboarding = false,
    this.bio = "",
    this.introVideoUrl = "",
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: ParsingHelper.parseStringMethod(map["_id"]),
      firstName: ParsingHelper.parseStringMethod(map["firstName"]),
      lastName: ParsingHelper.parseStringMethod(map["lastName"]),
      displayName:
      "${ParsingHelper.parseStringMethod(map["firstName"])} ${ParsingHelper.parseStringMethod(map["lastName"])}".trim(),
      mobileNumber: ParsingHelper.parseStringMethod(map["mobileNumber"]),
      email: ParsingHelper.parseStringMethod(map["email"]),
      password: ParsingHelper.parseStringMethod(map["password"]),
      notificationToken: ParsingHelper.parseStringMethod(map["notificationToken"]),
      profilePicture: ParsingHelper.parseStringMethod(map["profilePicture"]),
      profileCover: ParsingHelper.parseStringMethod(map["profileCover"]),
      gender: ParsingHelper.parseStringMethod(map["gender"]),
      authenticationMode: ParsingHelper.parseStringMethod(map["authenticationMode"]),
      age: ParsingHelper.parseIntMethod(map["age"]),
      enabled: ParsingHelper.parseBoolMethod(map["enabled"]),
      isDeleted: ParsingHelper.parseBoolMethod(map["isDeleted"]),
      country: ParsingHelper.parseStringMethod(map["countryOfResidence"]),
      preferredContentGender: ParsingHelper.parseStringMethod(map["genderPreference"]),
      isCreator: ParsingHelper.parseBoolMethod(map["isCreator"]),
      creatorUsername: ParsingHelper.parseStringMethod(map["creatorUsername"]),
      contentVisibleTo: ParsingHelper.parseStringMethod(map["contentVisibleTo"]),
      creatorCategory: ParsingHelper.parseStringMethod(map["creatorCategory"]),
      creatorHeadline: ParsingHelper.parseStringMethod(map["creatorHeadline"]),
      creatorStatus: ParsingHelper.parseStringMethod(map["creatorStatus"]),
      hasCompletedStripeOnboarding: ParsingHelper.parseBoolMethod(map["hasCompletedStripeOnboarding"]),
      bio: ParsingHelper.parseStringMethod(map["bio"]),
      introVideoUrl: ParsingHelper.parseStringMethod(map["introVideoUrl"]),
    );
  }

  void updateFromMap(Map<String, dynamic> map) {
    final updated = UserModel.fromMap(map);
    userId = updated.userId;
    firstName = updated.firstName;
    lastName = updated.lastName;
    displayName = updated.displayName;
    mobileNumber = updated.mobileNumber;
    email = updated.email;
    password = updated.password;
    notificationToken = updated.notificationToken;
    profilePicture = updated.profilePicture;
    profileCover = updated.profileCover;
    gender = updated.gender;
    authenticationMode = updated.authenticationMode;
    age = updated.age;
    enabled = updated.enabled;
    isDeleted = updated.isDeleted;
    country = updated.country;
    preferredContentGender = updated.preferredContentGender;
    isCreator = updated.isCreator;
    creatorUsername = updated.creatorUsername;
    contentVisibleTo = updated.contentVisibleTo;
    creatorCategory = updated.creatorCategory;
    creatorHeadline = updated.creatorHeadline;
    creatorStatus = updated.creatorStatus;
    hasCompletedStripeOnboarding = updated.hasCompletedStripeOnboarding;
    bio = updated.bio;
    introVideoUrl = updated.introVideoUrl;
  }

  Map<String, dynamic> toMap({bool toJson = false}) {
    return {
      "id": userId,
      "firstName": firstName,
      "lastName": lastName,
      "displayName": displayName,
      "mobileNumber": mobileNumber,
      "email": email,
      "password": password,
      "notificationToken": notificationToken,
      "profilePicture": profilePicture,
      "profileCover": profileCover,
      "gender": gender,
      "authenticationMode": authenticationMode,
      "age": age,
      "enabled": enabled,
      "isDeleted": isDeleted,
      "country": country,
      "preferredContentGender": preferredContentGender,
      "isCreator": isCreator,
      "creatorUsername": creatorUsername,
      "contentVisibleTo": contentVisibleTo,
      "creatorCategory": creatorCategory,
      "creatorHeadline": creatorHeadline,
      "creatorStatus": creatorStatus,
      "hasCompletedStripeOnboarding": hasCompletedStripeOnboarding,
      "bio": bio,
      "introVideoUrl": introVideoUrl,
    };
  }

  @override
  String toString() {
    return MyUtils.encodeJson(toMap(toJson: true));
  }
}
