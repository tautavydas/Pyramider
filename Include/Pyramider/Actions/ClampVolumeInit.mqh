// ###<Experts/Pyramider.mq5>

// #include <Pyramider/Actions/IAction.mqh>

class ClampVolumeInit final : public IAction {
    CPositionReporter const* const PositionReporter;

   public:
    ClampVolumeInit(CPositionReporter const& position_reporter) : PositionReporter(&position_reporter) {}
    double onInit() const override { return onButton(PositionReporter.getAvgVolume()); }
    double onTick(double const val) const override { return val; }
    double onButton(double const val) const override { return fmax(Volumes.VolumeMin, val); }
};