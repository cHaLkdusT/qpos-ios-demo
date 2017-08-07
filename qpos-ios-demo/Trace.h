//
//  Trace.h
//  qpossdk
//
//  Created by XiaoLonghui on 13-11-5.
//  Copyright (c) 2013年 xiaochengdong. All rights reserved.
//

#ifdef DEBUG
#define Trace(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define Trace(format, ...)
#endif
