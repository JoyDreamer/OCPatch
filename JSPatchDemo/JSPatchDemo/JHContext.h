//
//  JHContext.h
//  JSPatchDemo
//
//  Created by joyce on 15/7/21.
//  Copyright (c) 2015年 bang. All rights reserved.
//

#ifndef JSPatchDemo_JHContext_h
#define JSPatchDemo_JHContext_h
#import <Foundation/Foundation.h>

@interface JHContext : NSObject
@property(nonatomic, strong) NSMutableDictionary* functionMapping;
@property(nonatomic, strong) NSMutableArray* curArgs;
@property(nonatomic, strong) NSMutableArray* variables;

- (void)evaluateScript:(NSString *)script;
- (void)updateVariable:(NSDictionary*) variable;
- (NSDictionary*)getVariable:(NSString*) variableName;
@end

#endif
