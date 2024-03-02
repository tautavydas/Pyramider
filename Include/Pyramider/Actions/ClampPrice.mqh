// ###<Experts/Pyramider.mq5>

template <typename TMinMax>
class ClampPrice final : public IAction {
    TMinMax const MinMax;

   public:
    ENUM_SYMBOL_INFO_DOUBLE const QuoteIn;
    ClampPrice(ENUM_POSITION_TYPE const position_type)
        : QuoteIn(position_type == POSITION_TYPE_BUY ? SYMBOL_ASK : SYMBOL_BID) {}

    double onInit() const override { return SymbolInfoDouble(Symbol(), QuoteIn); }
    double onTick(double const val) const override { return MinMax.process(SymbolInfoDouble(Symbol(), QuoteIn), val); }
    double clamp(double const val) const override { return MinMax.process(SymbolInfoDouble(Symbol(), QuoteIn), fmax(0, val)); }
};

// double const Val{fmax(0, val)};
//, const current_price{SymbolInfoDouble(Symbol(), QuoteIn)};
// if (PositionReporter.getStatus()) {
// PrintFormat("%s %f %f %f | %f", __FUNCTION__, PositionReporter.getPrice(), current_price, val, MinMax.process(MinMax.process(PositionReporter.getPrice(), current_price), val));
//  return MinMax.process(MinMax.process(PositionReporter.getPrice(), current_price), val);
//} else {
//}