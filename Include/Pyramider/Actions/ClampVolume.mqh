// ###<Experts/Pyramider.mq5>

class ClampVolume final : public IAction {
    CPositionReporter const* const PositionReporter;

   public:
    ClampVolume(CPositionReporter const& position_reporter) : PositionReporter(&position_reporter) {}

    double onInit() const override { return PositionReporter.getVolume(); }
    double onTick(double const val) const override { return val; }
    double clamp(double const val) const override { return fmax(g_volumes.m_volume_min, val); }
};