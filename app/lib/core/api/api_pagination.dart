import '../state/common_provider.dart';

class DataDocumentsPaginatedListModel<T> extends CommonProvider {
  late CommonProviderListParameter<T> contentsList;

  int get contentsLength => contentsList.length;

  late CommonProviderPrimitiveParameter<int> pageIndex;
  late CommonProviderPrimitiveParameter<int> contentsDocumentLimitForPagination;
  late CommonProviderPrimitiveParameter<int> contentsDocumentRefreshLimitForPagination;
  late CommonProviderPrimitiveParameter<bool> hasMoreContents;
  late CommonProviderPrimitiveParameter<bool> isContentsFirstTimeLoading;
  late CommonProviderPrimitiveParameter<bool> isContentsLoading;

  int initialPageIndex = 0;
  int contentsDocumentLimit = 10;
  int contentsDocumentRefreshLimit = 3;

  DataDocumentsPaginatedListModel({this.contentsDocumentLimit = 10, this.contentsDocumentRefreshLimit = 3, this.initialPageIndex = 0}) {
    contentsList = CommonProviderListParameter<T>(list: <T>[], notify: notify);
    pageIndex = CommonProviderPrimitiveParameter<int>(value: initialPageIndex, notify: notify);
    contentsDocumentLimitForPagination = CommonProviderPrimitiveParameter<int>(value: contentsDocumentLimit, notify: notify);
    contentsDocumentRefreshLimitForPagination = CommonProviderPrimitiveParameter<int>(value: contentsDocumentRefreshLimit, notify: notify);
    hasMoreContents = CommonProviderPrimitiveParameter<bool>(value: true, notify: notify);
    isContentsFirstTimeLoading = CommonProviderPrimitiveParameter<bool>(value: false, notify: notify);
    isContentsLoading = CommonProviderPrimitiveParameter<bool>(value: false, notify: notify);
  }

  void setContentsDocumentLimitForPagination({int value = 10, bool isNotify = false}) {
    contentsDocumentLimit = value;
    contentsDocumentLimitForPagination.set(value: value, isNotify: isNotify);
  }

  void setContentsDocumentRefreshLimitForPagination({int value = 3, bool isNotify = false}) {
    contentsDocumentRefreshLimit = value;
    contentsDocumentRefreshLimitForPagination.set(value: value, isNotify: isNotify);
  }

  void reset({bool isNotify = true}) {
    contentsList.setList(list: <T>[], isClear: true, isNotify: false);
    pageIndex.set(value: initialPageIndex, isNotify: false);
    contentsDocumentLimitForPagination.set(value: contentsDocumentLimit, isNotify: false);
    contentsDocumentRefreshLimitForPagination.set(value: contentsDocumentRefreshLimit, isNotify: false);
    hasMoreContents.set(value: true, isNotify: false);
    isContentsFirstTimeLoading.set(value: false, isNotify: false);
    isContentsLoading.set(value: false, isNotify: isNotify);
  }
}

class APIDocumentsPaginatedListModel<T> extends DataDocumentsPaginatedListModel<T> {
  late CommonProviderPrimitiveParameter<int> currentPage;
  late CommonProviderPrimitiveParameter<int> totalPages;

  APIDocumentsPaginatedListModel({
    super.contentsDocumentLimit = 10,
    super.contentsDocumentRefreshLimit = 3,
    super.initialPageIndex = 1,
  }) {
    currentPage = CommonProviderPrimitiveParameter<int>(value: initialPageIndex, notify: notify);
    totalPages = CommonProviderPrimitiveParameter<int>(value: 1, notify: notify);
  }

  @override
  void reset({bool isNotify = true}) {
    super.reset(isNotify: false);
    currentPage.set(value: initialPageIndex, isNotify: false);
    totalPages.set(value: 1, isNotify: false);
    if (isNotify) notify();
  }
}

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
