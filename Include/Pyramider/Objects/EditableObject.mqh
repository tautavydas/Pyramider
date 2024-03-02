// ###<Experts/Pyramider.mq5>
#include <Pyramider/Actions/IAction.mqh>

class CEditableObject final : public IDrawable {
    color const border_color;
    double const step;
    bool BoolInit;

   public:
    IAction const *const Action;
    Parameters const *const Params;
    ChangeButton<ParametersStandard> *const ValueUp;
    ChangeButton<ParametersShifted> *const ValueDown;
    uint const digits;
    CEditableObject(CProportionsManager const &proportions_manager, IAction const &action, uint const coefX, ENUM_POSITION_TYPE const position_type, string const name_, uint const digits_)
        : IDrawable(OBJ_EDIT, (position_type == POSITION_TYPE_BUY ? "Long" : "Short") + name_, name_, position_type == POSITION_TYPE_BUY ? clrBlue : clrRed, clrLightGray),
          border_color(clrGray),
          step(pow(10.0, -double(digits_))),
          BoolInit(true),
          Action(GetPointer(action)),
          Params(new Parameters(proportions_manager, coefX, position_type, 2, 1)),
          ValueUp(new ChangeButton<ParametersStandard>(proportions_manager, coefX, position_type, name)),
          ValueDown(new ChangeButton<ParametersShifted>(proportions_manager, coefX, position_type, name)),
          digits(digits_) {}

    ~CEditableObject() {
        delete Action;
        delete Params;
        delete ValueUp;
        delete ValueDown;
    }

    void Draw() {
        IDrawable::Draw();
        ObjectSetInteger(ChartID(), name, OBJPROP_BORDER_COLOR, border_color);
        ValueUp.Draw();
        ValueDown.Draw();
        Params.Draw(name);
        if (BoolInit) {
            setText(Action.onInit());
            BoolInit = false;
        }
    }

    void Hide() {
        IDrawable::Hide();
        ValueUp.Hide();
        ValueDown.Hide();
        BoolInit = true;
    }

    double getValue() const {
        return StringToDouble(ObjectGetString(ChartID(), name, OBJPROP_TEXT));
    }

    void onEdit() const {
        setText(Action.clamp(getValue()));
    }

    void onButton(OperationPtr const &Operation) const {
        setText(Action.clamp(Operation(getValue(), step)));
    }

   private:
    // void setValue() const {
    //     setText(Action.onTick(getValue()));
    // }
    void setText(double const display_value) const {
        ObjectSetString(ChartID(), name, OBJPROP_TEXT, StringFormat("%.*f", digits, display_value));
    }
};