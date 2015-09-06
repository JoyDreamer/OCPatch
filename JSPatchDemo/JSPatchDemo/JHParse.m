//
//  JHParse.m
//  JSPatchDemo
//
//  Created by joyce on 15/7/21.
//  Copyright (c) 2015年 bang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JHParse.h"
#import "JHKeyWord.h"

@implementation JHParseReturn

- (id) init
{
    self = [super init];
    if (self)
    {
        self.object = nil;
        self.methodName = nil;
        self.operation = nil;
        self.objectName = nil;
        self.objectClassName = nil;
        self.returnDict = [[NSMutableDictionary alloc] init];
        self.returnName = nil;
        self.latestTempReturnName = nil;
        self.paramArray = [[NSMutableArray alloc] init];

        self.next = nil;
    }
    return self;
}
@end

@implementation JHParse

NSString* getFirstElement(NSString *script, NSString* seprator)
{
    NSString* ret = nil;
    NSRange range = [script rangeOfString:seprator];
    if (range.location != NSNotFound)
    {
        range.length = range.location;
        range.location = 0;
        ret = [script substringWithRange:range];
    }
    return ret;
}

NSString* getAfterFirstElement(NSString *script, NSString* seprator)
{
    NSString* ret = nil;
    NSRange range = [script rangeOfString:seprator];
    if (range.location != NSNotFound)
    {
        ret = [script substringFromIndex:range.location + seprator.length];
    }
    return ret;
}

NSString* replacePropertyCallWithInstanceCall(NSString* script)
{
    NSString* ret = script;
    NSRange range = [script rangeOfString:@"."];
    if (range.location != NSNotFound)
    {
        range = [script rangeOfString:@" "];
        if (range.location != NSNotFound)
        {
            NSString* first = getFirstElement(script, @" ");
            NSString* afterFirst = getAfterFirstElement(script, @" ");
            ret = [NSString stringWithFormat:@"%@] %@", [first stringByReplacingOccurrencesOfString:@"." withString:@" "], afterFirst];
        }
    }
    return ret;
}

void copyParseReturn(JHParseReturn* dest, JHParseReturn* src)
{
    dest.operation = src.operation;
    dest.objectName = src.objectName;
    dest.objectClassName = src.objectClassName;
    dest.object = src.object;
    dest.methodName = src.methodName;
    dest.paramArray = src.paramArray;
    dest.latestTempReturnName = src.latestTempReturnName;
    dest.next = src.next;
}

