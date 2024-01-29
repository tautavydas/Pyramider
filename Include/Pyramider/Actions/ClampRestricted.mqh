// ###<Experts/Pyramider.mq5>

template <typename T>
class ClampRestricted final : public IAction {
    // double const init_value, const lower_boundary;
    CTradeBuilder<T> const *const TradeBuilder;

   public:
    ClampRestricted(CTradeBuilder<T> const &trader_builder)
        :  // init_value(0),
           // lower_boundary(0),
          TradeBuilder(&trader_builder) {}

    double onInit() const override { return onButton(0); }
    double onTick(double const val) const override { return val; }
    double onButton(double const val) const override { return fmax(0, fmin(TradeBuilder.getCount(), val)); }
};