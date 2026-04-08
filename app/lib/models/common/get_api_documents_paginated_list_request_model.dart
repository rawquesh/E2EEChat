import 'api_documents_paginated_list_model.dart';

class GetAPIDocumentsPaginatedListRequestModel<T> {
  final APIDocumentsPaginatedListModel<T> paginatedListModel;
  final String baseUrl;
  final String endpoint;
  final Map<String, dynamic> queryParams;
  final int? contentsDocumentLimitForPagination;
  final bool isRefresh;
  final bool isFromCache;
  final bool isNotify;
  final String dataListKey;
  final T? Function(Map<String, dynamic> data) convertDataToContent;

  GetAPIDocumentsPaginatedListRequestModel({
    required this.paginatedListModel,
    required this.baseUrl,
    required this.endpoint,
    required this.dataListKey,
    this.queryParams = const {},
    this.contentsDocumentLimitForPagination,
    this.isRefresh = true,
    this.isFromCache = false,
    this.isNotify = true,
    required this.convertDataToContent,
  });
}
