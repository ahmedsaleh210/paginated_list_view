import 'dart:developer';

import 'package:flutter/material.dart';

class PaginatedListView<T> extends StatefulWidget {
  final Widget Function(BuildContext context, int index, T item) itemBuilder;
  final Future<List<T>> Function(int pageNumber, int maxRows) onPageChanged;
  final Widget lastPageWidget;
  final Widget initialLoader;
  final Widget bottomLoader;
  final Widget Function(int pageNumber, int maxRows)? onError;
  final Widget? onEmpty;
  final bool shrinkWrap;
  final int initalPageNumber;
  final int maxRows;
  final ScrollPhysics? physics;

  const PaginatedListView(
      {Key? key,
      required this.itemBuilder,
      required this.onPageChanged,
      this.lastPageWidget = const SizedBox(),
      this.initialLoader = const CircularProgressIndicator(),
      this.bottomLoader = const CircularProgressIndicator(),
      this.onError,
      this.onEmpty,
      this.shrinkWrap = false,
      this.initalPageNumber = 1,
      this.physics,
      this.maxRows = 10})
      : super(key: key);

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _scrollController = ScrollController();
  int _pageNumber = 1;
  bool isLoading = false;
  bool _isInitPageLoading = false;
  bool _hasError = false;
  final List<T> _items = [];
  List<T> moreItems = [];
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    _initScrollController();
  }

  void _initScrollController() async {
    await _loadMoreData(isInitial: true);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreData();
      }
    });
  }

  Future<void> _loadMoreData({isInitial = false}) async {
    if (isInitial) {
      _isInitPageLoading = true;
    } else {
      if (isLoading || isLastPage) {
        return;
      }
      isLoading = true;
    }
    try {
      moreItems = await widget.onPageChanged(_pageNumber, widget.maxRows);
      log('${_items.length}');
      _items.addAll(moreItems);
      _pageNumber++;
      setState(() {
        if (isInitial) {
          _isInitPageLoading = false;
        } else {
          isLoading = false;
          if (moreItems.length < widget.maxRows) {
            isLastPage = true;
          }
        }
      });
    } catch (error) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(() {});
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitPageLoading) {
      return _items.isNotEmpty
          ? ListView.builder(
              physics: widget.physics ?? const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                if (index < _items.length) {
                  return widget.itemBuilder(context, index, _items[index]);
                }
                if (index == _items.length && !isLastPage && !_hasError) {
                  log("test");
                  return Center(
                    child: widget.bottomLoader,
                  );
                }
                if (_hasError) {
                  return widget.onError?.call(_pageNumber, widget.maxRows) ??
                      const SizedBox();
                }
                return null;
              },
              itemCount: _items.length + (isLastPage ? 0 : 1),
              controller: _scrollController,
              shrinkWrap: widget.shrinkWrap,
            )
          : widget.onEmpty ??
              const Center(
                child: Text('List is Empty!'),
              );
    } else {
      return Center(child: widget.initialLoader);
    }
  }
}
