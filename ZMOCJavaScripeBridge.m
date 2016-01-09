//
//  ZMOCJavaScripeBridge.m
//
//  Created by 郑蒙 on 16/1/9.
//  Copyright © 2016年 joemo. All rights reserved.
//

#import "ZMOCJavaScripeBridge.h"
#import <objc/runtime.h>

@interface ZMOCJavaScripeBridge ()<UIWebViewDelegate>
// webView所在控制器实例
@property (nonatomic, strong) id currentClassInstance;

@end

@implementation ZMOCJavaScripeBridge

static id _instace = nil;
+ (id)allocWithZone:(struct _NSZone *)zone{
    if (_instace == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _instace = [super allocWithZone:zone];
        });
    }
    return _instace;
}
- (id)init{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instace = [super init];
    });
    return _instace;
}
+ (id)copyWithZone:(struct _NSZone *)zone{
    return _instace;
}
+ (id)mutableCopyWithZone:(struct _NSZone *)zone{
    return _instace;
}
+ (instancetype)shareManager{
    return [[self alloc] init];
}

/**
 *  JavaScripe 向 OC 发送信息
 *
 *  @param currentWebView 当前WebView
 *  @param currentClass   当前类
 */
- (void)startJSEventMonitor:(UIWebView *)currentWebView WithCurrentClassInstance:(id)currentClassInstance{
    currentWebView.delegate = self;
    self.currentClassInstance = currentClassInstance;
}

/**
 *  OC 向 JavaScripe 发送信息
 *
 *  @param JavaScripeString JS语句字符串
 */
- (void)sendObjcInfoWithJavaScripeString:(NSString *)JavaScripeString WithCurrentWebView:(UIWebView *)currentWebView{
    [currentWebView stringByEvaluatingJavaScriptFromString:JavaScripeString];
}

#pragma mark - <UIWebViewDelegate>
/**
 *  每当webView发送一个请求之前都会先调用这个方法
 *     
 *  @param request    即将发送的请求
 *  
 *  @return           YES: 允许发送这个请求, NO: 禁止发送这个请求
 */
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSString *url = request.URL.absoluteString;
    // 解码url里的中文及特殊符号
    url = [url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSRange range = [url rangeOfString:@"ZM://"];
    if (range.location != NSNotFound) {
        // 截取方法名
        NSRange r1 = [url rangeOfString:@"("];
        NSRange r2 = [url rangeOfString:@")"];
        NSRange range = NSMakeRange(r1.location + 1, r2.location - r1.location - 1);
        NSString *methodName = [url substringWithRange:range];
        
        // 截取参数
        NSArray *parameters = nil;
        NSRange r3 = [url rangeOfString:@"["];
        NSRange r4 = [url rangeOfString:@"]"];
        if (r3.location != NSNotFound && r4.location != NSNotFound) {
            NSRange range2 = NSMakeRange(r3.location + 1, r4.location - r3.location - 1);
            NSString *paramStr = [url substringWithRange:range2];
            if (![paramStr isEqualToString:@""]) {
                parameters = [paramStr componentsSeparatedByString:@","];
            }
        }
        // 调用方法
        SEL selector = NSSelectorFromString(methodName);
        
        // 判断方法的目的： 防止因为方法不存在而报错
        if ([self.currentClassInstance respondsToSelector:selector]) {
            if (![self.currentClassInstance respondsToSelector:@selector(performSelector:withObjects:)]) {
                [self addMethodAndImplementationToClassInstance:self.currentClassInstance withSel:@selector(performSelector:withObjects:)];
            }
            [self.currentClassInstance performSelector:selector withObjects:parameters];
        }
        return NO;
    }
    return YES;
}

// 给webView所在控制器添加performSelector:withObjects:方法
- (void)addMethodAndImplementationToClassInstance:(id)classInstance withSel:(SEL)sel{
    IMP codeImp = class_getMethodImplementation([self class], sel);
    class_addMethod([classInstance class], @selector(performSelector:withObjects:), codeImp, "@");
}

//  performSelector执行方法(多参数)
- (id)performSelector:(SEL)selector withObjects:(NSArray *)objects {
    NSMethodSignature *signature = [self methodSignatureForSelector:selector];
    if (signature) {
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self];
        [invocation setSelector:selector];
        for(int i = 0; i < [objects count]; i++){
            id object = [objects objectAtIndex:i];
            [invocation setArgument:&object atIndex: (i + 2)];
        }
        [invocation invoke];
        if (signature.methodReturnLength) {
            id anObject;
            [invocation getReturnValue:&anObject];
            return anObject;
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

@end
