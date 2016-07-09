//
//  CardFlightManager.h
//

#import "RCTBridgeModule.h"
#import "CardFlight.h"

@interface CardFlightManager : NSObject <RCTBridgeModule, CFTReaderDelegate>

@property (nonatomic) CFTCard *swipedCard;
@property (nonatomic) CFTReader *reader;

@end
