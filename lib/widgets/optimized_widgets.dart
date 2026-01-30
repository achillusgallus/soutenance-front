import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:togoschool/core/cache/cache_manager.dart';

class OptimizedListView extends StatefulWidget {
  final List<dynamic> items;
  final Widget Function(BuildContext context, dynamic item, int index) itemBuilder;
  final ScrollController? controller;
  final bool shrinkWrap;
  final EdgeInsets? padding;
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.shrinkWrap = false,
    this.padding,
    this.separatorBuilder,
  });

  @override
  State<OptimizedListView> createState() => _OptimizedListViewState();
}

class _OptimizedListViewState extends State<OptimizedListView> {
  final _visibleItems = <int>{};

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: widget.controller,
      shrinkWrap: widget.shrinkWrap,
      padding: widget.padding,
      itemCount: widget.items.length,
      separatorBuilder: widget.separatorBuilder ?? (_, __) => const SizedBox(),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final key = ValueKey(item.hashCode);
        
        return _OptimizedListItem(
          key: key,
          isVisible: _visibleItems.contains(index),
          child: widget.itemBuilder(context, item, index),
        );
      },
    );
  }
}

class _OptimizedListItem extends StatefulWidget {
  final Widget child;
  final bool isVisible;

  const _OptimizedListItem({
    super.key,
    required this.child,
    required this.isVisible,
  });

  @override
  State<_OptimizedListItem> createState() => _OptimizedListItemState();
}

class _OptimizedListItemState extends State<_OptimizedListItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class LazyImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration? cacheDuration;

  const LazyImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.cacheDuration,
  });

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _cachedImagePath;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      PerformanceMonitor.startOperation('image_load_${widget.imageUrl.hashCode}');
      
      final cachedFile = await ImageCacheManager.cacheImage(
        widget.imageUrl,
        duration: widget.cacheDuration,
      );
      
      if (cachedFile != null) {
        setState(() {
          _cachedImagePath = cachedFile.path;
          _isLoading = false;
        });
        PerformanceMonitor.endOperation('image_load_${widget.imageUrl.hashCode}');
        return;
      }
      
      setState(() {
        _isLoading = false;
      });
      
      PerformanceMonitor.endOperation('image_load_${widget.imageUrl.hashCode}');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      
      PerformanceMonitor.endOperation('image_load_${widget.imageUrl.hashCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.grey.shade400,
                ),
              ),
            ),
          );
    }

    if (_hasError) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey.shade200,
            child: Icon(
              Icons.broken_image,
              color: Colors.grey.shade400,
              size: 32,
            ),
          );
    }

    if (_cachedImagePath != null) {
      return Image.file(
        File(_cachedImagePath!),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    return Image.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.grey.shade400,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ??
            Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey.shade200,
              child: Icon(
                Icons.broken_image,
                color: Colors.grey.shade400,
                size: 32,
              ),
            );
      },
    );
  }
}

class OptimizedFutureBuilder<T> extends StatefulWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final T? initialData;
  final Duration? cacheTimeout;
  final String? cacheKey;

  const OptimizedFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.initialData,
    this.cacheTimeout,
    this.cacheKey,
  });

  @override
  State<OptimizedFutureBuilder<T>> createState() => _OptimizedFutureBuilderState<T>();
}

class _OptimizedFutureBuilderState<T> extends State<OptimizedFutureBuilder<T>> {
  late Future<T> _future;
  T? _cachedData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFuture();
  }

  @override
  void didUpdateWidget(OptimizedFutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.future != widget.future) {
      _initializeFuture();
    }
  }

  Future<void> _initializeFuture() async {
    if (widget.cacheKey != null) {
      final cachedData = await CacheManager.get<T>(
        widget.cacheKey!,
        (data) => data as T,
      );
      
      if (cachedData != null) {
        setState(() {
          _cachedData = cachedData;
        });
      }
    }

    setState(() {
      _isLoading = true;
      _future = _executeWithCache();
    });
  }

  Future<T> _executeWithCache() async {
    try {
      PerformanceMonitor.startOperation('future_builder_${widget.cacheKey ?? 'unknown'}');
      
      final result = await widget.future;
      
      if (widget.cacheKey != null && widget.cacheTimeout != null) {
        await CacheManager.set(
          widget.cacheKey!,
          result,
          duration: widget.cacheTimeout,
        );
      }
      
      PerformanceMonitor.endOperation('future_builder_${widget.cacheKey ?? 'unknown'}');
      
      return result;
    } catch (e) {
      PerformanceMonitor.endOperation('future_builder_${widget.cacheKey ?? 'unknown'}');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedData != null && widget.initialData == null) {
      return widget.builder(context, _cachedData as T);
    }

    return FutureBuilder<T>(
      future: _future,
      initialData: widget.initialData ?? _cachedData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
          return widget.loadingBuilder?.call(context) ??
              const Center(
                child: CircularProgressIndicator(),
              );
        }

        if (snapshot.hasError) {
          return widget.errorBuilder?.call(context, snapshot.error!) ??
              Center(
                child: Text('Error: ${snapshot.error}'),
              );
        }

        if (snapshot.hasData) {
          return widget.builder(context, snapshot.data as T);
        }

        return widget.loadingBuilder?.call(context) ??
            const Center(
              child: CircularProgressIndicator(),
            );
      },
    );
  }
}

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class Throttler {
  final Duration duration;
  DateTime? _lastExecution;

  Throttler({this.duration = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    final now = DateTime.now();
    
    if (_lastExecution == null || 
        now.difference(_lastExecution!) >= duration) {
      action();
      _lastExecution = now;
    }
  }
}
