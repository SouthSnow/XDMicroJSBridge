//
//  XDViewController_WK.m
//  XDMicroJSBridge_Example
//
//  Created by 蔡欣东 on 2018/6/20.
//  Copyright © 2018年 458770054@qq.com. All rights reserved.
//

#import "XDViewController_WK.h"
#import "XDMicroJSBridge_WK.h"
#import "Base64.h"

@interface XDViewController_WK ()<WKNavigationDelegate,WKUIDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>


@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, strong) XDMicroJSBridge_WK *bridge;

@property (nonatomic, copy) XDMCJSBCallback callback;

@property (nonatomic, strong) UIImagePickerController *cameraVC;

@property (nonatomic, strong) UIButton *nativeBtn;

@end

@implementation XDViewController_WK

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"XDMicroJSBridge_WK demo";
    
    self.bridge = [[XDMicroJSBridge_WK alloc] init];
    self.webView = [_bridge getBridgeWebView];
    
    WKUserScript *injectScript = [[WKUserScript alloc] initWithSource:@"var nameSpace = 'demo'" injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [self.webView.configuration.userContentController addUserScript:injectScript];

    
    _bridge.nameSpace = @"demo";
    _webView.UIDelegate = self;
    _webView.navigationDelegate = self;
    _webView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:_webView];
    
    _nativeBtn  = [[UIButton alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 200)/2, self.view.frame.size.height - 50, 200, 20)];
    [_nativeBtn setTitle:@"native btn" forState:UIControlStateNormal];
    [_nativeBtn addTarget:self action:@selector(_nativeClick) forControlEvents:UIControlEventTouchUpInside];
    [_nativeBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.view addSubview:_nativeBtn];
    [self.view bringSubviewToFront:_nativeBtn];

    NSURL *path = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"html"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:path]];

    self.cameraVC = [[UIImagePickerController alloc] init];
    _cameraVC.delegate = self;
    _cameraVC.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    __weak typeof(self) weakself = self;
    [_bridge registerAction:@"camerapicker" handler:^(NSArray *params, XDMCJSBCallback callback) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                weakself.callback = callback;
            }
            [weakself presentViewController:weakself.cameraVC animated:YES completion:nil];
        });
    }];
}

- (void)_nativeClick {
    [_bridge callAction:@"nativeClick" param:@{@"msg":@"I am from native"}];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!_webView.title) {
        [_webView reload];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

}

#pragma mark - WKUIDelegate
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
    
}
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }])];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    if ([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:@"public.image"]) {
        [picker dismissViewControllerAnimated:YES completion:nil];
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        NSData *imageData = UIImageJPEGRepresentation(image,1) ;
        if (imageData.length > 500000) {
            CGFloat ratio = 500000.0/imageData.length;
            imageData = UIImageJPEGRepresentation(image,ratio) ;
        }
        NSString *base64 = [imageData base64EncodedString];
        NSString *source = [NSString stringWithFormat:@"data:image/jpeg;base64,%@", base64];
        NSArray *soureArr = @[source];
        NSDictionary *value = @{@"photos":soureArr};
        if(self.callback) {
            self.callback(value);
        }

    }
}

- (void)dealloc {
    NSLog(@"===========wk dealoc============");
}


#pragma mark - WKNavigationDelegate
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    [webView reload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
