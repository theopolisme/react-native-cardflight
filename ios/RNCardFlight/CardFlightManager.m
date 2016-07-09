//
//  CardFlightManager.m
//

#import "RCTBridge.h"
#import "RCTEventDispatcher.h"
#import "RCTUtils.h"
#import "RCTLog.h"

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

RCT_EXPORT_METHOD(initWithReader: (int)reader)
{
  self.reader = [[CFTReader alloc] initWithReader:reader];
  self.reader.delegate = self;
}

RCT_EXPORT_METHOD(setSwipeHasTimeout: (BOOL)enabled)
{
  if (self.reader) {
    [self.reader swipeHasTimeout:enabled];
  }
}

RCT_EXPORT_METHOD(beginEMVTransactionWithAmount: (nonnull NSNumber*)amount chargeDictionary:(NSDictionary *)chargeDictionary)
{
  if (self.reader) {
    [self.reader beginEMVTransactionWithAmount:amount
                           andChargeDictionary:chargeDictionary];
  }
}

- (void)readerCardResponse:(CFTCard *)card withError:(NSError *)error {

  if (card) {
    self.swipedCard = card;

    NSDictionary *cardDetails = @{
      @"first6": card.first6,
      @"last4": card.last4,
      @"cardTypeString": card.cardTypeString,
      @"expirationMonth": card.expirationMonth,
      @"expirationYear": card.expirationYear,
      @"name": card.name,
      @"cardToken": card.cardToken,
      @"vaultID": card.vaultID
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
      NSDictionary *chargeDetails = @{
        @"amount": charge.amount,
        @"token": charge.token,
        @"referenceID": charge.referenceID,
        @"isRefunded": @(charge.isRefunded),
        @"isVoided": @(charge.isVoided),
        @"amountRefunded": charge.amountRefunded,
        @"created": charge.created,
        @"metadata": charge.metadata
      };
      callback(@[[NSNull null], @{ @"charge": chargeDetails }]);
    } failure:^(NSError *error) {
      callback(@[@{ @"message": error.localizedDescription }]);
    }];
  }
}

RCT_EXPORT_METHOD(destroy)
{
  if (self.reader) {
    [self.reader destroy];
  }
}

@end
