//
//  JHValue.m
//  JSPatchDemo
//
//  Created by joyce on 15/7/26.
//  Copyright (c) 2015年 bang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JHValue.h"
#import "JHEngine.h"

@implementation JHValue

- (id) init
{
    self = [super init];
    if (self)
    {
        _variableDict = [[NSMutableDictionary alloc] init];
        _objectFunctionDict = [[NSMutableDictionary alloc] init];

        _objectName = nil;
        _functionArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (JHValue*) callWithArguments:(NSArray*) args
{
    JHValue* ret = nil;

    //call native Objective-C function according function chain.
    NSLog(@"callWithArguments");
    JHContext* context = [JHEngine context];
    NSArray* functionArray = self.functionArray;
    for (int i = 0; i < functionArray.count; i++)
    {
        [context.curArgs removeAllObjects];
        
        NSDictionary* internalMethod = functionArray[i];
        NSString* internalMethodOperation = internalMethod[ImplMethodInternalOperation];
        NSString* internalMethodName = internalMethod[ImplMethodInternalName];
        NSString* internalMethodMethodName = internalMethod[ImplMethodInternalMethodName];
        [context.curArgs addObject:internalMethod];

        if ([internalMethodOperation isEqualToString:Key_InstanceCall])
        {
            id (^block)(JHValue *obj, NSString *selectorName, JHValue *arguments, BOOL isSuper) = context.functionMapping[Key_InstanceCall];

            if ([internalMethodName isEqualToString:@"self"])
            {
                block([args objectAtIndex:0], internalMethodMethodName, [args objectAtIndex:1], NO);//first arg is self, second from invocation
            }
            else
            {
                NSDictionary* var = [context getVariable:internalMethodName];
                if (var)
                {
                    block(var[VariableValue], internalMethodMethodName, [args objectAtIndex:1], NO);//first arg is self, second from invocation
                }
                else
                {
                    //nothing
                }
            }
        }
        else if ([internalMethodOperation isEqualToString:Key_ClassCall])
        {
            void (^block)(NSString *className, NSString *selectorName, JHValue *arguments) = context.functionMapping[Key_ClassCall];
            block(internalMethodName, internalMethodMethodName, [args objectAtIndex:1]);
        }
        else if ([internalMethodOperation isEqualToString:Key_Log])
        {
            void (^block)() = context.functionMapping[Key_Log];
            block();
        }
        else if ([internalMethodOperation isEqualToString:Key_Implementation])
        {/*
          NSDictionary* (^block)(NSString *classDeclaration, JHValue* instanceMethods, JHValue* classMethods) = [JHEngine context].functionMapping[internalMethodName];
          block(object, instanceMethods, nil);
          */
        }
        else
        {
            //nothing
        }
    }
    return ret;
}

@end