//
//  JHEngine.m
//  JSPatchDemo
//
//  Created by joyce on 15/7/21.
//  Copyright (c) 2015年 bang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>
#import <objc/message.h>

#import "JHContext.h"
#import "JHEngine.h"
#import "JHValue.h"


static JHContext *_context;

static NSRegularExpression *countArgRegex;
static NSArray *_TMPInvocationArguments;
static NSMutableDictionary *_JSOverideMethods;
static NSMutableDictionary *_propKeys;


static void _overrideMethod(Class cls, NSString *selectorName, JHValue *function, BOOL isClassMethod, const char *typeDescription);


static NSObject *_nilObj;
static NSObject *_nullObj;


#pragma mark Utilities

static NSString *trim(NSString *string)
{
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static NSString *extractTypeName(NSString *typeEncodeString)
{
    NSArray *array = [typeEncodeString componentsSeparatedByString:@"="];
    NSString *typeString = array[0];
    int firstValidIndex = 0;
    for (int i = 0; i< typeString.length; i++) {
        char c = [typeString characterAtIndex:i];
        if (c == '{' || c=='_') {
            firstValidIndex++;
        }else {
            break;
        }
    }
    return [typeString substringFromIndex:firstValidIndex];
}
static NSDictionary *rectToDictionary(CGRect rect)
{
    return @{@"x": @(rect.origin.x), @"y": @(rect.origin.y), @"width": @(rect.size.width), @"height": @(rect.size.height)};
}

static NSDictionary *pointToDictionary(CGPoint point)
{
    return @{@"x": @(point.x), @"y": @(point.y)};
}

static NSDictionary *sizeToDictionary(CGSize size)
{
    return @{@"width": @(size.width), @"height": @(size.height)};
}

static NSDictionary *rangeToDictionary(NSRange range)
{
    return @{@"location": @(range.location), @"length": @(range.length)};
}

static CGRect dictToRect(NSDictionary *dict)
{
    return CGRectMake([dict[@"x"] intValue], [dict[@"y"] intValue], [dict[@"width"] intValue], [dict[@"height"] intValue]);
}

static CGPoint dictToPoint(NSDictionary *dict)
{
    return CGPointMake([dict[@"x"] intValue], [dict[@"y"] intValue]);
}

static CGSize dictToSize(NSDictionary *dict)
{
    return CGSizeMake([dict[@"width"] intValue], [dict[@"height"] intValue]);
}

static NSRange dictToRange(NSDictionary *dict)
{
    return NSMakeRange([dict[@"location"] intValue], [dict[@"length"] intValue]);
}


static const void *_propKey(NSString *propName) {
    if (!_propKeys) _propKeys = [[NSMutableDictionary alloc] init];
    id key = _propKeys[propName];
    if (!key) {
        key = [propName copy];
        [_propKeys setObject:key forKey:propName];
    }
    return (__bridge const void *)(key);
}
static id getPropIMP(id slf, SEL selector, NSString *propName) {
    return objc_getAssociatedObject(slf, _propKey(propName));
}
static void setPropIMP(id slf, SEL selector, id val, NSString *propName) {
    objc_setAssociatedObject(slf, _propKey(propName), val, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


#pragma mark  fomrats

//static NSDictionary *_wrapObj(id obj)
//{
//    if (!obj || obj == _nilObj) {
//        return @{@"__isNull": @(YES)};
//    }
//    return @{@"__clsName": NSStringFromClass([obj class]), @"__obj": obj};
//}

//id formatOCToJH(id obj)
//{
//    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]]) {
//        return _wrapObj([JPBoxing boxObj:obj]);
//    }
//    if ([obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:NSClassFromString(@"NSBlock")]) {
//        return obj;
//    }
//    return _wrapObj(obj);
//}

static id _formatOCToJHList(NSArray *list)
{
    NSMutableArray *arr = [NSMutableArray new];
    for (id obj in list) {
        [arr addObject:obj];
    }
    return arr;
}

#pragma mark C-impl

static JHValue* getJSFunctionInObjectHierachy(id slf, SEL selector)
{
    NSString *selectorName = NSStringFromSelector(selector);
    Class cls = [slf class];
    NSString *clsName = NSStringFromClass(cls);
    JHValue *func = _JSOverideMethods[clsName][selectorName];
    while (!func) {
        cls = class_getSuperclass(cls);
        if (!cls) {
            NSCAssert(NO, @"warning can not find selector %@", selectorName);
            return nil;
        }
        clsName = NSStringFromClass(cls);
        func = _JSOverideMethods[clsName][selectorName];
    }
    return func;
}

static char *_methodTypesInProtocol(NSString *protocolName, NSString *selectorName, BOOL isInstanceMethod, BOOL isRequired)
{
    Protocol *protocol = objc_getProtocol([trim(protocolName) cStringUsingEncoding:NSUTF8StringEncoding]);
    unsigned int selCount = 0;
    struct objc_method_description *methods = protocol_copyMethodDescriptionList(protocol, isRequired, isInstanceMethod, &selCount);
    for (int i = 0; i < selCount; i ++) {
        if ([selectorName isEqualToString:NSStringFromSelector(methods[i].name)]) {
            return methods[i].types;
        }
    }
    return NULL;
}


#define DLog(fmt, ...) NSLog((fmt), ##__VA_ARGS__);

#define JPMETHOD_RET_ID \
    return nil;

#define JPMETHOD_IMPLEMENTATION_RET(_type, _typeString, _ret) \
static _type JPMETHOD_IMPLEMENTATION_NAME(_typeString) (id slf, SEL selector) {    \
JHValue *fun = getJSFunctionInObjectHierachy(slf, selector);    \
JHValue *ret = [fun callWithArguments:_TMPInvocationArguments];  \
_ret;    \
}   \

#define JPMETHOD_IMPLEMENTATION_NAME(_typeString) JPMethodImplement_##_typeString

JPMETHOD_IMPLEMENTATION_RET(void, v, nil)
JPMETHOD_IMPLEMENTATION_RET(id, id, JPMETHOD_RET_ID)
//JPMETHOD_IMPLEMENTATION_RET(CGRect, rect, JPMETHOD_RET_STRUCT(dictToRect))
//JPMETHOD_IMPLEMENTATION_RET(CGSize, size, JPMETHOD_RET_STRUCT(dictToSize))
//JPMETHOD_IMPLEMENTATION_RET(CGPoint, point, JPMETHOD_RET_STRUCT(dictToPoint))
//JPMETHOD_IMPLEMENTATION_RET(NSRange, range, JPMETHOD_RET_STRUCT(dictToRange))


/*
 private functions
 */


static NSDictionary *_defineClass(NSString *classDeclaration, JHValue *instanceMethod, JHValue *classMethod)
{
    NSString *className;
    NSString *superClassName;
    NSString *protocolNames;
    
    NSScanner *scanner = [NSScanner scannerWithString:classDeclaration];
    [scanner scanUpToString:@":" intoString:&className];
    if (!scanner.isAtEnd) {
        scanner.scanLocation = scanner.scanLocation + 1;
        [scanner scanUpToString:@"<" intoString:&superClassName];
        if (!scanner.isAtEnd) {
            scanner.scanLocation = scanner.scanLocation + 1;
            [scanner scanUpToString:@">" intoString:&protocolNames];
        }
    }
    NSArray *protocols = [protocolNames componentsSeparatedByString:@","];
    if (!superClassName) superClassName = @"NSObject";
    className = trim(className);
    superClassName = trim(superClassName);
    
    Class cls = NSClassFromString(className);
    if (!cls) {
        Class superCls = NSClassFromString(superClassName);
        cls = objc_allocateClassPair(superCls, className.UTF8String, 0);
        objc_registerClassPair(cls);
    }
    
    for (int i = 0; i < 2; i ++) {
        BOOL isInstance = i == 0;
        JHValue *jhMethod = isInstance ? instanceMethod: classMethod;
        
        Class currCls = isInstance ? cls: objc_getMetaClass(className.UTF8String);
        {
            NSString* selectorName;
            int numberOfArg = 0;
            
//            if (!countArgRegex) {
//                countArgRegex = [NSRegularExpression regularExpressionWithPattern:@":" options:NSRegularExpressionCaseInsensitive error:nil];
//            }
//            NSUInteger numberOfMatches = [countArgRegex numberOfMatchesInString:selectorName options:0 range:NSMakeRange(0, [selectorName length])];
//            if (numberOfMatches < numberOfArg) {
//                selectorName = [selectorName stringByAppendingString:@":"];
//            }
            if (!jhMethod)
            {
                return nil;
            }
            if (![jhMethod.objectName hasSuffix:@":"])
            {
                selectorName = [jhMethod.objectName stringByAppendingString:@":"];
                NSString *regExStr = @":";
                NSError *error = NULL;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regExStr options:NSRegularExpressionCaseInsensitive error:&error];
                numberOfArg = [regex numberOfMatchesInString:selectorName options:0 range:NSMakeRange(0, [selectorName length])];
                NSLog(@"%d", numberOfArg);
            }
            if (class_respondsToSelector(currCls, NSSelectorFromString(selectorName))) {
                _overrideMethod(currCls, selectorName, jhMethod, !isInstance, NULL);
            } else {
                BOOL overrided = NO;
                for (NSString *protocolName in protocols) {
                    char *types = _methodTypesInProtocol(protocolName, selectorName, isInstance, YES);
                    if (!types) types = _methodTypesInProtocol(protocolName, selectorName, isInstance, NO);
                    if (types) {
                        _overrideMethod(currCls, selectorName, jhMethod, !isInstance, types);
                        overrided = YES;
                        break;
                    }
                }
                if (!overrided) {
                    NSMutableString *typeDescStr = [@"@@:" mutableCopy];
                    for (int i = 0; i < numberOfArg; i ++) {
                        [typeDescStr appendString:@"@"];
                    }
                    _overrideMethod(currCls, selectorName, jhMethod, !isInstance, [typeDescStr cStringUsingEncoding:NSUTF8StringEncoding]);
                }
            }
            
        }
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    class_addMethod(cls, @selector(getProp:), (IMP)getPropIMP, "@@:@");
    class_addMethod(cls, @selector(setProp:forKey:), (IMP)setPropIMP, "v@:@@");
#pragma clang diagnostic pop
    
    return @{@"cls": className};
}

static id callSelector(NSString *className, NSString *selectorName, JHValue *arguments, JHValue *instance, BOOL isSuper)
{
    id argumentsObj;// = formatJSToOC(arguments);
    
    if (instance && [selectorName isEqualToString:@"toJS"]) {
        if ([instance isKindOfClass:[NSString class]] || [instance isKindOfClass:[NSDictionary class]] || [instance isKindOfClass:[NSArray class]]) {
//            return _unboxOCObjectToJS(instance);
        }
    }
    
    Class cls = className ? NSClassFromString(className) : [instance class];
    SEL selector = NSSelectorFromString(selectorName);
    
    if (isSuper) {
        NSString *superSelectorName = [NSString stringWithFormat:@"SUPER_%@", selectorName];
        SEL superSelector = NSSelectorFromString(superSelectorName);
        
        Class superCls = [cls superclass];
        Method superMethod = class_getInstanceMethod(superCls, selector);
        IMP superIMP = method_getImplementation(superMethod);
        
        class_addMethod(cls, superSelector, superIMP, method_getTypeEncoding(superMethod));
        
        NSString *JPSelectorName = [NSString stringWithFormat:@"_JP%@", selectorName];
        JHValue *overideFunction = _JSOverideMethods[NSStringFromClass(superCls)][JPSelectorName];
        if (overideFunction) {
            _overrideMethod(cls, superSelectorName, overideFunction, NO, NULL);
        }
        
        selector = superSelector;
    }
    
    NSInvocation *invocation;
    NSMethodSignature *methodSignature;
    if (instance) {
        methodSignature = [cls instanceMethodSignatureForSelector:selector];
        NSCAssert(methodSignature, @"unrecognized selector %@ for instance %@", selectorName, instance);
        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:instance];
    } else {
        methodSignature = [cls methodSignatureForSelector:selector];
        NSCAssert(methodSignature, @"unrecognized selector %@ for class %@", selectorName, className);
        invocation= [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:cls];
    }
    [invocation setSelector:selector];
    
    NSUInteger numberOfArguments = methodSignature.numberOfArguments;
    for (NSUInteger i = 2; i < numberOfArguments; i++) {
        const char *argumentType = [methodSignature getArgumentTypeAtIndex:i];
        NSDictionary *paramDict = [_context.curArgs objectAtIndex:0];//only has one parameters dictionary
        NSArray* params = paramDict[ImplMethodInternalParameters];
        NSString* varName = params[i-2][ImplMethodInternalParameterName];
        NSDictionary* varDict = [_context getVariable:varName];
        id valObj = nil;
        if (varDict)
        {
            valObj = varDict[VariableValue];
        }
        else
        {
            if ([varName isEqualToString:@"YES"])
            {
                valObj = [[NSNumber alloc] initWithBool:YES];
            }
            else if ([varName isEqualToString:@"NO"])
            {
                valObj = [[NSNumber alloc] initWithBool:NO];
            }
            else
            {
                valObj = varName;
            }
        }
        switch (argumentType[0]) {//why here type c == BOOL?
                
                #define JP_CALL_ARG_CASE(_typeString, _type, _selector) \
                case _typeString: {                              \
                _type value = [valObj _selector];                     \
                [invocation setArgument:&value atIndex:i];\
                break; \
                }
                
                JP_CALL_ARG_CASE('c', char, charValue)
                JP_CALL_ARG_CASE('C', unsigned char, unsignedCharValue)
                JP_CALL_ARG_CASE('s', short, shortValue)
                JP_CALL_ARG_CASE('S', unsigned short, unsignedShortValue)
                JP_CALL_ARG_CASE('i', int, intValue)
                JP_CALL_ARG_CASE('I', unsigned int, unsignedIntValue)
                JP_CALL_ARG_CASE('l', long, longValue)
                JP_CALL_ARG_CASE('L', unsigned long, unsignedLongValue)
                JP_CALL_ARG_CASE('q', long long, longLongValue)
                JP_CALL_ARG_CASE('Q', unsigned long long, unsignedLongLongValue)
                JP_CALL_ARG_CASE('f', float, floatValue)
                JP_CALL_ARG_CASE('d', double, doubleValue)
                JP_CALL_ARG_CASE('B', BOOL, boolValue)
                
            case ':': {
                SEL value = nil;
                if (valObj != _nilObj) {
                    value = NSSelectorFromString(valObj);
                }
                [invocation setArgument:&value atIndex:i];
                break;
            }
            case '{': {
                NSString *typeString = extractTypeName([NSString stringWithUTF8String:argumentType]);
#define JP_CALL_ARG_STRUCT(_type, _transFunc) \
if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
_type value = _transFunc(valObj);  \
[invocation setArgument:&value atIndex:i];  \
break; \
}
                JP_CALL_ARG_STRUCT(CGRect, dictToRect)
                JP_CALL_ARG_STRUCT(CGPoint, dictToPoint)
                JP_CALL_ARG_STRUCT(CGSize, dictToSize)
                JP_CALL_ARG_STRUCT(NSRange, dictToRange)
                @synchronized (_context) {
//                    for (JPExtension *ext in _structExtensions) {
//                        size_t size = [ext sizeOfStructWithTypeName:typeString];
//                        if (size) {
//                            void *ret = malloc(size);
//                            [ext structData:ret ofDict:valObj typeName:typeString];
//                            [invocation setArgument:ret atIndex:i];
//                            free(ret);
//                            break;
//                        }
//                    }
                }
                
                break;
            }
            case '*':
            case '^': {
//                if ([valObj isKindOfClass:[JPBoxing class]]) {
//                    void *value = [((JPBoxing *)valObj) unboxPointer];
//                    [invocation setArgument:&value atIndex:i];
//                    break;
//                }
            }
            case '#': {
//                if ([valObj isKindOfClass:[JPBoxing class]]) {
//                    Class value = [((JPBoxing *)valObj) unboxClass];
//                    [invocation setArgument:&value atIndex:i];
//                    break;
//                }
            }
            default: {
                if (valObj == _nullObj) {
                    valObj = [NSNull null];
                    [invocation setArgument:&valObj atIndex:i];
                    break;
                }
                if (valObj == _nilObj ||
                    ([valObj isKindOfClass:[NSNumber class]] && strcmp([valObj objCType], "c") == 0 && ![valObj boolValue])) {
                    valObj = nil;
                    [invocation setArgument:&valObj atIndex:i];
                    break;
                }
                static const char *blockType = @encode(typeof(^{}));
                if (!strcmp(argumentType, blockType))
                {
                    //todo:support block
//                    __autoreleasing id cb = genCallbackBlock(arguments[i-2]);
//                    [invocation setArgument:&cb atIndex:i];
                } else {
//                    if ([valObj isMemberOfClass:[JPBoxing class]]) {
//                        id obj = (__bridge id)[valObj unboxPointer];
//                        [invocation setArgument:&obj atIndex:i];
//                    }else{
                        [invocation setArgument:&valObj atIndex:i];
//                    }
                }
            }
        }
    }
    
    [invocation invoke];
    const char *returnType = [methodSignature methodReturnType];
    id returnValue;
    if (strncmp(returnType, "v", 1) != 0) {
        if (strncmp(returnType, "@", 1) == 0) {
            void *result;
            [invocation getReturnValue:&result];
            
            //For performance, ignore the other methods prefix with alloc/new/copy/mutableCopy
            if ([selectorName isEqualToString:@"alloc"] || [selectorName isEqualToString:@"new"] ||
                [selectorName isEqualToString:@"copy"] || [selectorName isEqualToString:@"mutableCopy"]) {
                returnValue = (__bridge_transfer id)result;
            } else {
                returnValue = (__bridge id)result;
            }
            return returnValue;
            
        } else {
            switch (returnType[0]) {
                    
#define JP_CALL_RET_CASE(_typeString, _type) \
case _typeString: {                              \
_type tempResultSet; \
[invocation getReturnValue:&tempResultSet];\
returnValue = @(tempResultSet); \
break; \
}
                    
                    JP_CALL_RET_CASE('c', char)
                    JP_CALL_RET_CASE('C', unsigned char)
                    JP_CALL_RET_CASE('s', short)
                    JP_CALL_RET_CASE('S', unsigned short)
                    JP_CALL_RET_CASE('i', int)
                    JP_CALL_RET_CASE('I', unsigned int)
                    JP_CALL_RET_CASE('l', long)
                    JP_CALL_RET_CASE('L', unsigned long)
                    JP_CALL_RET_CASE('q', long long)
                    JP_CALL_RET_CASE('Q', unsigned long long)
                    JP_CALL_RET_CASE('f', float)
                    JP_CALL_RET_CASE('d', double)
                    JP_CALL_RET_CASE('B', BOOL)
                    
                case '{': {
                    NSString *typeString = extractTypeName([NSString stringWithUTF8String:returnType]);
#define JP_CALL_RET_STRUCT(_type, _transFunc) \
if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
_type result;   \
[invocation getReturnValue:&result];    \
return _transFunc(result);    \
}
                    JP_CALL_RET_STRUCT(CGRect, rectToDictionary)
                    JP_CALL_RET_STRUCT(CGPoint, pointToDictionary)
                    JP_CALL_RET_STRUCT(CGSize, sizeToDictionary)
                    JP_CALL_RET_STRUCT(NSRange, rangeToDictionary)
                    @synchronized (_context) {
//                        for (JPExtension *ext in _structExtensions) {
//                            size_t size = [ext sizeOfStructWithTypeName:typeString];
//                            if (size) {
//                                void *ret = malloc(size);
//                                [invocation getReturnValue:ret];
//                                NSDictionary *dict = [ext dictOfStruct:ret typeName:typeString];
//                                free(ret);
//                                return dict;
//                            }
//                        }
                    }
                    break;
                }
                case '*':
                case '^': {
                    void *result;
                    [invocation getReturnValue:&result];
//                    returnValue = formatOCToJS([JPBoxing boxPointer:result]);
                    break;
                }
                case '#': {
                    Class result;
                    [invocation getReturnValue:&result];
//                    returnValue = formatOCToJS([JPBoxing boxClass:result]);
                    break;
                }
            }
            return returnValue;
        }
    }
    return nil;
}

