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

  destroy() {
    CardFlightManager.destroy();
  },

  /**
   * Available events
   * ================
   * - readerCardSuccess(card)
   * - readerCardFailure(error)
   */
  on(event, cb) {
    return NativeAppEventEmitter.addListener(event, cb);
  }
};

export default CardFlight;
