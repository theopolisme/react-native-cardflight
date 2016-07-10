//
//  CardFlightManager.m
//

#import "RCTBridge.h"
#import "RCTEventDispatcher.h"
#import "RCTUtils.h"
#import "RCTLog.h"
#import "RCTConvert.h"

#import "CardFlightManager.h"
#import "CardFlight.h"

@implementation CardFlightManager

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(setApiToken: (NSString *)cardFlightApiToken cardFlightAccountToken:(NSString *)cardFlightAccountToken callback:(RCTResponseSenderBlock)callback)
{
    RCTLogInfo(@"Authenticating to CardFlight: API=%@, ACCOUNT=%@", cardFlightApiToken, cardFlightAccountToken);
    [[CFTSessionManager sharedInstance] setApiToken:cardFlightApiToken
                                        accountToken:cardFlightAccountToken
                                        completed:^(BOOL emvReady) {
                                          callback(@[[NSNull null], @{ @"emvReady": @(emvReady) }]);
                                        }];
}

RCT_EXPORT_METHOD(setLogging: (BOOL)enabled)
{
  [[CFTSessionManager sharedInstance] setLogging:enabled];
}

-(void)readerIsConnecting {
  [self.bridge.eventDispatcher sendAppEventWithName:@"readerIsConnecting"
                                               body:@{}];
}

- (void)readerIsConnected:(BOOL)isConnected withError:(NSError *)error {
  if (isConnected) {
    [self.bridge.eventDispatcher sendAppEventWithName:@"readerConnected"
                                                 body:@{}];
  } else {
    [self.bridge.eventDispatcher sendAppEventWithName:@"readerConnectionFailed"
                                                 body:@{@"message": error.localizedDescription}];
  }
}

- (void)readerBatteryLow {
  [self.bridge.eventDispatcher sendAppEventWithName:@"readerBatteryLow"
                                               body:@{}];
}

RCT_EXPORT_METHOD(initWithReader: (int)reader)
{
  self.reader = [[CFTReader alloc] initWithReader:reader];
  self.reader.delegate = self;
}


# pragma mark general

RCT_EXPORT_METHOD(beginEMVTransactionWithAmount: (nonnull NSNumber*)amount chargeDictionary:(NSDictionary *)chargeDictionary)
{
  if (self.reader) {
    [self.reader beginEMVTransactionWithAmount:amount
                           andChargeDictionary:chargeDictionary];
  }
}

-(NSDictionary *)serializeCharge:(CFTCharge *)charge {
  NSDictionary *chargeDetails = @{
                                  @"amount": charge.amount ?: [NSNull null],
                                  @"token": charge.token ?: [NSNull null],
                                  @"referenceID": charge.referenceID ?: [NSNull null],
                                  @"isRefunded": @(charge.isRefunded),
                                  @"isVoided": @(charge.isVoided),
                                  @"amountRefunded": charge.amountRefunded ?: [NSNull null],
                                  @"created": charge.created ?: [NSNull null],
                                  @"metadata": charge.metadata ?: [NSNull null]
                                  };
  return chargeDetails;
}

# pragma mark swipe

RCT_EXPORT_METHOD(setSwipeHasTimeout: (BOOL)enabled)
{
  if (self.reader) {
    [self.reader swipeHasTimeout:enabled];
  }
}

- (void)readerCardResponse:(CFTCard *)card withError:(NSError *)error {

  if (card) {
    self.swipedCard = card;

    NSDictionary *cardDetails = @{
                                  @"first6": card.first6 ?: [NSNull null],
                                  @"last4": card.last4 ?: [NSNull null],
                                  @"cardTypeString": card.cardTypeString ?: [NSNull null],
                                  @"expirationMonth": card.expirationMonth ?: [NSNull null],
                                  @"expirationYear": card.expirationYear ?: [NSNull null],
                                  @"name": card.name ?: [NSNull null],
                                  @"cardToken": card.cardToken ?: [NSNull null],
                                  @"vaultID": card.vaultID ?: [NSNull null]
                                  };

    [self.bridge.eventDispatcher sendAppEventWithName:@"readerCardSuccess"
                                                 body:@{@"card": cardDetails}];
  } else {
    [self.bridge.eventDispatcher sendAppEventWithName:@"readerCardFailure"
                                                 body:@{@"message": error.localizedDescription}];
  }
}

RCT_EXPORT_METHOD(chargeSwipedCardWithParameters: (NSDictionary*)parameters callback:(RCTResponseSenderBlock)callback)
{
  if (self.swipedCard) {
    [self.swipedCard chargeCardWithParameters:parameters success:^(CFTCharge *charge) {
      callback(@[[NSNull null], [self serializeCharge:charge]]);
    } failure:^(NSError *error) {
      callback(@[@{ @"message": error.localizedDescription }]);
    }];
  }
}

# pragma mark emv

-(void)emvCardDipped {
  [self.bridge.eventDispatcher sendAppEventWithName:@"emvCardDipped"
                                               body:@{}];
}

-(void)emvCardResponse:(NSDictionary *)cardDictionary {
  [self.bridge.eventDispatcher sendAppEventWithName:@"emvCardResponse"
                                               body:@{@"card": cardDictionary}];
}

-(void)emvCardRemoved:(NSDictionary *)cardDictionary {
  [self.bridge.eventDispatcher sendAppEventWithName:@"emvCardRemoved"
                                               body:@{}];
}

-(void)emvErrorResponse:(NSError *)error {
  [self.bridge.eventDispatcher sendAppEventWithName:@"emvError"
                                               body:@{@"message": error.localizedDescription}];
}

-(void)emvMessage:(CFTEMVMessage)message {
  NSString *text = [self.reader defaultMessageForCFTEMVMessage:message];
  [self.bridge.eventDispatcher sendAppEventWithName:@"emvMessage"
                                               body:@{@"message": text}];
}

RCT_EXPORT_METHOD(chargeDippedCard:(RCTResponseSenderBlock)callback)
{
  self.emvChargeCallback = callback;
  [self.reader emvProcessTransaction:YES];
}

- (void)emvTransactionResult:(CFTCharge *)charge requiresSignature:(BOOL)signature withError:(NSError *)error {
  if (self.emvChargeCallback) {
    if (charge) {
      self.emvChargeCallback(@[[NSNull null], @{
                                                @"charge": [self serializeCharge:charge],
                                                @"requiresSignature": @(signature)
                                                }]);
    } else {
      self.emvChargeCallback(@[@{ @"message": error.localizedDescription }]);
    }
  }
}

RCT_EXPORT_METHOD(uploadSignature: (NSString*)data callback:(RCTResponseSenderBlock)callback)
{
  [self.reader emvTransactionSignature:[RCTConvert NSData:data] success:^{
    callback(@[[NSNull null], @{@"success": @(YES)}]);
  } failure:^(NSError *error) {
    callback(@[@{ @"message": error.localizedDescription }]);
  }];
}

RCT_EXPORT_METHOD(destroy)
{
  if (self.reader) {
    [self.reader destroy];
  }
}

@end
