//
//  YMTradeBaseController.m
//  MiniPay
//
//  Created by allen on 13-12-16.
//  Copyright (c) 2013年 allen. All rights reserved.
//

#import "YMTradeBaseController.h"
#import "GDataXMLNode.h"
#import "MPosOperation.h"
#import <ExternalAccessory/ExternalAccessory.h>
#import "SignaturViewController.h"
#import "PwdAllertViewController.h"
#import "KoulvListViewController.h"
#import "KouLvModel.h"
@interface YMTradeBaseController ()
{
   // BOOL isfrist;
    PwdAllertViewController *pwdAllertViewController;
    KoulvListViewController *koulvListViewController;
    
     EAAccessoryManager *eam;
}

@end

@implementation YMTradeBaseController
@synthesize accessoryList=_accessoryList;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        }
    return self;
}

- (void)viewDidLoad

{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
 
    window = [self systemWindow];
    NSArray *views1 = [[NSBundle mainBundle] loadNibNamed:@"InsertPosView" owner:self options:nil];
    insertPosView = [views1 objectAtIndex:0];
    insertPosView.frame = window.frame;
    
    NSArray *views2 = [[NSBundle mainBundle] loadNibNamed:@"CheckPosView" owner:self options:nil];
    checkPosView = [views2 objectAtIndex:0];
    checkPosView.frame = window.frame;
    
    NSArray *views3 = [[NSBundle mainBundle] loadNibNamed:@"SwipeAnimationView" owner:self options:nil];
    swipeView = [views3 objectAtIndex:0];
    swipeView.frame = window.frame;
    
    NSArray *views4 = [[NSBundle mainBundle] loadNibNamed:@"TradingView" owner:self options:nil];
    tradeView = [views4 objectAtIndex:0];
    tradeView.frame = window.frame;
    
    //是否是QPOS刷卡器
   // isQpos=_dataManager.isQpos;
    
    mPosOperationDelegate=self;
    phonerNumber=[_dataManager GetObjectWithNSUserDefaults:PHONENUMBER];
    tseqno=@"000001";
   

    //初始化对象，爱迷你付对象
    //初始化Qpost对象===========
    
    switch (_dataManager.device_Type) {
            
        case Vpos:
            m_vcom = [vcom getInstance];
            [m_vcom open];
            [m_vcom setMode:VCOM_TYPE_FSK recvMode:VCOM_TYPE_F2F]; //设置数据发送模式和接收模式
            [m_vcom setMac:FALSE];
           // m_vcom.eventListener=self;
            break;
        case Qpos:
            [ZftQiposLib setContectType:0];
//            qpos=[ZftQiposLib getInstance];
//            [qpos setLister:self];
            break;
        case D180:
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessoryConnected:) name:EAAccessoryDidConnectNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessoryDisConnected:) name:EAAccessoryDidDisconnectNotification object:nil];
                        eam = [EAAccessoryManager sharedAccessoryManager];
            _accessoryList = [[NSMutableArray alloc] initWithArray: [eam connectedAccessories]];
            selectedBTMac = @"00:00:00:00:00:00";
            if (_accessoryList.count > 0) {
                selectedBTMac = [_accessoryList[0] valueForKey:@"macAddress"];
            }
            opq = [[NSOperationQueue alloc] init];
            [opq setMaxConcurrentOperationCount:3];
            op = [[MPosOperation alloc] initWithType:OPER_START withName:@"start" withArgNum:1 withArgs:[[NSArray alloc] initWithObjects:selectedBTMac, nil] withDelegate:mPosOperationDelegate];
            [opq addOperation:op];
           break;
        case BPOS:
            
            [[CSwiperController sharedController] setDelegate:self];

        default:
            
            break;
    }
    
    //初始化Qpost对象===========
//    qpos=[ZftQposLib getInstance];
//    [qpos setLister:self];
    if(_dataManager.device_Type==SKTPOS)
    {
        _identify=10;
        //初始化对象
        m_vcom = [vcom getInstance];
        [m_vcom open];
        
        m_vcom.eventListener=self;
        //设置数据发送模式和接收模式
        [m_vcom setMode:VCOM_TYPE_F2F recvMode:VCOM_TYPE_F2F];
        //[m_vcom setMode:VCOM_TYPE_FSK recvMode:VCOM_TYPE_FSK];
        //    [m_vcom setVloumn:75];
        
        [m_vcom setMac:false];
    }
    else{
    _identify=0;
    }
    _D180identify=0;
    _Bposidentify=0;
    swipeView.stopBlock=^(void){
        
        
   switch (_dataManager.device_Type) {

     case Vpos:
         [m_vcom Request_Exit];
        break;
    case Qpos:
            [[ZftQiposLib getInstance] powerOff];
        break;
    case D180:
        
        break;
    case SKTPOS:
           [m_vcom StopRec];
           [m_vcom close];
        break;
       case BPOS:
           [[CSwiperController sharedController] stopCSwiper];
           break;
           
          
    default:
        
        break;
   }
      
       
};
    
   // [self addobserver];
    
}


- (void)accessoryConnected:(NSNotification *)notification
{
    EAAccessory *connectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];
    
    NSLog(@"accessory connected! mac is : %@", [connectedAccessory valueForKey:@"macAddress"]);
    EAAccessory *ea;
    BOOL found = NO;
    for (ea in _accessoryList) {
        if ([[connectedAccessory valueForKey:@"macAddress"] isEqualToString: [ea valueForKey:@"macAddress"]]) {
            found = YES;
            NSLog(@"found in accesory list");
            break;
        }
    }
    
    if (!found) {
        [_accessoryList addObject:connectedAccessory];
        NSLog(@"added to accessory list");
        // FIXME! refresh view
        //[_btPicker reloadAllComponents];
    }
    
}

- (void)accessoryDisConnected:(NSNotification *)notification
{
    EAAccessory *disconnectedAccessory = [[notification userInfo] objectForKey:EAAccessoryKey];
    
    NSLog(@"accessory disconnected! mac is : %@", [disconnectedAccessory valueForKey:@"macAddress"]);
    EAAccessory *ea;
    NSInteger idx = 0;
    BOOL found = NO;
    for (ea in _accessoryList) {
        if ([[disconnectedAccessory valueForKey:@"macAddress"] isEqualToString: [ea valueForKey:@"macAddress"]]) {
            found = YES;
            NSLog(@"found in accessory list");
            break;
        }
        idx++;
    }
    
    if (found) {
        NSLog(@"to remove it from the accessory list");
        [_accessoryList removeObjectAtIndex:idx];
    }
    
    // FIXME! refresh view
    //[_btPicker reloadAllComponents];
}


