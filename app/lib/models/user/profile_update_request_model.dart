import '../../core/my_utils.dart';

class ProfileUpdateRequestModel {
  String? displayName;
  String? email;
  String? countryOfResidence;
  String? gender;
  String? genderPreference;

  ProfileUpdateRequestModel({
    this.displayName,
    this.email,
    this.countryOfResidence,
    this.gender,
    this.genderPreference,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
      if (countryOfResidence != null) 'countryOfResidence': countryOfResidence,
      if (gender != null) 'gender': gender,
      if (genderPreference != null) 'genderPreference': genderPreference,
    };
  }

  @override
  String toString() {
    return MyUtils.encodeJson(toMap());
  }
}
