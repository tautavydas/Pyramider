// ###<Experts/Pyramider.mq5>

class ClampPriceRatio final : public IAction {
    double const default_value, const lower_boundary, const higher_boundary;

   public:
    ClampPriceRatio(ENUM_POSITION_TYPE const position_type, double const default_value_)
        : default_value(default_value_),
          lower_boundary(position_type == POSITION_TYPE_BUY ? 0 : 1),
          higher_boundary(position_type == POSITION_TYPE_BUY ? 1 : DBL_MAX) {}

    double onInit() const override { return onButton(default_value); }
    double onTick(double const val) const override { return val; }
    double onButton(double const val) const override { return fmax(lower_boundary, fmin(higher_boundary, val)); }
};