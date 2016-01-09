//
//  ZMOCJavaScripeBridge.h
//
//  Created by 郑蒙 on 16/1/9.
//  Copyright © 2016年 joemo. All rights reserved.
//

/**
 *  JS中请求的URL格式 : ZM://methodName(sendMsg:body:abc:)?parameters=[ZhengM,26,China]
 *
 *  methodName: OC方法名
 *  parameters: 参数数组
 */
#import <UIKit/UIKit.h>

@interface ZMOCJavaScripeBridge : NSObject

+ (instancetype)shareManager;

// JavaScripe 向 OC 发送信息
- (void)startJSEventMonitor:(UIWebView *)currentWebView WithCurrentClassInstance:(id)currentClassInstance;

// OC 向 JavaScripe 发送信息
- (void)sendObjcInfoWithJavaScripeString:(NSString *)JavaScripeString WithCurrentWebView:(UIWebView *)currentWebView;

@end
