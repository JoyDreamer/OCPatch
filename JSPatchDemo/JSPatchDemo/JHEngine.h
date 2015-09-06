//
//  JHEngine.h
//  JSPatchDemo
//
//  Created by joyce on 15/7/21.
//  Copyright (c) 2015年 bang. All rights reserved.
//

#ifndef JSPatchDemo_JHEngine_h
#define JSPatchDemo_JHEngine_h

#import "JHKeyWord.h"

#import "JHContext.h"

@interface JHEngine : NSObject
+ (void)startEngine;
+ (void)evaluateScript:(NSString *)script;
+ (JHContext*) context;
@end

#endif
