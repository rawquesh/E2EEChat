import '../../core/state/common_provider.dart';

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
    contentsList = CommonProviderListParameter<T>(
      list: <T>[],
      notify: notify,
    );
    pageIndex = CommonProviderPrimitiveParameter<int>(
      value: initialPageIndex,
      notify: notify,
    );
    contentsDocumentLimitForPagination = CommonProviderPrimitiveParameter<int>(
      value: contentsDocumentLimit,
      notify: notify,
    );
    contentsDocumentRefreshLimitForPagination = CommonProviderPrimitiveParameter<int>(
      value: contentsDocumentRefreshLimit,
      notify: notify,
    );

    hasMoreContents = CommonProviderPrimitiveParameter<bool>(
      value: true,
      notify: notify,
    );
    isContentsFirstTimeLoading = CommonProviderPrimitiveParameter<bool>(
      value: false,
      notify: notify,
    );
    isContentsLoading = CommonProviderPrimitiveParameter<bool>(
      value: false,
      notify: notify,
    );
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
