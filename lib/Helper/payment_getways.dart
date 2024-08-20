import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../Screen/Splash.dart';

class PhonePeHelper {
  String environmentValue = 'PRODUCTION'; //'SANDBOX'
  String packageName = "com.formbuxx.user"; //"com.phonepe.simulator"; //
  // String packageName = "com.eatozfood_user"; //"com.phonepe.simulator"; //
  Object? result;
  String appId = "";
  // final phonePemerchantId = "SANDLEATOZONLINE"; //"SANDLEATOZONLINE";
  final phonePemerchantId = "FARMBUZCROPONLINE"; //"SANDLEATOZONLINE";
  bool enableLogs = true;
  String? orderId;
  String amount;
  String callBackUrl =
      "https://webhook.site/49a2ee2b-f36b-4efe-a5a0-b1d9ac473aa6";
  String checksum = '';
  final apiEndPoint = "/pg/v1/pay";
  final saltkey =
      "919b2197-6472-488c-9fbb-8c1e9b048a99"; //"c4205b43-9dcc-49d9-85d3-96ceececda73";
  //   "c4205b43-9dcc-49d9-85d3-96ceececda73"; //"c4205b43-9dcc-49d9-85d3-96ceececda73";

  final saltIndex = "1";
  String body = '';

  ValueChanged onResult;

  PhonePeHelper(this.amount, this.onResult);
//"com.phonepe.simulator";

  void initPhonePeSdk() {
    PhonePePaymentSdk.init(
            environmentValue, appId, phonePemerchantId, enableLogs)
        .then((isInitialized) =>
            {result = 'PhonePe SDK Initialized - $isInitialized'})
        .catchError((error) {
      handleError(error);
      return <dynamic>{};
    });
    body = getChecksum().toString();
    startTransaction();
  }

  void handleError(error) {
    if (error is Exception) {
      result = error.toString();
    } else {
      result = {"error": error};
    }
  }

  getChecksum() {
    // SharedPreferences preferences = await SharedPreferences.getInstance();
    // mobile = preferences.getString("mobile");
    orderId = DateTime.now().millisecondsSinceEpoch.toString();
    transactionId = orderId.toString();
    final requestData = {
      "merchantId": phonePemerchantId,
      "merchantTransactionId": orderId,
      "merchantUserId": 'tf_525256',
      "amount": (100 * double.parse(amount)).toInt(),
      "callbackUrl": callBackUrl,
      "mobileNumber": '9685768623',
      "paymentInstrument": {"type": "PAY_PAGE"}
    };

    String base64Body = base64.encode(utf8.encode(json.encode(requestData)));
    checksum =
        "${sha256.convert(utf8.encode(base64Body + apiEndPoint + saltkey)).toString()}###$saltIndex";

    return base64Body;
  }

  Future<void> startTransaction() async {
    try {
      PhonePePaymentSdk.startTransaction(
              body, callBackUrl, checksum, packageName)
          .then((response) {
        if (response != null) {
          String status = response['status'].toString();
          String error = response['error'].toString();
          if (status == 'SUCCESS') {
            result = "Transaction Completion Successful!";
            checkPhonePeTransactionApi();

            //Navigator.popAndPushNamed(context, Routes.paymentSuccessful);
          } else {
            result =
                "Transaction Completion >> Status >> $status and Error >> $error";
            onResult("error");
          }
        } else {
          result = "Transaction Incomplete";
        }
      }).catchError((error) {
        handleError(error);
      });
    } catch (error) {
      handleError(error);
    }
  }