static void JPForwardInvocation(id slf, SEL selector, NSInvocation *invocation)
{
    NSMethodSignature *methodSignature = [invocation methodSignature];
    NSInteger numberOfArguments = [methodSignature numberOfArguments];
    
    NSString *selectorName = NSStringFromSelector(invocation.selector);
    NSString *JPSelectorName = [NSString stringWithFormat:@"_JP%@", selectorName];
    SEL JPSelector = NSSelectorFromString(JPSelectorName);
    
    if (!class_respondsToSelector(object_getClass(slf), JPSelector)) {
#pragma clang diagnostic push6
#pragma clang diagnostic ignored "-Wundeclared-selector"
        SEL origForwardSelector = @selector(ORIGforwardInvocation:);
        NSMethodSignature *methodSignature = [slf methodSignatureForSelector:origForwardSelector];
        NSInvocation *forwardInv= [NSInvocation invocationWithMethodSignature:methodSignature];
        [forwardInv setTarget:slf];
        [forwardInv setSelector:origForwardSelector];
        [forwardInv setArgument:&invocation atIndex:2];
        [forwardInv invoke];
        return;
#pragma clang diagnostic pop
    }
    
    NSMutableArray *argList = [[NSMutableArray alloc] init];
    [argList addObject:slf];
    
    for (NSUInteger i = 2; i < numberOfArguments; i++) {
        const char *argumentType = [methodSignature getArgumentTypeAtIndex:i];
        switch(argumentType[0]) {
                
#define JP_FWD_ARG_CASE(_typeChar, _type) \
case _typeChar: {   \
_type arg;  \
[invocation getArgument:&arg atIndex:i];    \
[argList addObject:@(arg)]; \
break;  \
}
                JP_FWD_ARG_CASE('c', char)
                JP_FWD_ARG_CASE('C', unsigned char)
                JP_FWD_ARG_CASE('s', short)
                JP_FWD_ARG_CASE('S', unsigned short)
                JP_FWD_ARG_CASE('i', int)
                JP_FWD_ARG_CASE('I', unsigned int)
                JP_FWD_ARG_CASE('l', long)
                JP_FWD_ARG_CASE('L', unsigned long)
                JP_FWD_ARG_CASE('q', long long)
                JP_FWD_ARG_CASE('Q', unsigned long long)
                JP_FWD_ARG_CASE('d', double)
            case '@': {
                __unsafe_unretained id arg;
                [invocation getArgument:&arg atIndex:i];
                static const char *blockType = @encode(typeof(^{}));
                if (!strcmp(argumentType, blockType)) {
                    [argList addObject:(arg ? [arg copy]: _nilObj)];
                } else {
                    [argList addObject:(arg ? arg: _nilObj)];
                }
                break;
            }
            case '{': {
                NSString *typeString = extractTypeName([NSString stringWithUTF8String:argumentType]);
#define JP_FWD_ARG_STRUCT(_type, _transFunc) \
if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
_type arg; \
[invocation getArgument:&arg atIndex:i];    \
[argList addObject:_transFunc(arg)];  \
break; \
}
                JP_FWD_ARG_STRUCT(CGRect, rectToDictionary)
                JP_FWD_ARG_STRUCT(CGPoint, pointToDictionary)
                JP_FWD_ARG_STRUCT(CGSize, sizeToDictionary)
                JP_FWD_ARG_STRUCT(NSRange, rangeToDictionary)
                
                @synchronized (_context) {
//                    for (JPExtension *ext in _structExtensions) {
//                        size_t size = [ext sizeOfStructWithTypeName:typeString];
//                        if (size) {
//                            void *ret = malloc(size);
//                            [invocation getArgument:&ret atIndex:i];
//                            NSDictionary *dict = [ext dictOfStruct:ret typeName:typeString];
//                            [argList addObject:dict];
//                            free(ret);
//                            break;
//                        }
//                    }
                }
                
                break;
            }
            case ':': {
                SEL selector;
                [invocation getArgument:&selector atIndex:i];
                NSString *selectorName = NSStringFromSelector(selector);
                [argList addObject:(selectorName ? selectorName: _nilObj)];
                break;
            }
            case '^':
            case '*': {
                void *arg;
                [invocation getArgument:&arg atIndex:i];
//                [argList addObject:[JPBoxing boxPointer:arg]];
                break;
            }
            case '#': {
                Class arg;
                [invocation getArgument:&arg atIndex:i];
//                [argList addObject:[JPBoxing boxClass:arg]];
                break;
            }
            default: {
                NSLog(@"error type %s", argumentType);
                break;
            }
        }
    }
    
    @synchronized(_context) {
        _TMPInvocationArguments = _formatOCToJHList(argList);
        
        [invocation setSelector:JPSelector];
        [invocation invoke];
        
        _TMPInvocationArguments = nil;
    }
}

