// ###<Experts/Pyramider.mq5>

class ActionButton : public StateObject<Parameters> {
   public:
    ActionButton(CProportionsManager const& proportions_manager, uint const coefX, ENUM_POSITION_TYPE const position_type, string const action)
        : StateObject((position_type == POSITION_TYPE_BUY ? "Long" : "Short") + action,
                      position_type == POSITION_TYPE_BUY ? "Buy" : "Sell",
                      action,
                      new Parameters(proportions_manager, coefX, position_type, 2, 1)) {}

    void UpdatePrice() const { /*PrintFormat("%s yo", __FUNCTION__);*/ /*Edit.SetValue();*/
    }
};