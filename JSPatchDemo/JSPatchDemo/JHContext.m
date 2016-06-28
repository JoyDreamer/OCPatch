
//
//  JHContext.m
//  JSPatchDemo
//
//  Created by joyce on 15/7/21.
//  Copyright (c) 2016年 joyce. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JHContext.h"
#import "JHValue.h"
#import "JHParse.h"
#import "JHKeyWord.h"

@interface JHContext()
{
    NSMutableArray* allClass;//[className, [methodName, [subCallName, parameters]]
}

@end

@implementation JHContext

- (id) init
{
    self = [super init];
    if (self)
    {
        _functionMapping = [[NSMutableDictionary alloc] init];
        _curArgs = [[NSMutableArray alloc] init];
        _variables = [[NSMutableArray alloc] init];
        allClass = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)evaluateScript:(NSString *)script
{
    //parese schema, then call context method
#if 1
    NSString* copyScript = [script copy];

    NSArray* lineArray =  [copyScript componentsSeparatedByString:@"\n"];
    JHValue* implClass = nil;
    JHValue* implMethod = nil;

    for (int i = 0; i < [lineArray count]; i++)
    {
        NSString* line = [lineArray objectAtIndex:i];
        line = [line stringByTrimmingCharactersInSet:[NSMutableCharacterSet whitespaceCharacterSet]];
        if (line.length > 0)
        {
            JHParseReturn* ret = [JHParse parseScript:line];
            if (ret.operation == nil)
            {
                continue;
            }
            if ([ret.operation isEqualToString:Key_Implementation])
            {
                implClass = [[JHValue alloc] init];
                implClass.objectName = ret.objectClassName;
                
                [allClass addObject:implClass];
            }
            if ([ret.operation isEqualToString:Key_ImplementMethod])
            {
                implMethod = [[JHValue alloc] init];

                implMethod.objectName = ret.methodName;

                //call declare for method
                [implClass.functionArray addObject:implMethod];
                
                NSDictionary* (^block)(NSString *classDeclaration, JHValue* instanceMethods, JHValue* classMethods) = _functionMapping[Key_Implementation];
                block(implClass.objectName, implMethod, nil);
            }
            if ([ret.operation isEqualToString:Key_Log])
            {
                NSMutableDictionary* internalDict = [[NSMutableDictionary alloc] init];

                internalDict[ImplMethodInternalOperation] = ret.operation;
                internalDict[ImplMethodInternalName] = ret.objectName;
                internalDict[ImplMethodInternalMethodName] = ret.methodName;
                internalDict[ImplMethodInternalParameters] = ret.paramArray;

                [implMethod.functionArray addObject:internalDict];
            }
            else if ([ret.operation isEqualToString:Key_InstanceCall])
            {
                NSMutableDictionary* internalDict = [[NSMutableDictionary alloc] init];
                
                internalDict[ImplMethodInternalOperation] = ret.operation;
                internalDict[ImplMethodInternalName] = ret.objectName;
                internalDict[ImplMethodInternalMethodName] = ret.methodName;
                internalDict[ImplMethodInternalParameters] = ret.paramArray;
                if (ret.latestTempReturnName.length && ret.next)
                {
                    internalDict[ImplMethodInternalReturnName] = ret.latestTempReturnName;
                    [implMethod.functionArray addObject:internalDict];
                    
                    //prepare the next call e.g init
                    NSMutableDictionary* nextDict = [[NSMutableDictionary alloc] init];
                    nextDict[ImplMethodInternalOperation] = ret.next.operation;
                    nextDict[ImplMethodInternalName] = ret.next.objectName;
                    nextDict[ImplMethodInternalMethodName] = ret.next.methodName;
                    nextDict[ImplMethodInternalParameters] = ret.next.paramArray;
                    if (ret.returnName.length)
                    {
                        nextDict[ImplMethodInternalReturnName] = ret.returnName;
                    }
                    [implMethod.functionArray addObject:nextDict];
                }
                else
                {
                    [implMethod.functionArray addObject:internalDict];
                }
            }
            else if ([ret.operation isEqualToString:Key_ClassCall])
            {
                NSMutableDictionary* internalDict = [[NSMutableDictionary alloc] init];
                
                internalDict[ImplMethodInternalOperation] = ret.operation;
                internalDict[ImplMethodInternalName] = ret.objectClassName;
                internalDict[ImplMethodInternalMethodName] = ret.methodName;
                internalDict[ImplMethodInternalParameters] = ret.paramArray;
                if (ret.latestTempReturnName.length && ret.next)
                {
                    internalDict[ImplMethodInternalReturnName] = ret.latestTempReturnName;
                    [implMethod.functionArray addObject:internalDict];
                    
                    //prepare the next call e.g init
                    NSMutableDictionary* nextDict = [[NSMutableDictionary alloc] init];
                    nextDict[ImplMethodInternalOperation] = ret.next.operation;
                    nextDict[ImplMethodInternalName] = ret.next.objectName;
                    nextDict[ImplMethodInternalMethodName] = ret.next.methodName;
                    nextDict[ImplMethodInternalParameters] = ret.next.paramArray;
                    if (ret.returnName.length)
                    {
                        nextDict[ImplMethodInternalReturnName] = ret.returnName;
                    }
                    [implMethod.functionArray addObject:nextDict];
                }
                else
                {
                    [implMethod.functionArray addObject:internalDict];
                }
            }
            else
            {
                //nothing
            }
        }
    }
#else
    
    NSString* operation = @"@implementation";
    NSString* object = @"JPViewController";

    NSString* instanceMethodName = @"handleBtn";
    NSString* instanceMethodReturnType = @"void";
    NSString* instanceMethodParameterName = @"sender";
    NSString* instanceMethodParameterType = @"id";

    NSString* instanceMethodInternalOperation = @"NSLog";
    NSString* instanceMethodInternalName = @"NSLog";
    NSString* instanceMethodInternalReturnType = @"void";
    NSString* instanceMethodInternalParameterName = @"%@";
    NSString* instanceMethodInternalParameterType = @"NSString*";
    NSString* instanceMethodInternalParameterValue = @"###";

    NSString* instanceMethodInternalOperation1 = @"instanceCall";
    NSString* instanceMethodInternalName1 = @"testFunction";
    NSString* instanceMethodInternalReturnType1 = @"void";
    NSString* instanceMethodInternalParameterName1 = @"";
    NSString* instanceMethodInternalParameterType1 = @"";
    NSString* instanceMethodInternalParameterValue1 = @"";

    JHValue* instanceMethods = [[JHValue alloc] init];
    
    NSMutableDictionary* instanceMethodDict = [[NSMutableDictionary alloc] init];
    instanceMethodDict[InstanceMethodName] = instanceMethodName;
    instanceMethodDict[InstanceMethodReturnType] = instanceMethodReturnType;

    NSMutableArray* paramtersArray = [[NSMutableArray alloc] init];
    NSMutableDictionary* parameterDict = [[NSMutableDictionary alloc] init];
    parameterDict[InstanceMethodParameterName] = instanceMethodParameterName;
    parameterDict[InstanceMethodParameterType] = instanceMethodParameterType;
    [paramtersArray addObject:parameterDict];
    instanceMethodDict[InstanceMethodParameters] = paramtersArray;

    NSMutableArray* internalMethodArray = [[NSMutableArray alloc] init];
    NSMutableDictionary* internalDict = [[NSMutableDictionary alloc] init];
    internalDict[InstanceMethodInternalOperation] = instanceMethodInternalOperation;
    internalDict[InstanceMethodInternalName] = instanceMethodInternalName;
    internalDict[InstanceMethodInternalReturnType] = instanceMethodInternalReturnType;
    NSMutableArray* internalMethodParameterArray = [[NSMutableArray alloc] init];
    NSMutableDictionary* internalMethodParameterArrayDic = [[NSMutableDictionary alloc] init];
    internalMethodParameterArrayDic[InstanceMethodInternalParameterName] = instanceMethodInternalParameterName;
    internalMethodParameterArrayDic[InstanceMethodInternalParameterType] = instanceMethodInternalParameterType;
    internalMethodParameterArrayDic[InstanceMethodInternalParameterValue] = instanceMethodInternalParameterValue;
    [internalMethodParameterArray addObject:internalMethodParameterArrayDic];
    internalDict[InstanceMethodInternalParameters] = internalMethodParameterArray;
    [internalMethodArray addObject:internalDict];
    
    NSMutableDictionary* internalDict1 = [[NSMutableDictionary alloc] init];
    internalDict1[InstanceMethodInternalOperation] = instanceMethodInternalOperation1;
    internalDict1[InstanceMethodInternalName] = instanceMethodInternalName1;
    internalDict1[InstanceMethodInternalReturnType] = instanceMethodInternalReturnType1;
    NSMutableArray* internalMethodParameterArray1 = [[NSMutableArray alloc] init];
    NSMutableDictionary* internalMethodParameterArrayDic1 = [[NSMutableDictionary alloc] init];
    internalMethodParameterArrayDic1[InstanceMethodInternalParameterName] = instanceMethodInternalParameterName1;
    internalMethodParameterArrayDic1[InstanceMethodInternalParameterType] = instanceMethodInternalParameterType1;
    internalMethodParameterArrayDic1[InstanceMethodInternalParameterValue] = instanceMethodInternalParameterValue1;
    [internalMethodParameterArray1 addObject:internalMethodParameterArrayDic1];
    internalDict1[InstanceMethodInternalParameters] = internalMethodParameterArray1;
    [internalMethodArray addObject:internalDict1];

    instanceMethodDict[InstanceMethodInternalMethods] = internalMethodArray;

//    [instanceMethodsArray addObject:instanceMethodDict];

    /*
     [name:handleBtn returnType:void parameters:[{name:sender type:id}] insternalMethods:[{name:NSLog returnType:void parmaters:[{name:%@ type:NSString value:####}]]}], [name:handleBtn returnType:void parameters:[{name:sender type:id}]]
     */
//    instanceMethods.functionMapping[instanceMethodName] = instanceMethodsArray;
    [instanceMethods.functionArray addObject:instanceMethodDict];

//    JHValue* classMethods = [[JHValue alloc] init];
#endif
//    NSDictionary* (^block)(NSString *classDeclaration, JHValue* instanceMethods, JHValue* classMethods) = _functionMapping[operation];
//    block(object, instanceMethods, nil);

}

- (void)updateVariable:(NSDictionary*) variable
{
    for(NSMutableDictionary* var in _variables)
    {
        if (![var[VariableName] isEqualToString: variable[VariableName]])
        {
            continue;
        }
        var[VariableValue] = variable[VariableValue];
        return;
    }
    [_variables addObject:variable];
}

- (NSDictionary*)getVariable:(NSString*) variableName
{
    for(NSMutableDictionary* var in _variables)
    {
        if (![var[VariableName] isEqualToString: variableName])
        {
            continue;
        }
        return var;
    }
    return nil;
}

@end