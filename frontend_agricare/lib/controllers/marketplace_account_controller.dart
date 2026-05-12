import 'package:get/get.dart';

import '../api/api_config.dart';
import '../services/marketplace_service.dart';

class MarketplaceAccountController extends GetxController {
  MarketplaceAccountController({MarketplaceService? service})
      : _service = service ?? MarketplaceService(baseUrl: ApiConfig.apiV1Base);

  final MarketplaceService _service;

  final RxnBool haveMarketplaceAccount = RxnBool();
  final RxBool isChecking = false.obs;
  final RxString errorMessage = ''.obs;

  bool _checkedOnce = false;
  Future<void>? _inFlight;

  bool get isResolved => haveMarketplaceAccount.value != null;

  Future<void> ensureChecked({bool force = false}) {
    if (!force && _checkedOnce && haveMarketplaceAccount.value == true) {
      return Future.value();
    }

    if (!force && _checkedOnce && haveMarketplaceAccount.value == false) {
      return Future.value();
    }

    if (_inFlight != null) return _inFlight!;

    errorMessage.value = '';
    isChecking.value = true;

    _inFlight = _service
        .checkMarketplaceAccount()
        .then((hasAccount) {
          haveMarketplaceAccount.value = hasAccount;
          _checkedOnce = true;
        })
        .catchError((e) {
          errorMessage.value = e.toString().replaceAll('Exception: ', '');
        })
        .whenComplete(() {
          isChecking.value = false;
          _inFlight = null;
        });

    return _inFlight!;
  }

  void setHaveMarketplaceAccount(bool value) {
    haveMarketplaceAccount.value = value;
    _checkedOnce = true;
    errorMessage.value = '';
    isChecking.value = false;
  }

  void invalidate() {
    _checkedOnce = false;
    haveMarketplaceAccount.value = null;
    errorMessage.value = '';
    isChecking.value = false;
  }
}
