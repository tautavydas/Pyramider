// ###<Experts/Pyramider.mq5>

class ClampValue final : public IAction {
    double const init_value, const lower_boundary, const higher_boundary;

   public:
    ClampValue(double const init_value_, double const lower_boundary_, double const higher_boundary_)
        : init_value(init_value_),
          lower_boundary(lower_boundary_),
          higher_boundary(higher_boundary_) {}

    double onInit() const override { return onButton(init_value); }
    double onTick(double const val) const override { return val; }
    double onButton(double const val) const override { return fmax(lower_boundary, fmin(higher_boundary, val)); }
};