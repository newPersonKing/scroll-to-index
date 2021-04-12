//Copyright (C) 2019 Potix Corporation. All Rights Reserved.
//History: Tue Apr 24 09:17 CST 2019
// Author: Jerry Chen

library util;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/animation.dart';

/// used to invoke async functions in order
Future<T> co<T>(key, FutureOr<T> action()) async {
  /*todo 这里为什么要循环 */
  /*todo 如果上次 action 没有执行完成 等待*/
  for (;;) {
    final c = _locks[key];
    /*第一次进来 这里肯定是null*/
    if (c == null) break;
    try {
      await c.future;
    } catch (_) {} //ignore error (so it will continue)
  }

  final c = _locks[key] = new Completer<T>();
  void then(T result) {
    final c2 = _locks.remove(key);
    c.complete(result);

    assert(identical(c, c2));
  }

  void catchError(ex, StackTrace st) {
    final c2 = _locks.remove(key);
    c.completeError(ex, st);

    assert(identical(c, c2));
  }

  try {
    /*action 可以是异步从操作*/
    final result = action();
    if (result is Future<T>) {
      result.then(then).catchError(catchError);
    } else {
      then(result);
    }
  } catch (ex, st) {
    catchError(ex, st);
  }

  return c.future;
}

final _locks = new HashMap<dynamic, Completer>();

/// skip the TickerCanceled exception
Future catchAnimationCancel(TickerFuture future) async {
  return future.orCancel.catchError((_) async {
    // do nothing, skip TickerCanceled exception
    return null;
  }, test: (ex) => ex is TickerCanceled);
}
