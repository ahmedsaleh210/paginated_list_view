import 'dart:developer';
import 'package:flutter/material.dart';

class PaginatedListView<T> extends StatefulWidget {
  final Widget Function(BuildContext context, int index, T item) itemBuilder;
  final Future<List<T>> Function(int pageNumber, int maxRows) onPageChanged;
  final Widget? onEnd;
  final Widget initialLoader;
  final Widget bottomLoader;
  final Widget Function(int pageNumber, int maxRows)? onError;
  final Widget? onEmpty;
  final bool shrinkWrap;
  final int initalPageNumber;
  final int maxRows;
  final ScrollPhysics? physics;

  const PaginatedListView({
    Key? key,
    required this.itemBuilder,
    required this.onPageChanged,
    this.onEnd,
    this.initialLoader = const CircularProgressIndicator(),
    this.bottomLoader = const CircularProgressIndicator(),
    this.onError,
    this.onEmpty,
    this.shrinkWrap = false,
    this.initalPageNumber = 1,
    this.physics,
    this.maxRows = 10,
  }) : super(key: key);

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  late ScrollController _scrollController;
  late int _pageNumber;
  bool isLoading = false;
  bool _isInitPageLoading = false;
  bool _hasError = false;
  final List<T> _items = [];
  List<T> moreItems = [];
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pageNumber = widget.initalPageNumber;
    _initScrollController();
    _loadInitialData();
  }

  void _initScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.98) {
        _loadMoreData();
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isInitPageLoading = true;
    });

    try {
      moreItems = await widget.onPageChanged(_pageNumber, widget.maxRows);
      log('${_items.length}');
      _items.addAll(moreItems);
      _pageNumber++;
      setState(() {
        _isInitPageLoading = false;
      });
    } catch (error) {
      setState(() {
        _hasError = true;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (isLoading || isLastPage) {
      return;
    }
    isLoading = true;

    try {
      moreItems = await widget.onPageChanged(_pageNumber, widget.maxRows);
      log('${_items.length}');
      _items.addAll(moreItems);
      _pageNumber++;
      setState(() {
        isLoading = false;
        if (moreItems.length < widget.maxRows) {
          isLastPage = true;
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
    if (_isInitPageLoading) {
      return Center(child: widget.initialLoader);
    } else if (_items.isNotEmpty) {
      return ListView.builder(
        physics: widget.physics ?? const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          if (index < _items.length) {
            return widget.itemBuilder(context, index, _items[index]);
          } else if (index == _items.length && !isLastPage && !_hasError) {
            return Center(
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: widget.bottomLoader),
            );
          } else if (_hasError) {
            return widget.onError?.call(_pageNumber, widget.maxRows) ??
                const SizedBox();
          } else if (isLastPage) {
            return widget.onEnd;
          }
          return null;
        },
        itemCount: _items.length +
            (isLastPage
                ? widget.onEnd != null
                    ? 1
                    : 0
                : 1),
        controller: _scrollController,
        shrinkWrap: widget.shrinkWrap,
      );
    } else {
      return widget.onEmpty ?? const Center(child: Text('List is Empty!'));
    }
  }
}
