// ###<Experts/Pyramider.mq5>

#include "IDrawable.mqh"

template <typename ParametersType>
class Stateful : public IDrawable {
    color const m_border_color;
    string m_add_text, const m_text;

   protected:
    bool m_state;

   public:
    ParametersType *const Parameters;
    Stateful(string const name, string const tooltip, string const text, ParametersType *const parameters)
        : IDrawable(OBJ_BUTTON, name, tooltip, clrBlack, clrWhiteSmoke),
          m_text(text),
          m_border_color(clrNONE),
          m_state(false),
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
        ObjectSetString(ChartID(), m_name, OBJPROP_TEXT, m_text + " " + m_add_text);
        Parameters.SetCoordinates(m_name);
    }

    /*void Hide() override {
        IDrawable::Hide();
    }*/

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

    void setText(string const text) {
        m_add_text = text;
        ObjectSetString(ChartID(), m_name, OBJPROP_TEXT, m_text + " " + m_add_text);
    }

    void resetText() {
        m_add_text = "";
        ObjectSetString(ChartID(), m_name, OBJPROP_TEXT, m_text);
    }
};