static void _initJPOverideMethods(NSString *clsName) {
    if (!_JSOverideMethods) {
        _JSOverideMethods = [[NSMutableDictionary alloc] init];
    }
    if (!_JSOverideMethods[clsName]) {
        _JSOverideMethods[clsName] = [[NSMutableDictionary alloc] init];
    }
}


static void _overrideMethod(Class cls, NSString *selectorName, JHValue *function, BOOL isClassMethod, const char *typeDescription)
{
    SEL selector = NSSelectorFromString(selectorName);
    
    NSMethodSignature *methodSignature;
    
    if (typeDescription) {
        methodSignature = [NSMethodSignature signatureWithObjCTypes:typeDescription];
    } else {
        methodSignature = [cls instanceMethodSignatureForSelector:selector];
        Method method = class_getInstanceMethod(cls, selector);
        typeDescription = (char *)method_getTypeEncoding(method);
    }
    
    IMP originalImp = class_respondsToSelector(cls, selector) ? class_getMethodImplementation(cls, selector) : NULL;
    
    IMP msgForwardIMP = _objc_msgForward;
#if !defined(__arm64__)
    if (typeDescription[0] == '{') {
        //In some cases that returns struct, we should use the '_stret' API:
        //http://sealiesoftware.com/blog/archive/2008/10/30/objc_explain_objc_msgSend_stret.html
        //NSMethodSignature knows the detail but has no API to return, we can only get the info from debugDescription.
        if ([methodSignature.debugDescription rangeOfString:@"is special struct return? YES"].location != NSNotFound) {
            msgForwardIMP = (IMP)_objc_msgForward_stret;
        }
    }
#endif
    
    class_replaceMethod(cls, selector, msgForwardIMP, typeDescription);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if (class_getMethodImplementation(cls, @selector(forwardInvocation:)) != (IMP)JPForwardInvocation) {
        IMP originalForwardImp = class_replaceMethod(cls, @selector(forwardInvocation:), (IMP)JPForwardInvocation, "v@:@");
        class_addMethod(cls, @selector(ORIGforwardInvocation:), originalForwardImp, "v@:@");
    }
#pragma clang diagnostic pop
    
    if (class_respondsToSelector(cls, selector)) {
        NSString *originalSelectorName = [NSString stringWithFormat:@"ORIG%@", selectorName];
        SEL originalSelector = NSSelectorFromString(originalSelectorName);
        if(!class_respondsToSelector(cls, originalSelector)) {
            class_addMethod(cls, originalSelector, originalImp, typeDescription);
        }
    }
    
    NSString *JPSelectorName = [NSString stringWithFormat:@"_JP%@", selectorName];
    SEL JPSelector = NSSelectorFromString(JPSelectorName);
    NSString *clsName = NSStringFromClass(cls);
    
    if (!_JSOverideMethods[clsName][JPSelectorName]) {
        _initJPOverideMethods(clsName);
        _JSOverideMethods[clsName][JPSelectorName] = function;
        const char *returnType = [methodSignature methodReturnType];
        IMP JPImplementation;
        
        switch (returnType[0]) {
#define JP_OVERRIDE_RET_CASE(_type, _typeChar)   \
case _typeChar : { \
JPImplementation = (IMP)JPMETHOD_IMPLEMENTATION_NAME(_type); \
break;  \
}
                JP_OVERRIDE_RET_CASE(v, 'v')
                JP_OVERRIDE_RET_CASE(id, '@')
//                JP_OVERRIDE_RET_CASE(c, 'c')
//                JP_OVERRIDE_RET_CASE(C, 'C')
//                JP_OVERRIDE_RET_CASE(s, 's')
//                JP_OVERRIDE_RET_CASE(S, 'S')
//                JP_OVERRIDE_RET_CASE(i, 'i')
//                JP_OVERRIDE_RET_CASE(I, 'I')
//                JP_OVERRIDE_RET_CASE(l, 'l')
//                JP_OVERRIDE_RET_CASE(L, 'L')
//                JP_OVERRIDE_RET_CASE(q, 'q')
//                JP_OVERRIDE_RET_CASE(Q, 'Q')
//                JP_OVERRIDE_RET_CASE(f, 'f')
//                JP_OVERRIDE_RET_CASE(d, 'd')
//                JP_OVERRIDE_RET_CASE(B, 'B')
//                JP_OVERRIDE_RET_CASE(pointer, '^')
//                JP_OVERRIDE_RET_CASE(pointer, '*')
//                JP_OVERRIDE_RET_CASE(cls, '#')
//                JP_OVERRIDE_RET_CASE(sel, ':')
                
            case '{': {
//                NSString *typeString = extractTypeName([NSString stringWithUTF8String:returnType]);
#define JP_OVERRIDE_RET_STRUCT(_type, _funcSuffix) \
if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
JPImplementation = (IMP)JPMETHOD_IMPLEMENTATION_NAME(_funcSuffix); \
break;  \
}
//                JP_OVERRIDE_RET_STRUCT(CGRect, rect)
//                JP_OVERRIDE_RET_STRUCT(CGPoint, point)
//                JP_OVERRIDE_RET_STRUCT(CGSize, size)
//                JP_OVERRIDE_RET_STRUCT(NSRange, range)
                
                break;
            }
            default: {
                JPImplementation = (IMP)JPMETHOD_IMPLEMENTATION_NAME(v);
                break;
            }
        }
        class_addMethod(cls, JPSelector, JPImplementation, typeDescription);
    }
}


