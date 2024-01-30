// ###<Experts/Pyramider.mq5>

#include "Drawable.mqh"

template <typename ParametersType>
class StateObject : public IDrawable {
    string const text;
    color const border_color;

   public:
    ParametersType const *const Parameters;
    StateObject(string const name_, string const tooltip_, string const text_, ParametersType const *const parameters)
        : IDrawable(OBJ_BUTTON, name_, tooltip_, clrBlack, clrWhiteSmoke),
          text(text_),
          border_color(clrNONE),
          Parameters(parameters) {}

    ~StateObject() { delete Parameters; }

   public:
    void Draw() {
        IDrawable::Draw();
        ObjectSetString(ChartID(), name, OBJPROP_TEXT, text);
        ObjectSetInteger(ChartID(), name, OBJPROP_BORDER_COLOR, border_color);
        Parameters.Draw(name);
    }

    void Set() const { ObjectSetInteger(ChartID(), name, OBJPROP_STATE, true); }
    void Unset() const { ObjectSetInteger(ChartID(), name, OBJPROP_STATE, false); }
};