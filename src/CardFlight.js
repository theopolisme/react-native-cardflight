import { NativeModules, NativeAppEventEmitter } from 'react-native';
const CardFlightManager = NativeModules.CardFlightManager;

let CardFlight = {
  setApiToken(cardFlightApiToken, cardFlightAccountToken, cb) {
    CardFlightManager.setApiToken(cardFlightApiToken, cardFlightAccountToken, cb);
  },

  setLogging(enabled) {
    CardFlightManager.setLogging(enabled);
  },

  initWithReader(reader) {
    CardFlightManager.initWithReader(reader);
  },

  setSwipeHasTimeout(enabled) {
    CardFlightManager.setSwipeHasTimeout(enabled);
  },

  beginEMVTransactionWithAmount(amount, metadata) {
    CardFlightManager.beginEMVTransactionWithAmount(amount, metadata);
  },

  chargeSwipedCardWithParameters(parameters, cb) {
    CardFlightManager.chargeSwipedCardWithParameters(parameters, cb);
  },

  chargeDippedCard(cb) {
    CardFlightManager.chargeDippedCard(cb);
  },

  uploadSignature(image, cb) {
    CardFlightManager.uploadSignature(image, cb);
  },

  destroy() {
    CardFlightManager.destroy();
  },

  /**
   * Available events
   * ================
   * - readerIsConnecting
   * - readerConnected
   * - readerConnectionFailed(error)
   * - readerBatteryLow
   * - readerCardSuccess({card})
   * - readerCardFailure(error)
   * - emvCardDipped
   * - emvCardResponse({card})
   * - emvCardRemoved
   * - emvError(error)
   * - emvMessage({message})
   */
  on(event, cb) {
    return NativeAppEventEmitter.addListener(event, cb);
  }
};

export default CardFlight;
