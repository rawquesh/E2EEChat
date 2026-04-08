import '../common_provider.dart';
import 'data_paginated_list_model.dart';

class APIDocumentsPaginatedListModel<T> extends DataDocumentsPaginatedListModel<T> {
  late CommonProviderPrimitiveParameter<int> currentPage;
  late CommonProviderPrimitiveParameter<int> totalPages;

  APIDocumentsPaginatedListModel() {
    currentPage = CommonProviderPrimitiveParameter<int>(value: 0, notify: notify);
    totalPages = CommonProviderPrimitiveParameter<int>(value: 0, notify: notify);
  }

  @override
  void reset({bool isNotify = true}) {
    super.reset(isNotify: false);
    currentPage.set(value: 0, isNotify: false);
    totalPages.set(value: 0, isNotify: isNotify);
  }
}