-(void)getTermKoulv
{
    [self showWaiting:@""];
    NSMutableArray *array=[[NSMutableArray alloc] init];
    NSString *phonerNumber=[_dataManager GetObjectWithNSUserDefaults:PHONENUMBER];
    [array addObject:@"TRANCODE"];
    [array addObject:SENDCODE_CMD_199038];
    [array addObject:@"PHONENUMBER"];
    [array addObject:phonerNumber];
    [array addObject:@"PACKAGEMAC"];
    [array addObject:[ValueUtils md5UpStr:[CommonUtil createXml:array]]];
    
    NSString *params=[CommonUtil createXml:array];
    
    _controlCentral.requestController=self;
    [_controlCentral requestDataWithJYM:SENDCODE_CMD_199038
                             parameters:params
                     isShowErrorMessage:TRADE_URL_TYPE
                             completion:^(id result, NSError *requestError, NSError *parserError) {
                                 
                                 [self hideWaiting];
                                 //[self showWaiting:@"正在检查设备……"];
                                 if (result)
                                 {
                                     NSMutableArray *_koulvarry=[[NSMutableArray alloc]init];
                                     GDataXMLElement *rootElement=(GDataXMLElement *)result;
                                     GDataXMLElement *trandetailsElement = [[rootElement elementsForName:@"TRANDETAILS"] objectAtIndex:0];
                                     
                                     NSArray *trandetail = [trandetailsElement elementsForName:@"TRANDETAIL"];
                                     [_koulvarry removeAllObjects];
                                     for (GDataXMLElement *user in trandetail) {
                                         
                                         KouLvModel *model=[[KouLvModel alloc] init];
                                         
                                         GDataXMLElement *DUPLMT = [[user elementsForName:@"DUPLMT"] objectAtIndex:0];
                                         [model setUPLMT:[DUPLMT stringValue]];
                                         
                                         GDataXMLElement *IDFID = [[user elementsForName:@"IDFID"] objectAtIndex:0];
                                         [model setIDFID:[IDFID stringValue]];
                                         
                                         GDataXMLElement *FEERAT = [[user elementsForName:@"FEERAT"] objectAtIndex:0];
                                         [model setFEERAT:[FEERAT stringValue]];
                                         GDataXMLElement *IDFCHANNEL = [[user elementsForName:@"IDFCHANNEL"] objectAtIndex:0];
                                         [model setIDFCHANNEL:[IDFCHANNEL stringValue]];
                                         
                                         
                                         [_koulvarry addObject:model];
                                     }
                                     if(_koulvarry.count>1)
                                     {
                                         koulvListViewController = [[KoulvListViewController alloc] initWithNibName:@"KoulvListViewController" bundle:nil title:@"支付方式选择" ];
                                         koulvListViewController.array=_koulvarry;
                                         // pwdAllertViewController.lableNo.text=maskedPAN;
                                         koulvListViewController.hidViewBlock=^(void){
                                             [self hideAllView];
                                             [koulvListViewController.view removeFromSuperview];
                                             koulvListViewController=nil;
                                         };
                                         
                                         koulvListViewController.tabviewSelectBlock=^(KouLvModel *moel)
                                         {
                                             [koulvListViewController.view removeFromSuperview];
                                             koulvListViewController=nil;
                                             
                                             iDFID=moel.IDFID;
                                             [self checkIsSign];
                                         };
                                         
                                         //   // [self presentViewController:pwdAllertViewController animated:YES completion:nil];
                                         [koulvListViewController showControllerByAddSubView:self animated:NO];
                                         
                                         
                                     }
                                     else
                                     {
                                         KouLvModel *model=[_koulvarry objectAtIndex:0];
                                         iDFID=model.IDFID;
                                        [self checkIsSign];
                                        // [self conntingdevic];
                                     }
                                     
                                 }
                             }];
    
}

-(void)conntingdevic
{
    [ZftQiposLib setContectType:1];
    [[ZftQiposLib getInstance]setLister:self];


}

//验证是否签到
-(void)checkIsSign{

    termialNo=@"";
    // [self showWaiting:@"正在检测设备……"];
    [self showCheckPos];
    nowDate=[ValueUtils getNowDate];
    nowTime=[ValueUtils getNowTime];
    
    BOOL isSigned=_dataManager.isSign;
    //若签到则进行刷卡交易
    if(isSigned){
        switch (_dataManager.device_Type) {
                
            case Vpos:
                [self getPsamNumber];
                break;
            case Qpos:
                [self qPostGetPsamInfo:@"1"];
                break;
            
               case Qpos_blue:
                if([ZftQiposLib isconnect_21])
                {
                   [self qPostGetPsamInfo:@"1"];
                }
                else{
                    [[ZftQiposLib getInstance]starScan];
                
                }
                break;
            case D180:
                if(_accessoryList.count<=0)
                {
                    
                    [self showAlert:@"未找到适配的蓝牙设备，请到设置页面检查设备蓝牙是否已匹配？匹配完成后重新启动应用！"];
                    [self hideAllView];
                    return;
                    
                    
                    
                    
                }
                [self signureSuccess];

                break;
            case SKTPOS:
            {
//                [m_vcom StopRec];
//                [m_vcom startDetector:14 random:"1234" randomLen:4 data:nil datalen:0 time:30];
//                [m_vcom StartRec];
                
                //[m_vcom setMode:VCOM_TYPE_F2F recvMode:VCOM_TYPE_F2F];
                [m_vcom StopRec];
                [m_vcom setVloumn:95];
                [m_vcom Request_GetKsn];
                [m_vcom StartRec];
            }
                break;
            case BPOS:
            {
                 [[CSwiperController sharedController] getCSwiperKsn];
            }
                break;
            default:
                break;
        }
    }else {  //未签到进行签到操作
        // [self showCheckPos];
      
        switch (_dataManager.device_Type) {
                
            case Vpos:
                _identify=-1;
                [m_vcom StopRec];
                [m_vcom Request_GetExtKsn];  //请求psam卡号和终端号
                [m_vcom StartRec];
                break;
            case Qpos:
               
                
               [self qPostGetPsamInfo:@"2"];
                
                
                break;
            case Qpos_blue:
                
                [[ZftQiposLib getInstance]starScan];

                break;
            case D180:
            
                if(_accessoryList.count<=0)
                {
                    
                    [self showAlert:@"未找到适配的蓝牙设备，请到设置页面检查设备蓝牙是否已匹配？匹配完成后重新启动应用！"];
                     [self hideAllView];
                    return;
                
                    
                
                    
                }
                 
                  op = [[MPosOperation alloc] initWithType:OPER_GET_PSAMNO withName:@"getpsamno" withArgNum:0 withArgs:nil withDelegate:mPosOperationDelegate];
                  [opq addOperation:op];
                _D180identify=1;
                break;
            case SKTPOS:
            {
                [self hideAllView];
                 [self showCheckPos];
                 //[self showWaiting:@"正在检测设备！"];
                [m_vcom StopRec];
                [m_vcom setVloumn:95];
                [m_vcom Request_GetKsn];
                [m_vcom StartRec];

//                [m_vcom startDetector:14 random:"1234" randomLen:4 data:nil datalen:0 time:30];
//                [m_vcom StartRec];
//                [m_vcom setMode:VCOM_TYPE_F2F recvMode:VCOM_TYPE_F2F];
//                [m_vcom StopRec];
//                //[m_vcom setVloumn:95];
//                [m_vcom Request_GetKsn];
//                [m_vcom StartRec];
//                 _identify=-6;
//                [m_vcom startCSwiper];
            }
                break;
            case BPOS:
                [[CSwiperController sharedController] getCSwiperKsn];
                
            break;
            default:
                
                
                break;
        }
        
        

        
    }

    
}


