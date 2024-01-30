// ###<Experts/Pyramider.mq5>

#include "IAction.mqh"
template <typename TMinMax>
class ClampPrice final : public IAction {
    TMinMax const MinMax;
    double const PriceRatio;

   public:
    ENUM_SYMBOL_INFO_DOUBLE const QuoteIn;
    ClampPrice(ENUM_POSITION_TYPE const position_type, double const price_ratio)
        : PriceRatio(price_ratio),
          QuoteIn(position_type == POSITION_TYPE_BUY ? SYMBOL_ASK : SYMBOL_BID) {}

    double onInit() const override { return onButton(SymbolInfoDouble(Symbol(), QuoteIn)) * PriceRatio; }
    double onTick(double const val) const override { return MinMax.process(SymbolInfoDouble(Symbol(), QuoteIn), val); }
    double onButton(double const val) const override {
        double const Val{fmax(0, val)}, const current_price{SymbolInfoDouble(Symbol(), QuoteIn)};
        // if (PositionReporter.getStatus()) {
        // PrintFormat("%s %f %f %f | %f", __FUNCTION__, PositionReporter.getPrice(), current_price, val, MinMax.process(MinMax.process(PositionReporter.getPrice(), current_price), val));
        //  return MinMax.process(MinMax.process(PositionReporter.getPrice(), current_price), val);
        //} else {
        return MinMax.process(current_price, val);
        //}
    }
};