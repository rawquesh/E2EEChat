import '../common_provider.dart';

class DataDocumentsPaginatedListModel<T> extends CommonProvider {
  late CommonProviderListParameter<T> contentsList;
  late CommonProviderPrimitiveParameter<int> pageIndex;
  late CommonProviderPrimitiveParameter<int> contentsDocumentLimitForPagination;
  late CommonProviderPrimitiveParameter<bool> hasMoreContents;
  late CommonProviderPrimitiveParameter<bool> isContentsFirstTimeLoading;
  late CommonProviderPrimitiveParameter<bool> isContentsLoading;

  DataDocumentsPaginatedListModel() {
    contentsList = CommonProviderListParameter<T>(list: <T>[], notify: notify);
    pageIndex = CommonProviderPrimitiveParameter<int>(value: 0, notify: notify);
    contentsDocumentLimitForPagination = CommonProviderPrimitiveParameter<int>(value: 10, notify: notify);
    hasMoreContents = CommonProviderPrimitiveParameter<bool>(value: true, notify: notify);
    isContentsFirstTimeLoading = CommonProviderPrimitiveParameter<bool>(value: false, notify: notify);
    isContentsLoading = CommonProviderPrimitiveParameter<bool>(value: false, notify: notify);
  }

  int get contentsLength => contentsList.length;

  void reset({bool isNotify = true}) {
    contentsList.clear(isNotify: false);
    pageIndex.set(value: 0, isNotify: false);
    hasMoreContents.set(value: true, isNotify: false);
    isContentsFirstTimeLoading.set(value: false, isNotify: false);
    isContentsLoading.set(value: false, isNotify: isNotify);
  }
}
