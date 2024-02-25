// ###<Experts/Pyramider.mq5>

class IDrawable {
   public:
    string const name;

   protected:
    ENUM_OBJECT const object;
    string const tooltip;
    color const object_color, const background_color;

    IDrawable(ENUM_OBJECT const object_, string const name_, string const tooltip_, color const object_color_, color const background_color_)
        : object(object_),
          name(name_),
          tooltip(tooltip_),
          object_color(object_color_),
          background_color(background_color_) {}

    ~IDrawable() { Hide(); }

   public:
    virtual void Draw() = 0;
    void Hide() const { ObjectDelete(ChartID(), name); }
};

void IDrawable::Draw() {
    ObjectCreate(ChartID(), name, object, 0, 0, 0);
    // ObjectSetString(ChartID(), name, OBJPROP_FONT, "Calibri");
    ObjectSetInteger(ChartID(), name, OBJPROP_ZORDER, 1);
    ObjectSetInteger(ChartID(), name, OBJPROP_BACK, false);
    ObjectSetInteger(ChartID(), name, OBJPROP_ALIGN, ALIGN_CENTER);
    ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, object_color);
    ObjectSetInteger(ChartID(), name, OBJPROP_BGCOLOR, background_color);
    ObjectSetString(ChartID(), name, OBJPROP_TOOLTIP, tooltip);
};