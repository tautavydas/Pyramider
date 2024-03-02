// ###<Experts/Pyramider.mq5>

class ClampPriceRatio final : public IAction {
    double const m_default_value, const m_lower_boundary, const m_higher_boundary;

   public:
    ClampPriceRatio(ENUM_POSITION_TYPE const position_type)
        : m_default_value(1),
          m_lower_boundary(position_type == POSITION_TYPE_BUY ? 0 : m_default_value),
          m_higher_boundary(position_type == POSITION_TYPE_BUY ? m_default_value : DBL_MAX) {}

    double onInit() const override { return m_default_value; }
    double onTick(double const val) const override { return val; }
    double clamp(double const val) const override { return fmax(m_lower_boundary, fmin(m_higher_boundary, val)); }
};