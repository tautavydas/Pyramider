// ###<Experts/Pyramider.mq5>
#include <Pyramider/Actions/IAction.mqh>

class CEditableObject final : public IDrawable {
    color const m_border_color;
    double const m_step;
    bool m_bool_init;

   public:
    IAction const *const Action;
    Parameters *const Params;
    ChangeButton<ParametersStandard> *const ValueUp;
    ChangeButton<ParametersShifted> *const ValueDown;
    uint const m_digits;
    CEditableObject(CProportionsManager const &proportions_manager, IAction const &action, uint const coefX, ENUM_POSITION_TYPE const position_type, string const name_, uint const digits)
        : IDrawable(OBJ_EDIT, (position_type == POSITION_TYPE_BUY ? "Long" : "Short") + name_, name_, position_type == POSITION_TYPE_BUY ? clrBlue : clrRed, clrLightGray),
          m_border_color(clrGray),
          m_step(pow(10.0, -double(digits))),
          m_bool_init(true),
          Action(&action),
          Params(new Parameters(proportions_manager, coefX, position_type, 2, 1)),
          ValueUp(new ChangeButton<ParametersStandard>(proportions_manager, coefX, position_type, m_name)),
          ValueDown(new ChangeButton<ParametersShifted>(proportions_manager, coefX, position_type, m_name)),
          m_digits(digits) {}

    ~CEditableObject() {
        delete Action;
        delete Params;
        delete ValueUp;
        delete ValueDown;
    }

    void UpdatePosition() {
        Params.UpdateCoordinates();
        ValueUp.UpdatePosition();
        ValueDown.UpdatePosition();
    }

    void Draw() {
        IDrawable::Draw();
        ObjectSetInteger(ChartID(), m_name, OBJPROP_BORDER_COLOR, m_border_color);
        Params.SetCoordinates(m_name);
        ValueUp.DrawFresh();
        ValueDown.DrawFresh();
        if (m_bool_init) {
            setText(Action.onInit());
            m_bool_init = false;
        }
    }

    void Hide() {
        IDrawable::Hide();
        ValueUp.Hide();
        ValueDown.Hide();
        m_bool_init = true;
    }

    double getValue() const {
        return StringToDouble(ObjectGetString(ChartID(), m_name, OBJPROP_TEXT));
    }

    void onEdit() const {
        setText(Action.clamp(getValue()));
    }

    void onButton(OperationPtr const &Operation) const {
        setText(Action.clamp(Operation(getValue(), m_step)));
    }

   private:
    // void setValue() const {
    //     setText(Action.onTick(getValue()));
    // }
    void setText(double const display_value) const {
        ObjectSetString(ChartID(), m_name, OBJPROP_TEXT, StringFormat("%.*f", m_digits, display_value));
    }
};