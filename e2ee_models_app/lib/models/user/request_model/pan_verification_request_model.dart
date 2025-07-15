import '../../../utils/my_utils.dart';

class PanVerificationRequestsModel {
  String id;
  String userId;
  String? userName;
  String panNumber;
  String? nameAsPerPan;
  String? panImageUrl;
  String status;

  PanVerificationRequestsModel({
    required this.id,
    required this.userId,
    this.userName,
    required this.panNumber,
    this.nameAsPerPan,
    this.panImageUrl,
    this.status = "Pending",
  });

  Map<String, dynamic> toMap({bool toJson = false}) {
    return <String, dynamic>{
      "uniqueRequestId": id,
      "userId": userId,
      if (userName != null) "userName": userName,
      "panNumber": panNumber,
      if (nameAsPerPan != null) "nameAsPerPan": nameAsPerPan,
      if (panImageUrl != null) "panImageUrl": panImageUrl,
      "status": status,
    };
  }

  @override
  String toString() {
    return MyUtils.encodeJson(toMap(toJson: true));
  }
}