  Future<void> checkPhonePeTransactionApi() async {
    String concate = "/pg/v1/status/$phonePemerchantId/$orderId$saltkey";
    var bytes = utf8.encode(concate);

    var digest = sha256.convert(bytes).toString();
    String xVerify = "$digest###$saltIndex";

    var headers = {
      'Content-Type': 'application/json',
      'X-VERIFY': xVerify,
      'X-MERCHANT-ID': phonePemerchantId
    };

    var request = http.Request(
        'GET',
        Uri.parse(
            'https://api.phonepe.com/apis/hermes/pg/v1/status/$phonePemerchantId/$orderId'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    print('${request.url}');

    if (response.statusCode == 200) {
      var result = await response.stream.bytesToString();
      var finalResult = jsonDecode(result);
      try {
        if (finalResult['success'] &&
            finalResult['code'] == "PAYMENT_SUCCESS" &&
            finalResult['data']['state'] == 'COMPLETED') {
          Fluttertoast.showToast(msg: finalResult['message']);

          onResult("SUCCESS");
        } else {
          Fluttertoast.showToast(msg: finalResult['message']);
          onResult("error");
        }
      } catch (e) {}
    } else {
      print(response.reasonPhrase);
      onResult("error");
    }
  }
}

// import 'dart:convert';
// import 'dart:math';
//
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
// import 'package:crypto/crypto.dart';
// import 'package:http/http.dart' as http;
//
// class PhonePeHelper {
//   String environmentValue = 'PRODUCTION'; //'SANDBOX'
//   String packageName = "com.formbuxx.user"; //"com.phonepe.simulator"; //
//   Object? result;
//   String appId = "";
//   final phonePemerchantId = "M18BHEFW0OG1"; //"SANDLEATOZONLINE";
//   bool enableLogs = true;
//   String? orderId;
//   String amount;
//   String callBackUrl =
//       "https://webhook.site/ec0dc0bd-d8de-47fe-9776-fa2f9560692f";
//   // "https://webhook.site/831e128f-38c3-481c-9a26-429d75b64168";
//   String checksum = '';
//   final apiEndPoint = "/pg/v1/pay";
//   final saltkey =
//       "831e128f-38c3-481c-9a26-429d75b64168"; //"c4205b43-9dcc-49d9-85d3-96ceececda73";
//
//   final saltIndex = "1";
//   String body = '';
//
//   ValueChanged onResult;
//
//   PhonePeHelper(this.amount, this.onResult);
// //"com.phonepe.simulator";
//
//   void initPhonePeSdk() {
//     PhonePePaymentSdk.init(
//             environmentValue, appId, phonePemerchantId, enableLogs)
//         .then((isInitialized) {
//       print("object isInitialized $isInitialized");
//       return {result = 'PhonePe SDK Initialized - $isInitialized'};
//     }).catchError((error) {
//       print("object Error Ankueh $error");
//       handleError(error);
//       return <dynamic>{};
//     });
//     body = getChecksum().toString();
//     startTransaction();
//   }
//
//   void handleError(error) {
//     if (error is Exception) {
//       print("Ankush Response $error");
//       result = error.toString();
//     } else {
//       result = {"error": error};
//     }
//   }
//
//   getChecksum() {
//     int min = 10;
//     int max = 20;
//     int randomIntInRange = Random().nextInt(max - min) + min;
//     // SharedPreferences preferences = await SharedPreferences.getInstance();
//     // mobile = preferences.getString("mobile");
//     orderId = DateTime.now().millisecondsSinceEpoch.toString();
//     final requestData = {
//       "merchantId": phonePemerchantId,
//       "merchantTransactionId": orderId,
//       "merchantUserId": 'tf_52525623ggs$randomIntInRange',
//       "amount": (100 * double.parse("1")).toInt(),
//       "callbackUrl": callBackUrl,
//       "mobileNumber": '8718899890',
//       'packageName': packageName,
//       "paymentInstrument": {"type": "PAY_PAGE"}
//     };
//
//     String base64Body = base64.encode(utf8.encode(json.encode(requestData)));
//     checksum =
//         "${sha256.convert(utf8.encode(base64Body + apiEndPoint + saltkey)).toString()}###$saltIndex";
//     print("object CheckSum $checksum");
//     return base64Body;
//   }
//
//   Future<void> startTransaction() async {
//     try {
//       print("Ankush Response body $body");
//       PhonePePaymentSdk.startTransaction(
//               body, callBackUrl, checksum, packageName)
//           .then((response) {
//         print("Ankush Response response $response");
//         if (response != null) {
//           String status = response['status'].toString();
//           String error = response['error'].toString();
//           if (status == 'SUCCESS') {
//             print("Ankush Response $response");
//             result = "Transaction Completion Successful!";
//             checkPhonePeTransactionApi();
//
//             //Navigator.popAndPushNamed(context, Routes.paymentSuccessful);
//           } else {
//             result =
//                 "Transaction Completion >> Status >> $status and Error >> $error";
//             onResult("error");
//           }
//         } else {
//           result = "Transaction Incomplete";
//         }
//       }).catchError((error) {
//         handleError(error);
//       });
//     } catch (error) {
//       handleError(error);
//     }
//   }
//
//   Future<void> checkPhonePeTransactionApi() async {
//     String concate = "/pg/v1/status/$phonePemerchantId/$orderId$saltkey";
//     var bytes = utf8.encode(concate);
//
//     var digest = sha256.convert(bytes).toString();
//     String xVerify = "$digest###$saltIndex";
//
//     var headers = {
//       'Content-Type': 'application/json',
//       'X-VERIFY': xVerify,
//       'X-MERCHANT-ID': phonePemerchantId
//     };
//
//     var request = http.Request(
//         'GET',
//         Uri.parse(
//             'https://api.phonepe.com/apis/hermes/pg/v1/status/$phonePemerchantId/$orderId'));
//
//     request.headers.addAll(headers);
//
//     http.StreamedResponse response = await request.send();
//
//     print('${request.url}');
//
//     if (response.statusCode == 200) {
//       var result = await response.stream.bytesToString();
//       var finalResult = jsonDecode(result);
//       try {
//         print("Ankush Response Two $finalResult");
//         if (finalResult['success'] &&
//             finalResult['code'] == "PAYMENT_SUCCESS" &&
//             finalResult['data']['state'] == 'COMPLETED') {
//           Fluttertoast.showToast(msg: finalResult['message']);
//
//           onResult("SUCCESS");
//         } else {
//           Fluttertoast.showToast(msg: finalResult['message']);
//           onResult("error");
//         }
//       } catch (e) {}
//     } else {
//       print(response.reasonPhrase);
//       onResult("error");
//     }
//   }
// }
