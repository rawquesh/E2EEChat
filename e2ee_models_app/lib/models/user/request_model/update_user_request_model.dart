import '../../../utils/my_utils.dart';
import '../data_model/user_model.dart';

class UpdateUserRequestModel {
  String userId;
  UserModel? userModel;
  Map<String, dynamic>? userDataMap;

  UpdateUserRequestModel({
    required this.userId,
    this.userModel,
    this.userDataMap,
  });

  Map<String, dynamic> toMap({bool toJson = true}) {
    return <String, dynamic>{
      "userId": userId,
      "userModel": userModel?.toMap(toJson: toJson),
      "userDataMap": toJson
          ? userDataMap?.map((key, value) {

        return MapEntry<String, dynamic>(key, value);
      })
          : userDataMap,
    };
  }

  @override
  String toString() {
    return MyUtils.encodeJson(toMap(toJson: true));
  }
}