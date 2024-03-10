// ###<Experts/Pyramider.mq5>

#include "IAction.mqh"

class ClampNotionalRatio final : public IAction {
    double const m_lower_boundary, const m_higher_boundary;

   public:
    ClampNotionalRatio()
        : m_lower_boundary(1.0),
          m_higher_boundary(DBL_MAX) {}

    double onInit() const override { return m_lower_boundary; }
    double onTick(double const val) const override { return val; }
    double clamp(double const val) const override { return fmax(m_lower_boundary, fmin(m_higher_boundary, val)); }
};