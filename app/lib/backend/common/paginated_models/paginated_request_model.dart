import 'api_documents_paginated_list_model.dart';

class GetAPIDocumentsPaginatedListRequestModel<T> {
  final String baseUrl;
  final String endpoint;
  final Map<String, dynamic>? queryParams;
  final bool isRefresh;
  final bool isFromCache;
  final bool isNotify;
  final String dataListKey;
  final int? contentsDocumentLimitForPagination;
  final APIDocumentsPaginatedListModel<T> paginatedListModel;
  final T Function(Map<String, dynamic>) convertDataToContent;

  GetAPIDocumentsPaginatedListRequestModel({
    required this.baseUrl,
    required this.endpoint,
    this.queryParams,
    this.isRefresh = false,
    this.isFromCache = true,
    this.isNotify = true,
    this.dataListKey = 'data',
    this.contentsDocumentLimitForPagination,
    required this.paginatedListModel,
    required this.convertDataToContent,
  });
}
