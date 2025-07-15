import '../../../utils/my_utils.dart';

class BankVerificationRequestsModel {
  String id;
  String userId;
  String? userName;
  String ifscCode;
  String bankAccountNumber;
  String status;
  String? bankProofImageUrl;

  BankVerificationRequestsModel({
    required this.id,
    required this.userId,
    this.userName,
    required this.ifscCode,
    required this.bankAccountNumber,
    this.status = "Pending",
    this.bankProofImageUrl,
  });

  Map<String, dynamic> toMap({bool toJson = false}) {
    return <String, dynamic>{
      "id": id,
      "userId": userId,
      if (userName != null) "userName": userName,
      "ifscCode": ifscCode,
      "bankAccountNumber": bankAccountNumber,
      "status": status,
      if (bankProofImageUrl != null) "bankProofImageUrl": bankProofImageUrl,
    };
  }

  @override
  String toString() {
    return MyUtils.encodeJson(toMap(toJson: true));
  }
}
