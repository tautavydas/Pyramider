// ###<Experts/Pyramider.mq5>

template <typename Type>
class ClampRestricted final : public IAction {
    CTradeBuilder<Type> const *const TradeBuilder;

   public:
    ClampRestricted(CTradeBuilder<Type> const &trader_builder)
        : TradeBuilder(&trader_builder) {}

    double onInit() const override { return 0; }
    double onTick(double const val) const override { return val; }
    double clamp(double const val) const override { return fmax(0, fmin(TradeBuilder.getCount(), val)); }
};