@interface JHEngine()
{
}
@end


@implementation JHEngine

static NSObject *_nilObj;

+ (void)startEngine
{
    //initialize context
    if (_context)
    {
        return;
    }
    //register keyword:impl
    JHContext *context = [[JHContext alloc] init];
    __weak JHContext *weakCtx = context;
    context.functionMapping[Key_Implementation] = ^(NSString *classDeclaration, JHValue* instanceMethod, JHValue* classMethod) {
        return _defineClass(classDeclaration, instanceMethod, classMethod);
    };
    context.functionMapping[Key_InstanceCall] = ^id(JHValue *obj, NSString *selectorName, JHValue *arguments, BOOL isSuper) {
        NSArray *args = [weakCtx curArgs];
        NSDictionary *paramDict = [args objectAtIndex:0];//only has one parameters dictionary
        NSMutableDictionary* returnVarDict = [[NSMutableDictionary alloc] init];
        id ret = nil;
        
        NSString* returnName = paramDict[ImplMethodInternalReturnName];
        if (returnName)
        {
            returnVarDict[VariableName] = returnName;
            ret = callSelector(nil, selectorName, arguments, obj, isSuper);
            returnVarDict[VariableValue] = ret;
            [weakCtx updateVariable:returnVarDict];
        }
        else
        {
            ret = callSelector(nil, selectorName, arguments, obj, isSuper);
        }
        return ret;
    };
    context.functionMapping[Key_ClassCall] = ^id(NSString *className, NSString *selectorName, JHValue *arguments) {
        NSArray *args = [weakCtx curArgs];
        NSDictionary *paramDict = [args objectAtIndex:0];//only has one parameters dictionary
        NSMutableDictionary* returnVarDict = [[NSMutableDictionary alloc] init];

        NSString* returnName = paramDict[ImplMethodInternalReturnName];
        if (returnName)
        {
            returnVarDict[VariableName] = returnName;
            id ret = callSelector(className, selectorName, arguments, nil, NO);
            returnVarDict[VariableValue] = ret;
            [weakCtx updateVariable:returnVarDict];
            return ret;
        }
        else
        {
            return callSelector(className, selectorName, arguments, nil, NO);
        }
    };


    context.functionMapping[Key_Log] = ^() {
        NSArray *args = [weakCtx curArgs];
        NSDictionary* paramDict = [args objectAtIndex:0];//only has one dictionary
        NSMutableArray* parameters = paramDict[ImplMethodInternalParameters];
        for (NSDictionary *internalMethodParameter in parameters)
        {
            NSString* internalMethodParameterName = internalMethodParameter[ImplMethodInternalParameterName];
            NSString* internalMethodParameterValue = internalMethodParameter[ImplMethodInternalParameterValue];

            NSLog(internalMethodParameterName, internalMethodParameterValue);
        }
    };
    
    _context = context;
}

+ (void)evaluateScript:(NSString *)script
{
    //evaluate script to Runtime system
    [_context evaluateScript:script];
}

+ (JHContext*) context
{
    return _context;
}


@end