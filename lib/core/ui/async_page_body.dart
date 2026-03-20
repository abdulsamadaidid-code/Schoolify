import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper for [AsyncValue] pages — keeps screens lean.
Widget asyncPageBody<T>({
  required AsyncValue<T> async,
  required Widget Function(T data) data,
}) {
  return async.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not load data.\n$e',
          textAlign: TextAlign.center,
        ),
      ),
    ),
    data: data,
  );
}