- (void)EDYdiscoverDevice:(NSDictionary *)device
{
    [self hideAllView];
    KouLvModel *model=[[KouLvModel alloc] init];
      NSString *name = [device objectForKey:@"name"];
    [model setIDFCHANNEL:name];
    [devicList addObject:model];
    
    if(koulvListViewController==NULL)
    {
      koulvListViewController = [[KoulvListViewController alloc] initWithNibName:@"KoulvListViewController" bundle:nil title:@"蓝牙选择" ];
       koulvListViewController.array=devicList;
      //koulvListViewController.title_lable.text=@"蓝牙选择";
      // pwdAllertViewController.lableNo.text=maskedPAN;
      koulvListViewController.hidViewBlock=^(void){
        [self hideAllView];
        [koulvListViewController.view removeFromSuperview];
        koulvListViewController=nil;
    };
    
    koulvListViewController.tabviewSelectBlock=^(KouLvModel *moel)
    {
        [self showWaiting:@""];
        [koulvListViewController.view removeFromSuperview];
        koulvListViewController=nil;
        [[ZftQiposLib getInstance] stopScan];
        [[ZftQiposLib getInstance] connectDevice:moel.IDFCHANNEL];
        
      
    };
        
         [koulvListViewController showControllerByAddSubView:self animated:NO];
    }
    else
    {
        [koulvListViewController reloadData:devicList];
    }
//
    
//    NSLog(@"%@",device);
//    [devicList addObject:[device objectForKey:@"name"]];
//    [[ZftQiposLib getInstance] connectDevice:[device objectForKey:@"name"]];
   }


-(void)EDYonPlugin
{
    if([ZftQiposLib isconnect_21])
    {
         [self qPostGetPsamInfo:@"2"];
    }
   
}



- (void)onDecodeCompleted:(NSDictionary *)decodeData
{
     switch (_Bposidentify)
    {
        
        case 2:
        {
            trackInfo=[NSString stringWithFormat:@"%@%@",[decodeData objectForKey:@"encTrack2"],[decodeData objectForKey:@"encTrack3"]];
            cardNoInfo=[decodeData objectForKey:@"PAN"];
            [self hideAllView];
            if(IsNilString(cardNoInfo))
            {
                [self showAlert:@"获取卡号信息失败！"];
                 [[CSwiperController sharedController] stopCSwiper];
                return;
            }
            
            pwdAllertViewController = [[PwdAllertViewController alloc] initWithNibName:@"PwdAllertViewController" bundle:nil cardNo:cardNoInfo];
            // pwdAllertViewController.lableNo.text=maskedPAN;
            pwdAllertViewController.hidViewBlock=^(void){
               
                [pwdAllertViewController.view removeFromSuperview];
                pwdAllertViewController=nil;
            };
            pwdAllertViewController.okBlock=^(NSString*str)
            {
                [pwdAllertViewController.view removeFromSuperview];
                pwdAllertViewController=nil;
                
                [self showTrading];
                NSString *pinBlock =[CommonUtil getpinblock:cardNoInfo andpwd:str];
               // pinkey_All=@"EE8C7FAD17D9BD050639E7F5D6161C0D61325A02";
                NSString *tpkInHex =[pinkey_All substringWithRange:NSMakeRange(0, pinkey_All.length-8)];
                NSString *kcvInHex =[NSString stringWithFormat:@"%@%@", [pinkey_All substringWithRange:NSMakeRange(pinkey_All.length-8, 8)], @"00000000"];
                NSMutableDictionary *encryptOptionDict = [NSMutableDictionary dictionary];
                [encryptOptionDict setObject:[NSNumber numberWithInt:EncryptionMethod_TDES_CBC] forKey:@"encryptionMethod"];
                [encryptOptionDict setObject:[NSNumber numberWithInt:EncryptionKeySource_BY_SERVER_16_BYTES_WORKING_KEY] forKey:@"encryptionKeySource"];
                [encryptOptionDict setObject:[NSNumber numberWithInt:EncryptionPaddingMethod_ZERO_PADDING] forKey:@"encryptionPaddingMethod"];
                [encryptOptionDict setObject:tpkInHex forKey:@"encWorkingKey"];
                [encryptOptionDict setObject:[kcvInHex substringWithRange:NSMakeRange(0, 6)] forKey:@"kcvOfWorkingKey"];
                [encryptOptionDict setObject:pinBlock forKey:@"data"];
                NSLog(@"encryptOptionDict: %@", encryptOptionDict);
                [[CSwiperController sharedController] encryptDataWithSettings:[NSDictionary dictionaryWithDictionary:encryptOptionDict]];
                _Bposidentify=3;
                
            };
            //   // [self presentViewController:pwdAllertViewController animated:YES completion:nil];
            [pwdAllertViewController showControllerByAddSubView:self animated:NO];

        }
     break;
     
            
      
    }
    
}

- (void)onEncryptDataCompleted:(NSDictionary *)encryptDataResponse{
    
    switch (_Bposidentify)
    {
     case 1:
      {
          _dataManager.isSign=YES;
        macEncrypt = [encryptDataResponse objectForKey:@"mac"];
        NSArray *encWorkingKeys = [NSArray arrayWithObjects:
                                   [deskey_All substringWithRange:NSMakeRange(0, deskey_All.length-8)], nil];
        NSArray *kcvOfWorkingKeys = [NSArray arrayWithObjects:
                                    [deskey_All substringWithRange:NSMakeRange(deskey_All.length-8, 8)], nil];
        
         [[CSwiperController sharedController] startCSwiper:1
                                            encWorkingKeys:encWorkingKeys
                                          kcvOfWorkingKeys:kcvOfWorkingKeys];
          [self hideAllView];
          [self showSwipCard];
          _Bposidentify=2;
      }
     break;
        case 3:
            pinInfo=[encryptDataResponse objectForKey:@"encData"];
            [self finishGetMac];
            break;
    }
   
}


- (void)onGetKsnCompleted:(NSString *)ksn
{
    switch (_dataManager.device_Type) {
            
        case SKTPOS:
            
            termialNo = [ksn uppercaseStringWithLocale:[NSLocale currentLocale]];
            [self performSelector:@selector(gettermiaNo) withObject:nil afterDelay:0.6];
            break;
        case BPOS:
            termialNo=[ksn uppercaseString];
            pasamNo=[ksn uppercaseString];
            if(!_dataManager.isSign)
            [self doSigned];
            else
            {
                [self signureSuccess];
            
            }
            break;
       
    }
    
    // [self gotosignaturview];
}


- (void)onTimeout{
    [self hideAllView];
    
    DLog(@"======超时了");
    [self showAlert:@"刷卡超时！"];
}


- (void)onError:(int)errorType message:(NSString *)message{
    [self hideAllView];
    [self showAlert:message];
}

-(void)gettermiaNo
{
    [self hideAllView];
    if(![_dataManager.TerminalSerialNumber isEqualToString:termialNo])
    {
        
        [self showAlert:@"该终端与当前商户绑定的终端不符，请检查终端是否正确！"];
        
        [m_vcom StopRec];
        [m_vcom close];
        
        return;
        
    }
    [m_vcom StopRec];
    [self showSwipCard];
    [m_vcom startDetector:14 random:"1234" randomLen:4 data:nil datalen:0 time:30];
    [m_vcom StartRec];


}

