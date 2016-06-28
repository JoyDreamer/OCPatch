//
//  JHParse.h
//  JSPatchDemo
//
//  Created by joyce on 15/7/21.
//  Copyright (c) 2016年 joyce. All rights reserved.
//

#ifndef JSPatchDemo_JHParse_h
#define JSPatchDemo_JHParse_h

@interface JHParseReturn : NSObject
@property(nonatomic, copy) NSString* operation;
@property(nonatomic, copy) NSString* objectName;
@property(nonatomic, copy) NSString* objectClassName;
@property(nonatomic, copy) id object;
@property(nonatomic, copy) NSString* methodName;
@property(nonatomic, strong) NSMutableArray* paramArray;
@property(nonatomic, strong) NSMutableDictionary* returnDict;//{returnName,id returnValue}
@property(nonatomic, copy) NSString* returnName;//{returnName,id returnValue}
@property(nonatomic, copy) NSString* latestTempReturnName;//{returnName,id returnValue}

@property(nonatomic, strong) JHParseReturn* next;
@end

@interface JHParse : NSObject
+ (JHParseReturn*)parseScript:(NSString *)script;
@end

#endif