JHParseReturn* parseClassOrInstanceCall(NSString*script)
{
    JHParseReturn* ret = [[JHParseReturn alloc] init];
    if ([script hasPrefix:@"["])
    {
        NSString* subScript = [[script substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];//skip [
        NSString* uppercaseScript = [subScript uppercaseString];
        NSRange range;
        range.location = 0;
        range.length = 1;
        NSString* uppercaseFirstCharacter = [uppercaseScript substringWithRange:range];
        NSString* firstCharacter = [subScript substringWithRange:range];
        if ([firstCharacter isEqualToString:uppercaseFirstCharacter]) //class call with uppercase prefix
        {
            ret.operation = Key_ClassCall;
            NSString* temp = getFirstElement(subScript, @" ");
            if (temp)
            {
                ret.objectClassName = temp;
            }
            temp = getAfterFirstElement(subScript, @" ");
            if (temp)
            {
                subScript = [temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                temp = getFirstElement(subScript, @"]");
                if (temp)
                {
                    NSRange tempRange = [temp rangeOfString:@":"];
                    if (tempRange.location != NSNotFound)
                    {
                        tempRange.length = tempRange.location;
                        tempRange.location = 0;
                        ret.methodName = [temp substringWithRange:tempRange];
                        
                        NSString* tempString = getAfterFirstElement(temp, @":");
                        NSMutableDictionary* parameterDic = [[NSMutableDictionary alloc] init];
                        parameterDic[ImplMethodInternalParameterName] = getFirstElement(tempString, @"\",");
                        parameterDic[ImplMethodInternalParameterValue] = getAfterFirstElement(tempString, @"\",");
                        [ret.paramArray addObject:parameterDic];
                    }
                    else
                    {
                        ret.methodName = temp;
                    }
                }
                temp = getAfterFirstElement(subScript, @"]");
                if (temp)
                {
                    subScript = [temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    //process next call
                    if (subScript)
                    {
                        NSRange tempRange = [subScript rangeOfString:@"]"];
                        if (tempRange.location != NSNotFound)
                        {
                            ret.latestTempReturnName = @"latestTemp";
                            
                            ret.next = [[JHParseReturn alloc] init];
                            ret.next.operation = Key_InstanceCall;
                            ret.next.objectName  = @"latestTemp";
                            ret.next.methodName = getFirstElement(subScript, @"]");
                        }
                    }
                }
            }
        }
        else //instance call
        {

            subScript = replacePropertyCallWithInstanceCall(subScript);
            NSString* tempSubScript = subScript;
            NSRange range4Method = [subScript rangeOfString:@" "];
            JHParseReturn* tempRet = ret;
            while (range4Method.location != NSNotFound)
            {
                tempRet.operation = Key_InstanceCall;

                NSRange tempRange = range4Method;
                tempRange.location = 0; //skip [
                tempRange.length = range4Method.location;
                tempRet.objectName = [tempSubScript substringWithRange:tempRange];
                
                NSMutableString* methodName = [[NSMutableString alloc] init];
                NSString* methodString = [[tempSubScript substringFromIndex:range4Method.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                
                NSString* restString = methodString;
                tempRange = [restString rangeOfString:@"]"];
                if (tempRange.location != NSNotFound)
                {
                    NSString* paramString = [getFirstElement(restString, @"]") stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    restString = getAfterFirstElement(restString, @"]");

                    NSRange range = [paramString rangeOfString:@":"];
                    while (range.location != NSNotFound)
                    {
                        NSMutableDictionary* parameterDic = [[NSMutableDictionary alloc] init];

                        [methodName appendFormat:@"%@:", getFirstElement(paramString, @":")];
                        NSString* paramterName = [getAfterFirstElement(paramString, @":") stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        NSString* parameter = getFirstElement(paramterName, @" ");
                        if (parameter)
                        {
                            parameterDic[ImplMethodInternalParameterName] = parameter;
                        }
                        else
                        {
                            parameterDic[ImplMethodInternalParameterName] = paramterName;
                        }
                        
                        paramString = [getAfterFirstElement(paramterName, @" ") stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        [tempRet.paramArray addObject:parameterDic];

                        if (paramString == nil)
                        {
                            break;
                        }
                        range = [paramString rangeOfString:@":"];
                    }
                    if (paramString)
                    {
                        [methodName appendFormat:@"%@", paramString];
                    }
                    
                    tempRet.methodName = methodName;
                }
                
                //process next parameters if exist
//                restString = getAfterFirstElement(methodString, @"]");
                range4Method = [restString rangeOfString:@" "];
                if (range4Method.location != NSNotFound)
                {
                    tempRet.latestTempReturnName = @"latestTemp";

                    tempSubScript = [NSString stringWithFormat:@"latestTemp%@", restString];
                    range4Method = [tempSubScript rangeOfString:@" "];
                    tempRet.next = [[JHParseReturn alloc] init];
                    tempRet = tempRet.next;
                }
            }
        }
    }
    return ret;
}

+ (JHParseReturn*)parseScript:(NSString *)script
{
    NSLog(@"%@", script);
    JHParseReturn* ret = [[JHParseReturn alloc] init];
    if ([script hasPrefix:Key_Implementation])
    {
        ret.operation = Key_Implementation;
        ret.objectName = @"self";
        ret.objectClassName = [[script substringFromIndex:Key_Implementation.length] stringByTrimmingCharactersInSet:[NSMutableCharacterSet whitespaceCharacterSet]];
    }
    else
    {
        if ([script hasPrefix:@"-"] || [script hasPrefix:@"+"])
        {
            ret.operation = Key_ImplementMethod;
            ret.objectName = @"self";

            script = [[script substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSRange range = [script rangeOfString:@")"];

            script = [[script substringFromIndex:range.location + range.length] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            range = [script rangeOfString:@":("];
            if (range.location != NSNotFound)
            {
                NSRange tmpRange = range;
                tmpRange.location = 0;
                tmpRange.length = range.location;
                ret.methodName = [script substringWithRange:tmpRange];
            }
        }
        else
        {
            if (![script isEqualToString:@"{"] && ![script isEqualToString:@"}"] && ![script isEqualToString:@"@end"])
            {
                if ([script hasPrefix:Key_Log])
                {
                    ret.operation = Key_Log;
                    ret.objectName = @"export";
                    ret.methodName = Key_Log;
                    //ret.returnValue = nil;

                    NSMutableDictionary* parameterDic = [[NSMutableDictionary alloc] init];
                    int i = 0;
                    NSArray* componetArray = [script componentsSeparatedByString:@","];
                    NSString* template = [componetArray objectAtIndex:0];
                    template = [template substringFromIndex:Key_Log.length + 3];//(@"
                    NSRange range = [template rangeOfString:@"“"];
#if 0 //only support one parameter
//                    while (range.location != NSNotFound)
//                    {
//                        NSRange tmpRange = range;
//                        tmpRange.location = 0;
//                        tmpRange.length = range.location;
//                        parameterDic[ImplMethodInternalParameterName] = [template substringWithRange:tmpRange];
//                        i++;
//                        parameterDic[ImplMethodInternalParameterValue] = [componetArray objectAtIndex:i];
//                        [ret.paramArray addObject:parameterDic];
//
//                        template = [template substringFromIndex:tmpRange.location];
//                        range = [template rangeOfString:@"%"];
//                    }
#endif
                    range.location = 0;
                    range.length = template.length -1;//last "
                    parameterDic[ImplMethodInternalParameterName] = [template substringWithRange:range];
                    i++;
                    NSString* lastFormatVal = [[componetArray objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    range = [lastFormatVal rangeOfString:@")"];
                    range.length = range.location;
                    range.location = 0;
                    parameterDic[ImplMethodInternalParameterValue] = [lastFormatVal substringWithRange:range];

                    [ret.paramArray addObject:parameterDic];
                }
                else if ([script hasPrefix:@"["]) //no return value
                {
                    JHParseReturn* tempRet = parseClassOrInstanceCall(script);
                    copyParseReturn(ret, tempRet);
                }
                else //has return value
                {
                    NSRange range = [script rangeOfString:@"="];
                    if (range.location != NSNotFound)
                    {
                        NSString* returnStr = [[script substringToIndex:range.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        NSArray* componentArray = [returnStr componentsSeparatedByString:@" "];
                        NSString* lastStr = [componentArray lastObject];
                        if ([lastStr hasPrefix:@"*"])
                        {
                            NSString* returnName = [lastStr substringFromIndex:1];//skip *
                            ret.returnName = returnName;
//                            [retDict setObject:nil forKey:returnName];
                        }
                        else
                        {
//                            [retDict setObject:nil forKey:lastStr];
                            ret.returnName = lastStr;
                        }
                        //ret.returnDict = retDict;
                        
                        script = [[script substringFromIndex:range.location + 1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];//skip =
                        JHParseReturn* tempRet = parseClassOrInstanceCall(script);
                        copyParseReturn(ret, tempRet);
                    }
                }
            }
        }
    }
    return ret;
}



@end