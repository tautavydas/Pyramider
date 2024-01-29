// ###<Experts/Pyramider.mq5>

#include <Pyramider/Entities/Parameters.mqh>
#include <Pyramider/Objects/Stateful.mqh>

class PeriodButton : public StateObject<Parameters> {
   public:
    PeriodButton(CProportionsManager const& proportions_manager, ENUM_TIMEFRAMES const& periods[], uint const coefX)
        : StateObject(EnumToString(periods[coefX]),
                      EnumToString(periods[coefX]),
                      StringSubstr(EnumToString(periods[coefX]), 7),
                      new Parameters(proportions_manager, coefX, 0, 1, 1)) {}
};