//Qpos获取数卡器和终端号等信息
-(void)qPostGetPsamInfo:(NSString *)index{
    
     [[ZftQiposLib getInstance] doGetTerminalID];
    
//    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(getQposPsam:) userInfo:index repeats:NO];

}


-(void)EDYgetTerminalID:(NSString *)terminalId
{
    
    
    
    termialNo= terminalId;
    pasamNo= [[ZftQiposLib getInstance] getPsamID];
    
    if(!IsNilString(pasamNo)){
        pasamNo=[AESUtil changePsamNo:pasamNo];
        if(_dataManager.isSign){
            [self signureSuccess];
        }else{
            
            
            [self doSigned];
        }
        
    }else{
        //        [self hideCheckPos];
        [self hideAllView];
        [self showAlert:@"获取设备信息失败"];
    }
}


-(void)getQposPsam:(NSTimer *)timer{
    
    NSString *index=[timer userInfo];
    
    termialNo= [[ZftQiposLib getInstance] getTerminalID];
    pasamNo= [[ZftQiposLib getInstance] getPsamID];
//    if(![_dataManager.TerminalSerialNumber isEqualToString:termialNo])
//    {
//        [self showAlert:@"该终端与当前商户绑定的终端不符，请检查终端是否正确！"];
//        [self hideAllView];
//        return;
//        
//    }
    if(!IsNilString(pasamNo)){
       pasamNo=[AESUtil changePsamNo:pasamNo];
        if([index isEqualToString:@"1"]){
            [self signureSuccess];
        }else if([index isEqualToString:@"2"]){
           
           
            [self doSigned];
        }
       
    }else{
//        [self hideCheckPos];
        [self hideAllView];
        [self showAlert:@"获取设备信息失败"];
    }
    
    
    DLog(@"\n--Qpos获取到的设备号:%@---psam号:%@\n",termialNo,pasamNo);
    
}


//更新QPOS刷卡器秘钥
-(void)updateQpostMac:(NSString *)deskey pinkey:(NSString *)pinkey mackey:(NSString *)mackey{
    
    NSString *str=[NSString stringWithFormat:@"%@%@%@",deskey,pinkey,mackey];
    DLog(@"\n========Qpos开始签到=======\n%@",str);
     [[ZftQiposLib getInstance] doSignIn:str];
    
    
    
}


//更新爱创刷卡器秘钥
-(void)updateAiMac:(NSString *)deskey pinkey:(NSString *)pinkey mackey:(NSString *)mackey{
    
        char * pin=HexToBin((char *)[pinkey UTF8String]);
        int pindatalen = [pinkey length]/2;
        char pindata[pindatalen];
        memcpy(pindata, pin, pindatalen);
        
        char * mac=HexToBin((char *)[mackey UTF8String]);
        int macdatalen = [mackey length]/2;
        char macdata[pindatalen];
        memcpy(macdata, mac, macdatalen);
        
        char * des=HexToBin((char *)[deskey UTF8String]);
        int desdatalen = [deskey length]/2;
        char desdata[desdatalen];
        memcpy(desdata, des, desdatalen);
        
        _identify=-2;
        //更新mac算法秘钥
        [m_vcom StopRec];
        [m_vcom Request_ReNewKey:0 PinKey:pindata PinKeyLen:pindatalen MacKey:macdata MacKeyLen:macdatalen DesKey:desdata DesKeyLen:desdatalen];
        [m_vcom StartRec];
    
    
}

//签到成功后判断当前的psam卡号和设备终端号是否为空，若为空则重新获取
//为下一步刷卡准备
-(void)getPsamNumber{
    
    
    if(IsNilString(pasamNo) || IsNilString(termialNo)){
        
        _identify=-3;
        [m_vcom StopRec];
        [m_vcom Request_GetExtKsn];
        [m_vcom StartRec];
       
        
    }else{
        
        [self signureSuccess];
        
    }

    
}

//签到成功
-(void)signureSuccess{
    [self hideAllView];
    
    //[self hideCheckPos];
    //[self hideWaiting];
    
    //[self showWaiting:@"请刷卡…"];
    [self showSwipCard];
    char *cmoney;
    const int len=tmpMoney.length;;
    
    switch (_dataManager.device_Type) {
            
        case Vpos:
            
            cmoney=new char(len+1);
            strcpy(cmoney, [tmpMoney UTF8String]);
            _identify=-4;
            [m_vcom StopRec];
            [m_vcom Request_ExtCtrlConOper:1 PINKeyIndex:1 DESKeyInex:1 MACKeyIndex:1 CtrlMode:0x1f ParameterRandom:(char *)"" ParameterRandomLen:0 cash:cmoney cashLen:len appendData:(char *)"" appendDataLen:0 time:60];
            [m_vcom StartRec];
            
            break;
        case Qpos:
            [self qPosSwipCard];
            
            break;
        case Qpos_blue:
            [self qPosSwipCard];
            
            break;
        case D180:
            op = [[MPosOperation alloc] initWithType:OPER_GET_PSAMNO withName:@"getpsamno" withArgNum:0 withArgs:nil withDelegate:mPosOperationDelegate];
            [opq addOperation:op];
            _D180identify=1;
            
            break;
        case BPOS:
           
            [self BposSwipCard];
            

        default:
            
            break;
    }

    
}


- (void)taskFinishedWithResult:(NSString *)result; {
    if ([result isEqualToString:@"通讯错误"])
    {
        [self showAlert:@"未找到适配的蓝牙设备，请到设置页面检查设备蓝牙是否已匹配？匹配完成后重新启动应用！"];
        [self hideAllView];
        return;
    }
   else if ([result isEqualToString:@"刷卡取消"])
    {
        [self showAlert:result];
//        op = [[MPosOperation alloc] initWithType:STOP withName:@"" withArgNum:1 withArgs:nil withDelegate:mPosOperationDelegate];
//        [opq addOperation:op];
        [self hideAllView];
        _D180identify=0;
        return;
    }
    
    
    switch (_D180identify) {
        case 1:
            _D180identify=2;
            pasamNo=result;
            op = [[MPosOperation alloc] initWithType:OPER_GET_SN withName:@"getsn" withArgNum:0 withArgs:nil withDelegate:mPosOperationDelegate];
            [opq addOperation:op];
            break;
        case 2:
            termialNo=result;
            if(![_dataManager.TerminalSerialNumber isEqualToString:termialNo])
            {
                [self showAlert:@"该终端与当前商户绑定的终端不符，请检查终端是否正确！"];
                [self hideAllView];
                return;
            }
            if(!_dataManager.isSign)
              [self doSigned];
            else
            {[self d180SwipCard];}
            break;
        case 3:
            _D180identify=4;
            _dataManager.isSign=YES;
            [self d180SwipCard];
            break;
        case 4:
            [self hideAllView];
            [self showSwipCard];
            macEncrypt=result;
            _D180identify=5;
             op = [[MPosOperation alloc] initWithType:OPER_SWIPE withName:@"swipe" withArgNum:1 withArgs:[[NSArray alloc] initWithObjects:tmpMoney1, nil] withDelegate:mPosOperationDelegate];
            [opq addOperation:op];

            break;
        case 5:
            _D180identify=6;
            trackInfo=result;
             op = [[MPosOperation alloc] initWithType:OPER_GET_PIN withName:@"getpin" withArgNum:0 withArgs:nil withDelegate:mPosOperationDelegate];
             [opq addOperation:op];
            break;
         case 6:
          
           pinInfo=result;
            cardNoInfo=@"";
            if([pinInfo isEqualToString:@"输入密码取消"]||[trackInfo isEqualToString:@"刷卡取消"]||IsNilString(trackInfo)||[trackInfo isEqualToString:@"OK"])
            {
                [self showAlert:result];
                [self hideAllView];
                return;
            
            }
            [self finishGetMac];
            //[self gotosignaturview];
           // _D180identify=7;
            break;
        case 7:
            
            break;
            
        default:
            break;
    }
      }


