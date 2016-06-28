//
//  JHKeyWord.h
//  JSPatchDemo
//
//  Created by joyce on 15/7/21.
//  Copyright (c) 2016年 joyce. All rights reserved.
//

#ifndef JSPatchDemo_JHKeyWord_h
#define JSPatchDemo_JHKeyWord_h

//operations
#define Key_Implementation  @"@implementation"
#define Key_ImplementMethod @"implementMethod"
#define Key_InstanceCall    @"instanceCall"
#define Key_ClassCall       @"classCall"
#define Key_Log             @"NSLog"

#define ImplMethodName @"ImplMethodName"
#define ImplMethodSubCall @"ImplMethodSubCall"
#define ImplMethodParameters @"ImplMethodParameters" //[{},{}]
#define ImplMethodParameterName @"ImplMethodParameterName"
#define ImplMethodParameterType @"ImplMethodParameterType"

//#define ImplMethodInternalMethods @"ImplMethodInternalMethods"
#define ImplMethodInternalOperation @"ImplMethodInternalOperation" //"@implementation" "instanceCall"  "classCall" "NSLog"
#define ImplMethodInternalName @"ImplMethodInternalName"//internal object/class name
#define ImplMethodInternalMethodName @"ImplMethodInternalMethodName"
#define ImplMethodInternalReturnName @"ImplMethodInternalReturnName" //add for [[class alloc] init]
//#define ImplMethodInternalLatestTempReturnName @"ImplMethodInternalLatestTempReturnName"//add for [[class alloc] init]
#define ImplMethodInternalParameters @"ImplMethodInternalParameters" //[{},{}]
#define ImplMethodInternalParameterName @"ImplMethodInternalParameterName"
//#define ImplMethodInternalParameterType @"ImplMethodInternalParameterType"
#define ImplMethodInternalParameterValue @"ImplMethodInternalParameterValue"

#define ReturnType_Void  @"void"

#define VariableName @"variableName"
#define VariableValue @"variableValue"

#endif
