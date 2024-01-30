// ###<Experts/Pyramider.mq5>

template <typename ParamsType>
class ChangeButton final : public StateObject<ParamsType> {
   public:
    ChangeButton(CProportionsManager const& proportions_manager, uint const coefX, ENUM_POSITION_TYPE const position_type, string const name_)
        : StateObject(name_ + (typename(ParamsType) == typename(ParametersStandard) ? "Up" : "Down"),
                      typename(ParamsType) == typename(ParametersStandard) ? "Increase" : "Decrease",
                      typename(ParamsType) == typename(ParametersStandard) ? "Up" : "Down",
                      new ParamsType(proportions_manager, coefX + 2, position_type, 1, 2)) {
    }
};