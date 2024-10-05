// ###<Experts/Pyramider.mq5>
#include <Pyramider/Objects/Parameters.mqh>

class CTextObject final : public IDrawable {
    color const m_border_color;
    // double const m_step;
    bool m_initialized;
    Parameters *const Params;
    uint const m_digits;

   public:
    // IAction const *const Action;
    CTextObject(CProportionsManager const &proportions_manager, /*IAction const &action, */ uint const coefX, ENUM_POSITION_TYPE const position_type, string const name, uint const digits)
        : IDrawable(OBJ_LABEL, (position_type == POSITION_TYPE_BUY ? "Long" : "Short") + name, name, position_type == POSITION_TYPE_BUY ? clrBlue : clrRed, clrLightGray),
          m_border_color(clrGray),
          // m_step(pow(10.0, -double(digits))),
          m_initialized(false),
          // Action(&action),
          Params(new Parameters(proportions_manager, coefX, position_type, 2, 1)),
          m_digits(digits)
    // ValueUp(new ChangeButton<ParametersStandard>(proportions_manager, coefX, position_type, m_name)),
    // ValueDown(new ChangeButton<ParametersShifted>(proportions_manager, coefX, position_type, m_name)),
    // m_digits(digits),
    /*m_save_last_value(save_last_value)*/ {
    }

    ~CTextObject() {
        delete Params;
    }

    void UpdatePosition() {
        Params.UpdateCoordinates();
    }

    void Draw() {
        IDrawable::Draw();

        ObjectSetInteger(ChartID(), m_name, OBJPROP_BORDER_COLOR, m_border_color);
        Params.SetCoordinates(m_name);

        if (!m_initialized) {
            setValue(666);
            m_initialized = true;
        }
    }

    void Hide() {
        IDrawable::Hide();
        m_initialized = false;
    }

    double getValue() const {
        return StringToDouble(ObjectGetString(ChartID(), m_name, OBJPROP_TEXT));
    }

    void setValue(double const display_value) const {
        ObjectSetString(ChartID(), m_name, OBJPROP_TEXT, StringFormat("%.*f", m_digits, display_value));
    }
};