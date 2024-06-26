// ###<Experts/Pyramider.mq5>

#include "Parameters.mqh"
#include "Stateful.mqh"

class PeriodButton : public Stateful<Parameters> {
   public:
    PeriodButton(CProportionsManager const& proportions_manager, ENUM_TIMEFRAMES const& periods[], uint const coefX)
        : Stateful(EnumToString(periods[coefX]),
                   EnumToString(periods[coefX]),
                   StringSubstr(EnumToString(periods[coefX]), 7),
                   new Parameters(proportions_manager, coefX, 0, 1, 1)) {}
};