-(void)gotosignaturview
{

    //转向签名页面
        SignaturViewController *signature=[[SignaturViewController alloc] init];
         signature.finshcaedBlock=^(NSString*signatureImageSt){
        [self finishGetMac];
    };

      //  signature.logno=logno;
    //    signature.type=1;   //代表交易
    //    double mon=[tmpMoney doubleValue]/100;
    //    signature.money=[NSString stringWithFormat:@"%.2f",mon];
    //    signature.hidesBottomBarWhenPushed=YES;
    signature.hidesBottomBarWhenPushed=YES;
     [self.navigationController pushViewController:signature animated:YES];



}


//Bpos
-(void)BposSwipCard{}

//Qpos刷卡
-(void)qPosSwipCard{
    
    
    
}

-(void)d180SwipCard
{

}

//执行刷卡完毕
-(void)finishSwipCard{
    
    
    
}

//用户签到操作
-(void)doSigned{
    
    
    if(IsNilString(pasamNo) || IsNilString(termialNo)){
        [self hideAllView];
        [self showAlert:@"签到失败"];
        return;
    }
     [self hideAllView];
    [self showWaiting:@"正在签到！"];
    
    
    NSMutableArray *array=[[NSMutableArray alloc] init];
    
    [array addObject:@"TRANCODE"];
    [array addObject:SIGNED_CMD_199020];
    
    [array addObject:@"PHONENUMBER"];
    [array addObject:phonerNumber];
    
    [array addObject:@"TERMINALNUMBER"];  //设备终端号
    [array addObject:termialNo];
    
    [array addObject:@"PSAMCARDNO"];  //psam卡号-UN201010000111
    [array addObject:pasamNo];
    
    [array addObject:@"TERMINALSERIANO"];  //订单编号
    [array addObject:@"000001"];
    
    
    NSString *paramXml=[CommonUtil createXml:array];
    NSString *PACKAGEMAC=[ValueUtils md5UpStr:paramXml];
    
    [array addObject:@"PACKAGEMAC"];
    [array addObject:PACKAGEMAC];
    
   // NSString *md5=[ValueUtils md5UpStr:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><EPOSPROTOCOL><TRACK>6217730200128815D2314030665C5DE30E7900</TRACK><TSEQNO>000002</TSEQNO><CTXNAT>000000000001</CTXNAT><TPINBLK>29179F6B7F40E2A0</TPINBLK><PCSIM>获取不到</PCSIM><CRDNO>6217730200128815</CRDNO><TRANCODE>199005</TRANCODE><PHONENUMBER>18566205799</PHONENUMBER><CHECKX>40.702677</CHECKX><APPTOKEN>apptoken</APPTOKEN><CHECKY>-74.011277</CHECKY><TERMINALNUMBER>5010100233090000</TERMINALNUMBER><TTXNTM>154330</TTXNTM><TTXNDT>0212</TTXNDT><PSAMCARDNO>UN501010023309</PSAMCARDNO><MAC>39463431</MAC></EPOSPROTOCOL>"];
    
    NSString *params=[CommonUtil createXml:array];
    //params=@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><EPOSPROTOCOL><TRANCODE>199020</TRANCODE><PHONENUMBER>18566205799</PHONENUMBER><TERMINALNUMBER>5010100233090000</TERMINALNUMBER><PSAMCARDNO>UN501010023309</PSAMCARDNO><TERMINALSERIANO>000001</TERMINALSERIANO><PACKAGEMAC>DBA971BC27EAA46C832D4CEB9C6DFE7C</PACKAGEMAC></EPOSPROTOCOL>";
    
    _controlCentral.requestController=self;
    [_controlCentral requestDataWithJYM:SIGNED_CMD_199020
                             parameters:params
                     isShowErrorMessage:TRADE_URL_TYPE
                             completion:^(id result, NSError *requestError, NSError *parserError) {
                                 
                                 if (result)
                                 {
                                     GDataXMLElement *rootElement=(GDataXMLElement *)result;
                                     GDataXMLElement *encryptkeyElement = [[rootElement elementsForName:@"ENCRYPTKEY"] objectAtIndex:0];
                                     NSString *deskey=[encryptkeyElement stringValue];
                                     
                                     GDataXMLElement *pinkeyElement = [[rootElement elementsForName:@"PINKEY"] objectAtIndex:0];
                                     NSString *pinkey=[pinkeyElement stringValue];
                                     
                                     GDataXMLElement *mackeyElement = [[rootElement elementsForName:@"MACKEY"] objectAtIndex:0];
                                     NSString *mackey=[mackeyElement stringValue];
                                     
                                     //签到成功w
                                     if(!IsNilString(deskey) && !IsNilString(pinkey) && !IsNilString(mackey)){
                                         
                                         
                                         switch (_dataManager.device_Type) {
                                                 
                                             case Vpos:
                                                 [self updateAiMac:deskey pinkey:pinkey mackey:mackey];

                                                    break;
                                             case Qpos:
                                                [self updateQpostMac:deskey pinkey:pinkey mackey:mackey];
                                                 break;
                                             case Qpos_blue:
                                                 [self updateQpostMac:deskey pinkey:pinkey mackey:mackey];
                                                 break;

                                             case D180:
                                                 _D180identify=3;
                                                 op = [[MPosOperation alloc] initWithType:OPER_WRITE_KEY withName:@"writekey" withArgNum:3 withArgs:[NSArray arrayWithObjects:pinkey,mackey,deskey, nil] withDelegate:mPosOperationDelegate];
                                                  [opq addOperation:op];
                                                 
                                                 break;
                                             case BPOS:
                                                 pinkey_All=pinkey;
                                                 mackey_All=mackey;
                                                 deskey_All=deskey;
                                                 [self BposSwipCard];
                                                 
                                                 
                                                 break;
                                             default:
                                                 
                                                 break;
                                         }
                                         
                                        
                                         
                                     }else{
                                         [self hideAllView];
                                         [self showAlert:@"签到失败"];
                                     }
                                     
                                     
                                 }
                                 else
                                 {
                                  [self hideAllView];
                                 }
                             }];
    
    
}


//计算mac
-(void)getMac:(NSString *)mac{
    
    
    char * temp=HexToBin((char *)[mac UTF8String]);
    int datalen = [mac length]/2;
    char data[datalen];
    memcpy(data, temp, datalen);
    
    _identify=-5;
    [m_vcom StopRec];
    [m_vcom Request_GetMac:0 keyIndex:1 random:(char *)"" randomLen:0 data:data dataLen:datalen];
    [m_vcom StartRec];
    
}


-(void)finishGetMac{
    
    
}

