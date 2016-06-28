//
//  JHValue.h
//  JSPatchDemo
//
//  Created by joyce on 15/7/26.
//  Copyright (c) 2016年 joyce. All rights reserved.
//

#ifndef JSPatchDemo_JHValue_h
#define JSPatchDemo_JHValue_h

#import "JHKeyWord.h"

@interface JHValue : NSObject
@property(nonatomic, strong) NSMutableDictionary* variableDict;//{varName:varAddr, returnVarName:returnVarAddr}
@property(nonatomic, strong) NSMutableDictionary* objectFunctionDict;//{objectName:function}

@property(nonatomic, copy) NSString* objectName;
@property(nonatomic, strong) NSMutableArray* functionArray;//{{objectName:objectAddr}, {}}
//@property(nonatomic, strong) JHValue* parent;//currently, we only support one level parsing , and ignore {}

//- (NSArray*) methodsToArray;
- (JHValue*) callWithArguments:(NSArray*) args;
@end

#endif
