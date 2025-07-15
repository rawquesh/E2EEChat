import '../../../backend/common/common_provider.dart';
import 'data_paginated_list_model.dart';

class APIDocumentsPaginatedListModel<T> extends DataDocumentsPaginatedListModel<T> {
  late CommonProviderPrimitiveParameter<int> currentPage;
  late CommonProviderPrimitiveParameter<int> totalPages;

  APIDocumentsPaginatedListModel({
    super.contentsDocumentLimit = 10,
    super.contentsDocumentRefreshLimit = 3,
    super.initialPageIndex = 1,
  }) {
    currentPage = CommonProviderPrimitiveParameter<int>(
      value: initialPageIndex,
      notify: notify,
    );
    totalPages = CommonProviderPrimitiveParameter<int>(
      value: 1,
      notify: notify,
    );
  }

  @override
  void reset({bool isNotify = true}) {
    super.reset(isNotify: false);
    currentPage.set(value: initialPageIndex, isNotify: false);
    totalPages.set(value: 1, isNotify: false);
    if (isNotify) notify();
  }
}
