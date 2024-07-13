// ###<Experts/Pyramider.mq5>

class IDrawable {
   public:
    string const m_name;

   protected:
    ENUM_OBJECT const object;
    string const m_tooltip;
    color const m_object_color, const m_background_color;

    IDrawable(ENUM_OBJECT const object_, string const name, string const tooltip, color const object_color, color const background_color)
        : object(object_),
          m_name(name),
          m_tooltip(tooltip),
          m_object_color(object_color),
          m_background_color(background_color) {}

    ~IDrawable() { Hide(); }

   public:
    virtual void Draw() = 0;
    // virtual void DrawUpdate() = 0;
    void Hide() const { ObjectDelete(ChartID(), m_name); }
};

void IDrawable::Draw() {
    ObjectCreate(ChartID(), m_name, object, 0, 0, 0);
    // ObjectSetString(ChartID(), name, OBJPROP_FONT, "Calibri");
    ObjectSetInteger(ChartID(), m_name, OBJPROP_COLOR, m_object_color);
    ObjectSetInteger(ChartID(), m_name, OBJPROP_BACK, false);
    ObjectSetInteger(ChartID(), m_name, OBJPROP_ZORDER, 1);
    ObjectSetInteger(ChartID(), m_name, OBJPROP_ALIGN, ALIGN_CENTER);
    ObjectSetInteger(ChartID(), m_name, OBJPROP_STATE, false);
    ObjectSetInteger(ChartID(), m_name, OBJPROP_BGCOLOR, m_background_color);
    ObjectSetString(ChartID(), m_name, OBJPROP_TOOLTIP, m_tooltip);
};

/*void IDrawable::DrawUpdate() {
    ObjectCreate(ChartID(), name, object, 0, 0, 0);
    ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, object_color);
    ObjectSetInteger(ChartID(), name, OBJPROP_BACK, false);
    ObjectSetInteger(ChartID(), name, OBJPROP_ZORDER, 1);
    ObjectSetInteger(ChartID(), name, OBJPROP_ALIGN, ALIGN_CENTER);
    ObjectSetInteger(ChartID(), name, OBJPROP_STATE, ObjectGetInteger(ChartID(), name, OBJPROP_STATE));
    ObjectSetInteger(ChartID(), name, OBJPROP_BGCOLOR, background_color);
    ObjectSetString(ChartID(), name, OBJPROP_TOOLTIP, tooltip);
};*/