-(void)onDecodeCompleted:(NSString*) formatID
                  andKsn:(NSString*) ksn
            andencTracks:(NSString*) encTracks
         andTrack1Length:(int) track1Length
         andTrack2Length:(int) track2Length
         andTrack3Length:(int) track3Length
         andRandomNumber:(NSString*) randomNumber
            andMaskedPAN:(NSString*) maskedPAN
           andExpiryDate:(NSString*) expiryDate
       andCardHolderName:(NSString*) cardHolderName{
    NSLog(@"回调函数接受返回数据");
    NSLog(@"ksn %@" ,ksn);
    NSLog(@"encTracks %@" ,encTracks);
    NSLog(@"track1Length %i",track1Length);
    NSLog(@"track2Length %i",track2Length);
    NSLog(@"track3Length %i",track3Length);
    NSLog(@"randomNumber %@",randomNumber);
    NSLog(@"maskedPAN %@",maskedPAN);
    NSLog(@"expiryDate %@",expiryDate);
    NSString* string =[[NSString alloc] initWithFormat:@"ksn:%@ encTracks:%@ \n track1Length:%i \n track2Length:%i \n track3Length:%i \n randomNumber:%@ \n maskedPAN:%@ \n expiryDate:%@",ksn,encTracks,track1Length,track2Length,track3Length,randomNumber,maskedPAN,expiryDate];
    //string = [NSString initWithFormat:@"%@,%@", ksn, ksn ];
    NSLog(@"%@",string);
    [self hideAllView];
    if(_dataManager.device_Type==SKTPOS)
    {
        pwdAllertViewController = [[PwdAllertViewController alloc] initWithNibName:@"PwdAllertViewController" bundle:nil cardNo:maskedPAN];
       // pwdAllertViewController.lableNo.text=maskedPAN;
    pwdAllertViewController.hidViewBlock=^(void){
        [m_vcom StopRec];
        [m_vcom close];
       [pwdAllertViewController.view removeFromSuperview];
          pwdAllertViewController=nil;
     };
       pwdAllertViewController.okBlock=^(NSString*str)
      {
          [self hideAllView];
          [self showTrading];
          [pwdAllertViewController.view removeFromSuperview];
          pwdAllertViewController=nil;

         NSMutableArray  *array=[ValueUtils createParam:encTracks tradeMoney:tmpMoney1 pinInfo:[AESUtil encrypt:str password:[ValueUtils md5UpStr:AES_PWD]]cardNoInfo:randomNumber cmd:SWIPE_CARD_CMD_1990051 phonerNumber:phonerNumber termialNo:ksn pasamNo:ksn tseqno:tseqno nowDate:nowDate nowTime:nowTime mac:randomNumber CHECKX:_dataManager.latitude CHECKY:_dataManager.longitude];
          NSString *paramXml=[CommonUtil createXml:array];
          NSString *PACKAGEMAC=[ValueUtils md5UpStr:paramXml];
          
          [array addObject:@"PACKAGEMAC"];
          [array addObject:PACKAGEMAC];
          
          NSString *params=[CommonUtil createXml:array];
          
          _controlCentral.requestController=self;
          [_controlCentral requestDataWithJYM:SWIPE_CARD_CMD_1990051
                                   parameters:params
                           isShowErrorMessage:TRADE_URL_TYPE
                                   completion:^(id result, NSError *requestError, NSError *parserError) {
                                       
                                       [self hideAllView];
                                       if (result)
                                       {
                                           GDataXMLElement *rootElement=(GDataXMLElement *)result;
                                           [self parseTradeXml:rootElement];
                                           
                                       }
                                   }];
          
       };
    //   // [self presentViewController:pwdAllertViewController animated:YES completion:nil];
       [pwdAllertViewController showControllerByAddSubView:self animated:NO];
    //m_recvData.text= m_con;
    }
    
}


//解析xml
-(void)parseTradeXml:(GDataXMLElement *)rootElement{
    
    [self hideAllView];
    GDataXMLElement *lognoElement = [[rootElement elementsForName:@"LOGNO"] objectAtIndex:0];
    NSString *logno=[lognoElement stringValue];
    
    //转向签名页面
    SignaturViewController *signature=[[SignaturViewController alloc] init];
    signature.logno=logno;
    signature.type=1;   //代表交易
    double mon=[tmpMoney doubleValue]/100;
    signature.money=[NSString stringWithFormat:@"%.2f",mon];
    signature.hidesBottomBarWhenPushed=YES;
    [self.navigationController pushViewController:signature animated:YES];
    
    //    TradeResultViewController *result=[[TradeResultViewController alloc] init];
    //    result.type=1;
    //    result.hidesBottomBarWhenPushed=YES;
    //
    //    result.money=[NSString stringWithFormat:@"%.2f",[tmpMoney doubleValue]/100];
    //    [self.navigationController pushViewController:result animated:YES];
    
    
    
}







-(void)dataArrive:(vcom_Result *)vs Status:(int)_status{
    
    DLog(@"======identify======%d",_identify);
    [m_vcom StopRec];
    
    if(_status==-3){
        //设备没有响应
        [self hideAllView];
//        [self hideCheckPos];
//        [self hideSwipCard];
//        [self hideTrading];
        [self showAlert:@"设备无响应"];
    }else if(_status == -2){
        //耳机没有插入
        [self hideAllView];
//        [self hideCheckPos];
//        [self hideSwipCard];
        [self showAlert:@"请插入刷卡器"];
    }else if(_status==-1){
        //接收数据的格式错误
        [self hideAllView];
//        [self hideCheckPos];
//        [self hideSwipCard];
//        [self hideTrading];
        [self showAlert:@"接收数据的格式错误"];
    }else {
        //操作指令正确
        if(vs->res==0){
            
            //设备有成功返回指令
            NSLog(@"cmd exec ok===%d\n",_identify);
            if(_identify==-1){  //签到时获取psam卡号和设备终端号
                _identify=0;
                pasamNo=[NSString stringWithFormat:@"%s",BinToHex(vs->psamno, 0, vs->psamnoLen)];
                //pasamNo--554e123451234584转换前两位为：UN123451234584
                pasamNo=[AESUtil changePsamNo:pasamNo];
                termialNo=[NSString stringWithFormat:@"%s",BinToHex(vs->hardSerialNo, 0, vs->hardSerialNoLen)];
                DLog(@"==签到获取到psam号%@==设备终端号:%@",pasamNo,termialNo);
                if(![_dataManager.TerminalSerialNumber isEqualToString:termialNo])
                {
                    [self showAlert:@"该终端与当前商户绑定的终端不符，请检查终端是否正确！"];
                    [self hideAllView];
                    return;
                }
                
                [self doSigned];
                
            }else if(_identify==-2){ //若是签到更新mac返回时
                _identify=0;
                DLog(@"更新mac成功，签到成功……");
                _dataManager.isSign=TRUE;
                [self getPsamNumber];
            }else if(_identify==-3){
                
                _identify=0;
                pasamNo=[NSString stringWithFormat:@"%s",BinToHex(vs->psamno, 0, vs->psamnoLen)];
                pasamNo=[AESUtil changePsamNo:pasamNo];
                termialNo=[NSString stringWithFormat:@"%s",BinToHex(vs->hardSerialNo, 0, vs->hardSerialNoLen)];
                
                [self signureSuccess];
            }else if(_identify==-4){
                _identify=0;
                trackInfo=[[NSString stringWithFormat:@"%s",BinToHex(vs->trackEncryption, 0, vs->trackEncryptionLen)] uppercaseString];
                cardNoInfo=[[NSString stringWithFormat:@"%s",BinToHex(vs->cardEncryption, 0, vs->cardEncryptionLen)] uppercaseString];
//                pinInfo=[[NSString stringWithFormat:@"%s",BinToHex(vs->psamno, 0, vs->psamnoLen)] uppercaseString];
                 pinInfo=[[NSString stringWithFormat:@"%s",BinToHex(vs->pinEncryption, 0, vs->pinEncryptionLen)] uppercaseString];
                
                DLog(@"==刷卡获取到卡号%@==\n磁道信息:%@",cardNoInfo,trackInfo);
                
//                [self hideSwipCard];
                [self hideAllView];
                if(!IsNilString(trackInfo) && !IsNilString(cardNoInfo)){
                 [self finishSwipCard];
                    //[self gotosignaturview];
                }
            
            }else if(_identify==-5){
                
                _identify=0;
                NSString *tmpStr=[NSString stringWithFormat:@"%s",BinToHex(vs->macres, 0, vs->macresLen)];
                macEncrypt=[AESUtil stringFromHexString:tmpStr];
                [self finishGetMac];
               // [self gotosignaturview];
            
            }
            else if(_identify==-6){
                
                _identify=0;
                
            }
            else{
                
                [self doResult:vs Status:_status];
            }
            
        }else {
            DLog(@"cmd exec error:%d\n",vs->res);
            [self hideAllView];
            switch (vs->res) {
                    
                case 4:
                    [self showAlert:@"刷卡器硬件暂不支持该命令"];
                    break;
                case 64:
                    [self showAlert:@"打印机缺纸"];
                    break;
                case 242:
                    [self showAlert:@"不识别的子命令码"];
                    break;
                case 244:
                    [self showAlert:@"随机数长度错误"];
                    break;
                case 247:
                    [self showAlert:@"数据域长度错误"];
                    break;
                case 252:
                    [self showAlert:@"数据域内容错误"];
                    break;
                default:
                    
                    [self showAlert:@"操作失败"];
                     [m_vcom StopRec];
                     [m_vcom close];
                    break;
            }
             [m_vcom StopRec];
        }
    }

}



