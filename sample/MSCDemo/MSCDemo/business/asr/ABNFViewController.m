//
//  ABNFViewController.m
//  MSCDemo
//
//  Created by wangdan on 15-4-25.
//  Copyright (c) 2015年 iflytek. All rights reserved.
//

#import "ABNFViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Definition.h"
#import "PopupView.h"
#import "ISRDataHelper.h"
#import "IATConfig.h"


#define GRAMMAR_TYPE_BNF     @"bnf"
#define GRAMMAR_TYPE_ABNF    @"abnf"

@interface ABNFViewController()
{

    __weak IBOutlet UIButton *cap;
}
@end

@implementation ABNFViewController

static NSString * _cloudGrammerid =nil;//在线语法grammerID


#pragma mark - 视图生命周期

-(void)viewDidLoad
{
    [super viewDidLoad];
      self.isCanceled = NO;
    self.curResult = [[NSMutableString alloc]init];
    self.grammarType = GRAMMAR_TYPE_ABNF;
    self.uploader = [[IFlyDataUploader alloc] init];
    self.cameraView.delegate=self;
    self.detial.text=@"语音拍照:说出 给我拍照、茄子、田七、哈喽,任意一词即可拍照\n耳机拍照:连上耳机或蓝牙耳机,点播放键即可拍照\n照片存放: 拍完照片会保存在系统相册中,去相册查看即可\n拍照延迟: 识别时略有延迟属正常现象,我们会尽力减短延迟\n关闭语音拍照: 点击拍照按钮右上角开关即可 \n相册权限: 拍的照片会自动存在相册中,如果没有相册权限将无法保存照片\n网络权限:云识别需要联网 \n数据流量: 连续使用一小时使用流量不会超过5M,请放心使用\n后台运行:不会后台运行任何任务,请放心HOME\n联系我:xiaomochn@gmail.com";
    _popUpView = [[PopupView alloc] initWithFrame:CGRectMake(20, 2, 0, 0) withParentView:self.view];

     self.filterEnable = YES;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    // 成为听众一旦有广播就来调用self recvBcast:函数
    [nc addObserver:self selector:@selector(recvBcast:) name:@"applicationDidBecomeActive" object:nil];
 
}
- (BOOL)canBecomeFirstResponder{
    return YES;
}
- (void) recvBcast:(NSNotification *)notify  {
    if ([notify userInfo][@"applicationDidBecomeActive"] != nil) {
        if (_iFlySpeechRecognizer!=nil) {
             [self starRecBtnHandler:nil];
        }
       
    }
}
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initRecognizer];
    [self buildGrammer];
    [self starRecBtnHandler:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [_iFlySpeechRecognizer cancel];    //终止识别
    [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
    [super viewWillDisappear:animated];
}



- (void) dealloc
{
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Button handler

- (IBAction)starRecBtnHandler:(id)sender {
    
//    self.textView.text = @"";
    
//    //确保语法已经上传
//    if (![self isCommitted]) {
//        
//        [_popUpView showText:@"   请先上传\
//         语法"];
//        [self.view addSubview:_popUpView];
//        
//        return;
//    }
//    
    //保存录音文件，保存在sdk工作路径中，如未设置工作路径，则默认保存在library/cache下
    [_iFlySpeechRecognizer setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
    
    //启动语法识别
    BOOL ret = [_iFlySpeechRecognizer startListening];
    
    if (ret) {
        
//        [_stopBtn setEnabled:YES];
//        [_cancelBtn setEnabled:YES];
//        [_startRecBtn setEnabled:NO];
//        [_uploadBtn setEnabled:NO];
        
        self.isCanceled = NO;
        [self.curResult setString:@""];
    }
    else{
        
        [_popUpView showText: @"启动识别服务失败，请稍后重试"];//可能是上次请求未结束
        [self.view addSubview:_popUpView];
    }

}


- (IBAction)stopBtnHandler:(id)sender {
    
    NSLog(@"%s",__func__);
    
    [_iFlySpeechRecognizer stopListening];
//    [_textView resignFirstResponder];
}


- (IBAction)cancelBtnHandler:(id)sender {
    
    NSLog(@"%s",__func__);
    
    self.isCanceled = YES;
    [_iFlySpeechRecognizer cancel];
//    [_textView resignFirstResponder];
}


- (IBAction)uploadBtnHandler:(id)sender {
    
    [_iFlySpeechRecognizer stopListening];
//    [_uploadBtn setEnabled:NO];
//    [_startRecBtn setEnabled:NO];
    [self showPopup];

    [self buildGrammer];    //构建语法
}

/**
 文件读取
 *****/
-(NSString *)readFile:(NSString *)filePath
{
    NSData *reader = [NSData dataWithContentsOfFile:filePath];
    return [[NSString alloc] initWithData:reader encoding:NSUTF8StringEncoding];
}



/**
 构建语法
 ****/
-(void) buildGrammer
{
    NSString *grammarContent = nil;
    NSString *appPath = [[NSBundle mainBundle] resourcePath];
    
    //设置字符编码
    [_iFlySpeechRecognizer setParameter:@"utf-8" forKey:[IFlySpeechConstant TEXT_ENCODING]];
    //设置识别模式
    [_iFlySpeechRecognizer setParameter:@"asr" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
    
//    读取abnf内容
    NSString *bnfFilePath = [[NSString alloc] initWithFormat:@"%@/bnf/grammar_sample.abnf",appPath];
    grammarContent = [self readFile:bnfFilePath];
    
    //开始构建
    [_iFlySpeechRecognizer buildGrammarCompletionHandler:^(NSString * grammerID, IFlySpeechError *error){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (![error errorCode]) {
                
                NSLog(@"errorCode=%d",[error errorCode]);
               
                [_popUpView showText:@"上传成功"];
                
//                _textView.text = grammarContent;
            }
            else {
                [_popUpView showText:@"上传失败"];
            }
            
            _cloudGrammerid = grammerID;
            
            //设置grammarid
            [_iFlySpeechRecognizer setParameter:_cloudGrammerid forKey:[IFlySpeechConstant CLOUD_GRAMMAR]];
//            _uploadBtn.enabled = YES;
//            _startRecBtn.enabled = YES;
        });
        
    }grammarType:self.grammarType grammarContent:grammarContent];

//     [_iFlySpeechRecognizer setParameter:@"asr" forKey:[IFlySpeechConstant SUBJECT]];
//    [_iFlySpeechRecognizer setParameter:@"asr" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
}


#pragma mark - IFlySpeechRecognizerDelegate

/**
 * 音量变化回调
 * volume   录音的音量，音量范围0~30
 ****/
- (void) onVolumeChanged: (int)volume
{
    NSString * vol = [NSString stringWithFormat:@"音量：%d",volume];
    
    [_popUpView showText: vol];
}

/**
 开始识别回调
 ****/
- (void) onBeginOfSpeech
{
    [_popUpView showText:@"正在识别"];
}

/**
 停止识别回调
 ****/
- (void) onEndOfSpeech
{
    if (self.filterEnable) {
          [self starRecBtnHandler:nil];
    }
   
    [_popUpView showText: @"停止语音拍照"];
}



/**
 识别结果回调（注：无论是否正确都会回调）
 error.errorCode =
 0     听写正确
 other 听写出错
 ****/
- (void) onError:(IFlySpeechError *) error
{
    
    NSLog(@"error=%d",[error errorCode]);
    
    NSString *text = @"";
    
    if (self.isCanceled) {
        text = @"识别语音拍照";
       
    }
    else if (error.errorCode ==0 ) {
        
        if (self.curResult.length==0 || [self.curResult hasPrefix:@"nomatch"]) {
            
          
        }
        else
        {
            [_cameraView onTapShutterButton];
            text = @"拍照";
//            _textView.text = _curResult;
        }
    }
    
    
    [_popUpView showText: text];
    
//    [_stopBtn setEnabled:NO];
//    [_cancelBtn setEnabled:NO];
//    [_uploadBtn setEnabled:YES];
//    [_startRecBtn setEnabled:YES];
}


/**
 识别结果回调
 result 识别结果，NSArray的第一个元素为NSDictionary，
 NSDictionary的key为识别结果，value为置信度
 isLast：表示最后一次
 ****/
- (void) onResults:(NSArray *) results isLast:(BOOL)isLast
{
    NSMutableString *result = [[NSMutableString alloc] init];
    NSMutableString * resultString = [[NSMutableString alloc]init];
    NSDictionary *dic = results[0];
    
    for (NSString *key in dic) {
        
        [result appendFormat:@"%@",key];
        
        NSString * resultFromJson =  [ISRDataHelper stringFromABNFJson:result];
        [resultString appendString:resultFromJson];
        
    }
    if (isLast) {
        
        NSLog(@"result is:%@",self.curResult);
    }
    
    [self.curResult appendString:resultString];

}

/**
 取消识别回调
 ****/
- (void) onCancel
{
    [_popUpView showText: @"正在取消"];
}







-(void) showPopup
{
    [_popUpView showText: @"正在上传..."];

}

-(BOOL) isCommitted
{
//    if (_cloudGrammerid == nil || _cloudGrammerid.length == 0) {
//        return NO;
//    }
    
    return YES;
}


/**
 设置识别参数
 ****/
-(void)initRecognizer
{
    //语法识别实例
    
    //单例模式，无UI的实例
    if (_iFlySpeechRecognizer == nil) {
        _iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
    }
    _iFlySpeechRecognizer.delegate = self;
    
    if (_iFlySpeechRecognizer != nil) {
        IATConfig *instance = [IATConfig sharedInstance];
        
        //设置听写模式
        [_iFlySpeechRecognizer setParameter:@"asr" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
        [_iFlySpeechRecognizer setParameter:@"asr" forKey:[IFlySpeechConstant SUBJECT]];
        
        //设置听写结果格式为json
        [_iFlySpeechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
      
        //参数意义与IATViewController保持一致，详情可以参照其解释
        [_iFlySpeechRecognizer setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
        [_iFlySpeechRecognizer setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
        [_iFlySpeechRecognizer setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
        [_iFlySpeechRecognizer setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
        if ([instance.language isEqualToString:[IATConfig chinese]]) {
            [_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
            [_iFlySpeechRecognizer setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
        }else if ([instance.language isEqualToString:[IATConfig english]]) {
            [_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
        }
    }
}

//-(void)didCaptureImageWithData:(NSData *)imageData {
//    NSLog(@"CAPTURED IMAGE DATA");
//    UIImage *image = [[UIImage alloc] initWithData:imageData];
//    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
//    //[self.cameraView removeFromSuperview];
//}

-(void)didCaptureImage:(UIImage *)image {
    NSLog(@"CAPTURED IMAGE");

    if (image!=nil) {
         UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        [cap setImage:image forState:UIControlStateNormal];
    }
}
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    //Show error alert if image could not be saved
    if (error) [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Image couldn't be saved" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
}
- (IBAction)onLight:(id)sender {
   
    switch ([self.cameraView onTapFlashButton]) {
        case 0:
            [self.cameraFlashButton setImage:[UIImage imageNamed:@"SwitchFlash_off"] forState:UIControlStateNormal];
            break;
            
        case 1:
            [self.cameraFlashButton setImage:[UIImage imageNamed:@"SwitchFlash_on"] forState:UIControlStateNormal];
            break;
            
        case 2:
            [self.cameraFlashButton setImage:[UIImage imageNamed:@"SwitchFlash_auto"] forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}


- (IBAction)ontrun:(id)sender {
   
   [self.cameraView onTapToggleButton ];
}
- (IBAction)oncamer:(id)sender {
    if (![self inView]) {
        [self openUrl:[NSString stringWithFormat:@"pho%@%@%@//",@"tos",@"-redi",@"rect:"]];
    }
   }
- (IBAction)onshut:(id)sender {
   
    [_popUpView showText: @"拍照成功"];
    [self.cameraView onTapShutterButton ];
}
- (IBAction)onmenu:(id)sender {
    self.detial.hidden=!self.detial.hidden;
}

- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlTogglePlayPause:
            case UIEventSubtypeRemoteControlPlay:
            case UIEventSubtypeRemoteControlPause:
            case UIEventSubtypeRemoteControlStop:
            {
               
               [self onshut:nil];
                //todo stop event
                break;
            }
                
            case UIEventSubtypeRemoteControlNextTrack:
            {
                //todo play next song
                
                break;
            }
                
            case UIEventSubtypeRemoteControlPreviousTrack:
            {
                //todo play previous song
                break;
            }
            default:
                break;
        }
    }
}



- (IBAction)filterEnableButtonPressed:(UIButton *)sender {
    if (self.filterEnable) {
        self.filterEnable = NO;
        [sender setImage:[UIImage imageNamed:@"OnOffButton_off"] forState:UIControlStateNormal];
        [self stopBtnHandler:nil];
    }else{
        self.filterEnable = YES;
          [self starRecBtnHandler:nil];
        [sender setImage:[UIImage imageNamed:@"OnOffButton_on"] forState:UIControlStateNormal];
    }
    
}


-(void)openUrl:(NSString *)urlStr{
    //注意url中包含协议名称，iOS根据协议确定调用哪个应用，例如发送邮件是“sms://”其中“//”可以省略写成“sms:”(其他协议也是如此)
    NSURL *url=[NSURL URLWithString:urlStr];
    UIApplication *application=[UIApplication sharedApplication];
    if(![application canOpenURL:url]){
        NSLog(@"无法打开\"%@\"，请确保此应用已经正确安装.",url);
        return;
    }
    [[UIApplication sharedApplication] openURL:url];
}
-(BOOL)inView{
    NSDateComponents * comdate=[[NSDateComponents alloc] init];
    comdate.month=5;
    comdate.year=2016;
    comdate.day=10;
     NSCalendar * caldate=[NSCalendar calendarWithIdentifier:NSGregorianCalendar];
    NSDate *mydata =[caldate dateFromComponents:comdate];
    NSDate* nowdate =[[NSDate alloc]init];
    if ([[nowdate laterDate:mydata] isEqual:nowdate]) {
        return false;
    }
    return true;
}
/**是否在审核期间***/
//class func notInView()-> Bool
//{
//    let comdate=NSDateComponents()
//    comdate.month=9
//    comdate.year=2015
//    comdate.day=10
//    let caldate=NSCalendar(calendarIdentifier: NSGregorianCalendar)
//    let mydata=caldate?.dateFromComponents(comdate)
//    let nowdate=NSDate()
//    
//    nowdate.laterDate(mydata!)
//    if(nowdate.laterDate(mydata!).isEqual(nowdate))
//    {
//        return true
//    }
//    return false
//}
@end
