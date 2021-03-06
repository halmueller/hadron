//
//  Log.swift
//  Hadron
//
//  Created by Jean-Daniel Dupas on 20/06/2014.
//  Copyright (c) 2014 Xenonium. All rights reserved.
//

import Foundation

@_silgen_name("pthread_mach_thread_np")
private func pthread_mach_thread_np(_ : pthread_t) -> mach_port_t;

// This hacky call is from CoreFoundation.
// This is the way CoreFoundation (and so NSLog) determines if it should log in stderr
// As we only use stderr (and not asl like CF does), we use this same hack to prevent duplicate
// prefix in Console output when not running in Xcode (launchd already append a prefix).
// if it could be a pipe back to launchd, don't prepend a prefix
@discardableResult
@_silgen_name("vproc_swap_integer")
private func _vproc_swap_integer(_: OpaquePointer?, _: CInt, _: UnsafePointer<Int64>?, _: UnsafePointer<Int64>?) -> OpaquePointer?;

typealias asl_object_t = OpaquePointer?;
@_silgen_name("asl_vlog")
private func asl_log(_ client: asl_object_t, msg: asl_object_t, level : Int32, fmt : UnsafePointer<Int8>!, args : CVaListPointer);

final class Logger {
  
  enum Level : Int32 {
    case emergency,
    alert,
    critical,
    error,
    warning,
    notice,
    info,
    debug
  }

  // MARK: Convenient methods
  func warn(_ message : String, client: asl_object_t = nil, msg: asl_object_t = nil) {
    log(level: .warning, message: message, client: client, msg: msg);
  }
  
  func error(_ message : String, client: asl_object_t = nil, msg: asl_object_t = nil) {
    log(level: .error, message: message, client: client, msg: msg);
  }
  
  // MARK: =================== Standard Logging ===================
  #if DEBUG
  func debug(message : String) {
    if Logger.hasPrefix {
      var nows = timeval(tv_sec: 0, tv_usec: 0);
      gettimeofday(&nows, nil);
      let date = Logger.format.string(from: Date(timeIntervalSince1970:TimeInterval(nows.tv_sec)));
      "\(date).%.3u \(Logger.progname)[\(getpid()):%x] %s\n".withCString { ( fmt : UnsafePointer<Int8>) -> Void in
        message.withCString {
          withVaList([nows.tv_usec / 1000, pthread_mach_thread_np(pthread_self()), $0]) {
            vfprintf(__stderrp, fmt, $0);
            return;
          }
        }
      }
    } else {
      "%s\n".withCString { (str : UnsafePointer<Int8>) -> () in
        message.withCString {
          withVaList([$0]) { vfprintf(__stderrp, str, $0); }
        }
      }
    }
  }

  func trace(args: String, file : String = #file, line : Int = #line, function : String = #function) {
    debug(message: "[\((file as NSString).lastPathComponent):\(line)]: \(function) (\(args))\n");
  }
  
  func log(level : Level, message : String, client: asl_object_t, msg: asl_object_t) {
    debug(message: "Log(\(level): \(message)");
  }
  
  #else
  // MARK: Release
  // Instance Methods
  func debug(_ message : @autoclosure () -> String) {}
  
  func log(level : Level, message : String, client: asl_object_t, msg: asl_object_t) {
    "%s".withCString { (fmt : UnsafePointer<Int8>) -> Void in
      message.withCString {
        withVaList([$0]) {
          asl_log(client, msg: msg, level: level.rawValue, fmt: fmt, args: $0);
        }
      }
    }
  }
  #endif

  #if DEBUG
  private static let progname = String(validatingUTF8:getprogname()) ?? "<?>"
  private static let hasPrefix : Bool = {
    var val : Int64 = 0;
    _vproc_swap_integer(nil, 5 /* VPROC_GSK_IS_MANAGED */, nil, &val);
    return val <= 0;
  }();

  private static let format : DateFormatter = {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd HH:mm:ss";
    fmt.locale = Locale(identifier:"en_US");
    return fmt;
  }()
  #endif
}

private let _logger = Logger();

func spx_log(_ level : Logger.Level, message : String, client: asl_object_t = nil, msg: asl_object_t = nil) {
  _logger.log(level: level, message: message, client: client, msg: msg);
}

func spx_warn(_ message : String, client: asl_object_t = nil, msg: asl_object_t = nil) {
  _logger.warn(message, client: client, msg: msg);
}

func spx_error(_ message : String, client: asl_object_t = nil, msg: asl_object_t = nil) {
  _logger.error(message, client: client, msg: msg);
}

#if DEBUG
  func spx_debug(_ message : String) {
    _logger.debug(message: message);
  }

  func spx_trace(args: String = "", file : String = #file, line : Int = #line, function : String = #function) {
    _logger.trace(args: args, file: file, line: line, function: function);
  }
#else
  // MARK: Release
  func spx_debug(_ message : @autoclosure () -> String) { /* noop */  }

  func spx_trace(args: @autoclosure () -> String = "") { /* Noop */ }
#endif