//检查micphone状态
- (BOOL)hasHeadset
{
#if TARGET_IPHONE_SIMULATOR
#warning *** Simulator mode: audio session code works only on a device
    return NO;
#else
    CFStringRef route;
    UInt32 propertySize = sizeof(CFStringRef);
    AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &route);
    if((route == NULL) || (CFStringGetLength(route) == 0))
    {
        // Silent Mode
        //NSLog(@"AudioRoute: SILENT, do nothing!");
    }
    else
    {
        NSString* routeStr = (NSString*)CFBridgingRelease(route);
        //NSLog(@"AudioRoute: %@", routeStr);
        
        NSRange headphoneRange = [routeStr rangeOfString : @"Headphone"];
        NSRange headsetRange = [routeStr rangeOfString : @"Headset"];
        if (headphoneRange.location != NSNotFound)
        {
            return YES;
        } else if(headsetRange.location != NSNotFound)
        {
            return YES;
        }
    }
    return NO;
#endif
}


-(void)doResult:(vcom_Result *)vs Status:(int)_status{
    
    
}



///==================Qpost SDK==========================

-(void)doSignInStatus:(NSString *)status{
    
    DLog(@"\n--Qpos签到返回信息:%@\n",status);
    
    if(status){
        if([@"签到成功" isEqualToString:status]){
            
            _dataManager.isSign=YES;
            [self signureSuccess];
            
        }else{
            [self hideAllView];
            [self showAlert:status];
        }
        
    }else{
        [self hideAllView];
        [self showAlert:@"签到失败"];
    }
    
}

-(void)EDYGet55Message:(NSString *) message
{
   // [self performSelectorOnMainThread:@selector(StatusInText:) withObject:message waitUntilDone:NO];
}


-(void)EDYonSwiper:(NSString*)cardNum  andcardTrac:(NSString*)cardTrac andpin:(NSString*)cardPin
{

    trackInfo=cardTrac;
    pinInfo=cardPin;
    cardNoInfo=@"11111";
    
    DLog(@"\n=====Qpos刷卡返回=====cardNum:%@===carTrac:%@====carPin:%@\n",cardNum,cardTrac,cardPin);
    trackInfo=[cardTrac substringFromIndex:2];
    DLog(@"截取之后的cardTrac====%@",trackInfo);

    
}


-(void)EDYonError:(NSString*)errmsg
{
    [self hideAllView];
    [self showAlert:errmsg];
}
-(void)EDYonTradeInfo:(NSString*)mac andpsam:(NSString*)psam andtids:(NSString*)tids
{
//    pasamNo=[AESUtil changePsamNo:psam];
//    termialNo=tids;
    macEncrypt=[AESUtil stringFromHexString:mac];
    DLog(@"\n=====Qpos刷卡返回%@=====mac:%@===psam:%@====tids:%@\n",mac,macEncrypt,pasamNo,tids);
    
    //    [self hideSwipCard];
    [self hideAllView];
    [self finishGetMac];

}


//刷卡返回磁道等信息
-(void)onSwiper:(NSString *)cardNum andcardTrac:(NSString *)cardTrac andpin:(NSString *)cardPin{
    
    trackInfo=cardTrac;
    pinInfo=cardPin;
    cardNoInfo=cardNum;
    
    DLog(@"\n=====Qpos刷卡返回=====cardNum:%@===carTrac:%@====carPin:%@\n",cardNum,cardTrac,cardPin);
    trackInfo=[cardTrac substringFromIndex:2];
    DLog(@"截取之后的cardTrac====%@",trackInfo);
    
    
}

//刷卡返回mac信息
-(void)onTradeInfo:(NSString *)mac andpsam:(NSString *)psam andtids:(NSString *)tids{
    
    pasamNo=[AESUtil changePsamNo:psam];
    termialNo=tids;
    macEncrypt=[AESUtil stringFromHexString:mac];
    DLog(@"\n=====Qpos刷卡返回%@=====mac:%@===psam:%@====tids:%@\n",mac,macEncrypt,pasamNo,tids);
    
//    [self hideSwipCard];
    [self hideAllView];
    [self finishGetMac];
   // [self gotosignaturview];


}

//qPOS插入
-(void)onPlugin{
    
 [self performSelectorOnMainThread:@selector(StatusInText:) withObject:@"设备已插入" waitUntilDone:NO];
  
}

//qPOS拔出
-(void)onPlugOut{
    
    [self performSelectorOnMainThread:@selector(StatusInText:) withObject:@"设备已拔出" waitUntilDone:NO];

}



- (void)StatusInText:(NSString *)text
{
    if (text) {
        [self showHudWithTextOnly:@"插入刷卡器"];
         [self hideAllView];
    }
}

-(void)onError:(NSString *)errmsg{
    
    [self hideAllView];

    [self showAlert:errmsg];
}



///==================爱创SDK===================
//通知监听器刷卡器插入手机
-(void) onDevicePlugged
{
    [self hideAllView];
    [self showHudWithTextOnly:@"插入刷卡器"];
    [self hideInsertPos];
}

