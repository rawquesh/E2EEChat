import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../configs/constants.dart';
import 'api_pagination.dart';
import '../my_print.dart';
import '../my_utils.dart';
import '../parsing_helper.dart';
import '../../utils/storage_manager.dart';

class APIController {
  static Future<Map<String, dynamic>> getAPIData({
    required String baseUrl,
    required String endpoint,
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
    Map<String, String>? customHeaders,
  }) async {
    final tag = MyUtils.getNewId();
    MyPrint.printOnConsole("GET API Started: $endpoint [Tag: $tag]", tag: tag);

    try {
      final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParams);

      final headers = customHeaders ??
          (includeAuth ? await _getHeadersWithAuth() : {'Content-Type': 'application/json'});

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        MyPrint.printOnConsole("GET Success [Tag: $tag]", tag: tag);
        MyPrint.printOnConsole("Get Api Response data: ${response.body}");
        return data is Map<String, dynamic> ? data : {'data': data};
      } else {
        MyPrint.printOnConsole("GET Failed: ${response.statusCode} [Tag: $tag]", tag: tag);
        throw Exception('Failed GET $endpoint');
      }
    } catch (e) {
      MyPrint.printOnConsole("Exception: $e [Tag: $tag]", tag: tag);
      rethrow;
    }
  }

  static Future<void> getAPIDocumentsPaginatedList<T>({
    required GetAPIDocumentsPaginatedListRequestModel<T> requestModel,
  }) async {
    final tag = MyUtils.getNewId();
    final paginatedListModel = requestModel.paginatedListModel;
    final limit = requestModel.contentsDocumentLimitForPagination ??
        paginatedListModel.contentsDocumentLimitForPagination.get();

    MyPrint.printOnConsole(
        "API Pagination Started for endpoint: ${requestModel.endpoint}, query: ${requestModel.queryParams}, isRefresh: ${requestModel.isRefresh} [Tag: $tag]",
        tag: tag);

    try {
      if (!requestModel.isRefresh && requestModel.isFromCache && paginatedListModel.contentsLength > 0) {
        MyPrint.printOnConsole("Returning cached data. [Tag: $tag]", tag: tag);
        return;
      }

      if (requestModel.isRefresh) {
        MyPrint.printOnConsole("Resetting pagination for refresh. [Tag: $tag]", tag: tag);
        paginatedListModel.reset(isNotify: false);
        paginatedListModel.hasMoreContents.set(value: true, isNotify: false);
        paginatedListModel.isContentsFirstTimeLoading.set(value: true, isNotify: requestModel.isNotify);
      }

      if (!paginatedListModel.hasMoreContents.get()) {
        MyPrint.printOnConsole("No more contents to fetch. [Tag: $tag]", tag: tag);
        _finalizeLoading(paginatedListModel, tag);
        return;
      }
      if (paginatedListModel.isContentsLoading.get()) {
        MyPrint.printOnConsole("Content is already loading. [Tag: $tag]", tag: tag);
        return;
      }

      paginatedListModel.isContentsLoading.set(value: true, isNotify: requestModel.isNotify);

      final currentPageToFetch = paginatedListModel.currentPage.get();
      final uri = Uri.parse(requestModel.baseUrl + requestModel.endpoint).replace(
        queryParameters: {
          ...requestModel.queryParams,
          'page': currentPageToFetch.toString(),
          'limit': limit.toString(),
        },
      );

      MyPrint.printOnConsole("Fetching URL: $uri [Tag: $tag]", tag: tag);
      final response = await http.get(uri, headers: await _getHeadersWithAuth());

      MyPrint.printOnConsole("API Response Status: ${response.statusCode} [Tag: $tag]", tag: tag);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData == null || responseData[requestModel.dataListKey] == null || responseData['pagination'] == null) {
          MyPrint.printOnConsole("Invalid API response structure. [Tag: $tag]", tag: tag);
          paginatedListModel.hasMoreContents.set(value: false, isNotify: false);
          _handleError("Invalid API response structure", paginatedListModel, tag, shouldResetList: requestModel.isRefresh);
          _finalizeLoading(paginatedListModel, tag);
          return;
        }

        final List<dynamic> rawDataList = responseData[requestModel.dataListKey];
        final Map<String, dynamic> paginationData = responseData['pagination'];

        final List<T> parsedDataList = rawDataList
            .map((data) => requestModel.convertDataToContent(ParsingHelper.parseMapMethod(data)))
            .whereType<T>()
            .toList();

        final int currentPageFromAPI = ParsingHelper.parseIntMethod(paginationData['page']);
        final int totalPagesFromAPI = ParsingHelper.parseIntMethod(paginationData['totalPages']);
        final bool hasMoreBasedOnResponse = currentPageFromAPI < totalPagesFromAPI;
        final int nextPageToSet = hasMoreBasedOnResponse ? currentPageFromAPI + 1 : currentPageFromAPI;

        paginatedListModel.currentPage.set(value: nextPageToSet, isNotify: false);
        paginatedListModel.totalPages.set(value: totalPagesFromAPI, isNotify: false);
        paginatedListModel.hasMoreContents.set(value: hasMoreBasedOnResponse, isNotify: false);

        if (requestModel.isRefresh) {
          paginatedListModel.contentsList.setList(list: parsedDataList, isClear: true, isNotify: requestModel.isNotify);
        } else {
          final currentList = paginatedListModel.contentsList.getList();
          paginatedListModel.contentsList.setList(list: [...currentList, ...parsedDataList], isClear: false, isNotify: requestModel.isNotify);
        }

        MyPrint.printOnConsole("Page $currentPageFromAPI/$totalPagesFromAPI loaded. Items: ${parsedDataList.length}. [Tag: $tag]", tag: tag);
      } else {
        MyPrint.printOnConsole("API Error: ${response.statusCode}. [Tag: $tag]", tag: tag);
        _handleError("API Error: ${response.statusCode}", paginatedListModel, tag, shouldResetList: requestModel.isRefresh);
      }
    } catch (e, s) {
      MyPrint.printOnConsole("Exception during API call: $e [Tag: $tag]", tag: tag);
      MyPrint.printOnConsole(s, tag: tag);
      _handleError(e, paginatedListModel, tag, shouldResetList: requestModel.isRefresh);
    } finally {
      _finalizeLoading(paginatedListModel, tag);
    }
  }

  static Future<Map<String, String>> _getHeadersWithAuth() async {
    return {
      'Authorization': 'Bearer ${await SharedPrefManager().getString(MySharedPreferenceVariables.authToken)}',
      'Content-Type': 'application/json',
    };
  }

  static void _handleError<T>(Object error, APIDocumentsPaginatedListModel<T> model, String tag, {bool shouldResetList = false}) {
    MyPrint.printOnConsole("Error encountered: ${error.toString()} [Tag: $tag]", tag: tag);
    if (shouldResetList) {
      model.contentsList.setList(list: [], isClear: true, isNotify: false);
    }
    model.hasMoreContents.set(value: true, isNotify: false);
    model.currentPage.set(value: model.currentPage.get(), isNotify: false);
  }

  static void _finalizeLoading<T>(APIDocumentsPaginatedListModel<T> model, String tag) {
    if (model.isContentsFirstTimeLoading.get()) {
      model.isContentsFirstTimeLoading.set(value: false, isNotify: false);
    }
    if (model.isContentsLoading.get()) {
      model.isContentsLoading.set(value: false, isNotify: false);
    }
    MyPrint.printOnConsole("API Pagination Flow Completed [Tag: $tag]", tag: tag);
  }
}
