// ###<Experts/Pyramider.mq5>

#include "IDrawable.mqh"

template <typename ParametersType>
class Stateful : public IDrawable {
    bool m_state;
    color const m_border_color;
    string const m_text;

   public:
    ParametersType *const Parameters;
    Stateful(string const name_, string const tooltip_, string const text_, ParametersType *const parameters)
        : IDrawable(OBJ_BUTTON, name_, tooltip_, clrBlack, clrWhiteSmoke),
          m_state(false),
          m_text(text_),
          m_border_color(clrNONE),
          Parameters(parameters) {}

    ~Stateful() {
        delete Parameters;
    }

   public:
    void UpdatePosition() {
        Parameters.UpdateCoordinates();
    }

   private:
    void Draw() override {
        IDrawable::Draw();
        ObjectSetInteger(ChartID(), m_name, OBJPROP_STATE, m_state);
        ObjectSetInteger(ChartID(), m_name, OBJPROP_BORDER_COLOR, m_border_color);
        ObjectSetString(ChartID(), m_name, OBJPROP_TEXT, m_text);
        Parameters.SetCoordinates(m_name);
    }

   public:
    void DrawFresh() {
        m_state = false;
        Draw();
    }

    void DrawKeepState() {
        m_state = ObjectGetInteger(ChartID(), m_name, OBJPROP_STATE);
        Draw();
    }

    void Set() const {
        ObjectSetInteger(ChartID(), m_name, OBJPROP_STATE, true);
    }
    void Unset() const {
        ObjectSetInteger(ChartID(), m_name, OBJPROP_STATE, false);
    }
};