//通知监听器刷卡器已从手机拔出
-(void) onDeviceUnPlugged
{
    [self hideAllView];
    [self showHudWithTextOnly:@"刷卡器拔出"];
}

-(void)onMicInOut:(int)inout{
    
    
}


-(void)onWaitingForDevice{
    
    
    
}

-(void)onError:(int)errorCode andMsg:(NSString *)errorMsg{
    
    
}


-(void)onDeviceReady{
    
    
}



//-(void)onDecodeCompleted:(NSString *)formatID andKsn:(NSString *)ksn andencTracks:(NSString *)encTracks andTrack1Length:(int)track1Length andTrack2Length:(int)track2Length andTrack3Length:(int)track3Length andRandomNumber:(NSString *)randomNumber andMaskedPAN:(NSString *)maskedPAN andExpiryDate:(NSString *)expiryDate andCardHolderName:(NSString *)cardHolderName{
//    
//    
//}

-(void)onWaitingForCardSwipeForAiShua{
    
    DLog(@"===等待刷卡====");
    
}

-(void)onNoDeviceDetected{
    
    
}

// 通知监听器检测到刷卡动作
-(void)onCardSwipeDetected{
    
    
}

-(void)secondReturnDataFromAiShua{
    
    
}

-(void)onDecodeDrror:(int)decodeResult{
    
    
}

-(void)onWaitingForCardSwipe{
    
    
}

-(void)onDecodingStart{
    
    
}

-(void)hideAllView{
    if(checkPosView)
    [self hideCheckPos];
    
    if(insertPosView)
    {
       // insertPosView=[insertPosView retain];
        [self hideInsertPos];
    }
    
    if(swipeView)
    [self hideSwipCard];
    
    if(tradeView)
    [self hideTrading];
    
    if(hud)
    [self hideWaiting];
    
    [self hideWaiting];
    
}

//用户取消了刷卡
-(void)onReturnConfirm{
    
//    [self hideSwipCard];
    [self hideAllView];
    [self showAlert:@"刷卡操作取消"];
}

//操作中断
-(void)onInterrupted{
    
   // [self hideSwipCard];
    [self hideAllView];
    
    
}


//显示请插入刷卡器
-(void)showInsertPos{
    
    [window addSubview:insertPosView];
   // insertPosView=[insertPosView retain];
}
//隐藏请插入刷卡器
-(void)hideInsertPos{
     //window=[window retain];
    //if ([insertPosView isDescendantOfView:window])
     {
         [insertPosView removeFromSuperview];
         
     }
}


//显示检测设备
-(void)showCheckPos{
    
    [window addSubview:checkPosView];
    checkPosView.Is_show=YES;
    checkPosView.hidchenkviewBlock=^(void){
        
        [self hideAllView];
        [self showAlert:@"设备无响应！"];
    };

    [checkPosView loadAnimationStart];
}

//隐藏检测设备
-(void)hideCheckPos{
    
     checkPosView.Is_show=NO;
    [checkPosView removeFromSuperview];
}


-(void)addobserver
{
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(HiddeView) name:@"HiddenView" object:nil];
    
}

-(void)HiddeView
{
    [self hideAllView];
    
}

-(void)removeobserver
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"HiddenView" object:nil];
    
}

//显示请刷卡
-(void)showSwipCard{
    
    [window addSubview:swipeView];
}

//隐藏刷卡
-(void)hideSwipCard{
    
    [swipeView removeFromSuperview];
}

//显示正在交易中
-(void)showTrading{
    
    [window addSubview:tradeView];
}

//隐藏正在交易中
-(void)hideTrading{
    
    [tradeView removeFromSuperview];
    
}


-(void)viewDidDisappear:(BOOL)animated
{
    //[m_vcom close];
}


-(void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:YES];
    
    switch (_dataManager.device_Type) {
            
        case Vpos:
            m_vcom.eventListener=self;
            
            break;
        case Qpos:
           
            [[ZftQiposLib getInstance]setLister:self];
            break;
        case Qpos_blue:
            [ZftQiposLib setContectType:1];
            [[ZftQiposLib getInstance]setLister:self];
            devicList=[[NSMutableArray alloc]init];
            break;
        case D180:
            // op = [[MPosOperation alloc] initWithType:OPER_START withName:@"start" withArgNum:1 withArgs:[[NSArray alloc] initWithObjects:selectedBTMac, nil] withDelegate:mPosOperationDelegate];
             op.delegate=mPosOperationDelegate;
            
            
            break;
        case SKTPOS:
            
             m_vcom.eventListener=self;
            
            
            break;
        case BPOS:
            
            [[CSwiperController sharedController] setDelegate:self];
            
            
            break;
        default:
            
            break;
    }
    
    


}


-(void)getDeviceNO
{
    
    [self hideAllView];
    [self showWaiting:@"正在获取终端序列号"];
    
    switch (_dataManager.device_Type) {
            
        case Vpos:
            
            [m_vcom StopRec];
            [m_vcom Request_GetExtKsn];  //请求psam卡号和终端号
            [m_vcom StartRec];
            
            break;
            
        case Qpos:
             [self qPostGetPsamInfo:@"1"];
            
            break;
        case Qpos_blue:
            if([ZftQiposLib isconnect_21])
            {
                [self qPostGetPsamInfo:@"1"];
            }
            else{
                [[ZftQiposLib getInstance]starScan];
                
            }

            //[[ZftQiposLib getInstance]setLister:self];

            break;
        case D180:
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessoryConnected:) name:EAAccessoryDidConnectNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessoryDisConnected:) name:EAAccessoryDidDisconnectNotification object:nil];
            eam = [EAAccessoryManager sharedAccessoryManager];
            _accessoryList = [[NSMutableArray alloc] initWithArray: [eam connectedAccessories]];
            selectedBTMac = @"00:00:00:00:00:00";
            if (_accessoryList.count > 0) {
                selectedBTMac = [_accessoryList[0] valueForKey:@"macAddress"];
            }
            opq = [[NSOperationQueue alloc] init];
            [opq setMaxConcurrentOperationCount:3];
            op = [[MPosOperation alloc] initWithType:OPER_START withName:@"start" withArgNum:1 withArgs:[[NSArray alloc] initWithObjects:selectedBTMac, nil] withDelegate:mPosOperationDelegate];
            [opq addOperation:op];
            op.delegate=self;
            
            
            if(_accessoryList.count<=0)
            {
                
                [self showAlert:@"未找到适配的蓝牙设备，请到设置页面检查设备蓝牙是否已匹配？匹配完成后重新启动应用！"];
                [self hideAllView];
                return;

            }
            
            op = [[MPosOperation alloc] initWithType:OPER_GET_SN withName:@"getsn" withArgNum:0 withArgs:nil withDelegate:mPosOperationDelegate];
            [opq addOperation:op];

            break;
        default:
            
            
            break;
    }


}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
//    if ([self.view window] == nil)
//    {
//        // Add code to preserve data stored in the views that might be
//        // needed later.
//        // Add code to clean up other strong references to the view in
//        // the view hierarchy.
//        self.view = nil;  
//    }
  //  [self removeobserver];
    // Dispose of any resources that can be recreated.
}

@end
