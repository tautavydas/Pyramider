// ###<Experts/Pyramider.mq5>

// #include <Generic/Stack.mqh>
#include <Pyramider/Objects/Parameters.mqh>
#include <Pyramider/Objects/Stateful.mqh>

class DrawButton final : public Stateful<Parameters> {
   public:
    class Pair final {
       public:
        double m_price, m_volume;
        Pair(double const price, double const volume)
            : m_price(price), m_volume(volume) {}
    }* Levels[];

    string const m_line_tooltip;
    color const m_colour;
    ENUM_LINE_STYLE const m_style;
    uint const m_digits;

   public:
    uint m_counter;
    DrawButton(CProportionsManager const& proportions_manager, uint const coefX, ENUM_POSITION_TYPE const position_type, string const text, uint const digits)
        : Stateful((position_type == POSITION_TYPE_BUY ? "Long" : "Short") + text,
                   (position_type == POSITION_TYPE_BUY ? "Long" : "Short") + text,
                   text,
                   new Parameters(proportions_manager, coefX, position_type, 2, 1)),
          m_counter(0),
          m_line_tooltip(text == "Deals" ? "trade_volume" : "total_volume"),
          m_colour(text == "Deals" ? (position_type == POSITION_TYPE_BUY ? clrTeal : clrChocolate) : (text == "Positions" ? (position_type == POSITION_TYPE_BUY ? clrSteelBlue : clrSaddleBrown) : (position_type == POSITION_TYPE_BUY ? clrBlue : clrRed))),
          m_style(text == "Deals" ? STYLE_DOT : (text == "Positions" ? STYLE_DASH : STYLE_SOLID)),
          m_digits(digits) {}

    ~DrawButton() {
        delete Parameters;
        DeleteLines();
        DeleteLevels();
    }

    void Hide() {
        Stateful<Parameters>::Hide();
        DeleteLines();
    }

    void ResetCounter() {
        m_counter = 0;
    }
    uint SizeCounter() {
        return m_counter;
    }

    void Push(double const price, double const volume) {
        if (m_counter < Levels.Size()) {
            Levels[m_counter].m_price = price;
            Levels[m_counter].m_volume = volume;
        } else {
            while (Levels.Size() + 1 != ArrayResize(Levels, Levels.Size() + 1)) {
            }
            Levels[Levels.Size() - 1] = new Pair(price, volume);
        }
        ++m_counter;
    }

    void Drop(uint const restricted_count) {
        m_counter -= fmin(m_counter, restricted_count);
    }

    void DrawLines() {
        // if (m_state) {
        for (uint cnt{0}; cnt < m_counter; ++cnt) {
            DrawLine(cnt);
        }
        DeleteExcessLines();
        setText(string(m_counter));
        // PrintFormat("%s %u", __FUNCTION__, m_counter);
        // }
    }

    void DeleteLines() {
        // if (!m_state) {
        for (uint cnt{0}; cnt < m_counter; ++cnt) {
            // DeleteLine(cnt);
            ObjectDelete(ChartID(), Name(cnt));
        }
        DeleteExcessLines();
        DeleteExcessLevels();
        resetText();
        //}
    }

    bool State() const {
        // bool const state = bool(ObjectGetInteger(ChartID(), m_name, OBJPROP_STATE));
        //  ObjectSetString(ChartID(), m_name, OBJPROP_TEXT, m_text);
        return bool(ObjectGetInteger(ChartID(), m_name, OBJPROP_STATE));
    }

    /*double Price(uint const cnt) const {
      return ObjectGetDouble(ChartID(), Name(cnt), OBJPROP_PRICE);
    }*/

    /*double Volume(uint const cnt) const {
      string result[];
      uint const size{StringSplit(ObjectGetString(ChartID(), Name(cnt), OBJPROP_TOOLTIP), ' ', result)};
      return size > 0 ? StringToDouble(result[size - 1]) : 6.66;
    }*/

    string Name(uint const cnt) const {
        return StringFormat("%s %u", m_name, cnt);
    }

   private:
    void DrawLine(uint const cnt) {
        string const deal_name{Name(cnt)};
        // PrintFormat("%s %s %u", __FUNCTION__, deal_name, cnt);
        ObjectCreate(ChartID(), deal_name, OBJ_HLINE, 0, 0, Levels[cnt].m_price);
        ObjectSetString(ChartID(), deal_name, OBJPROP_TOOLTIP, StringFormat("%s %s %.*f", deal_name, m_line_tooltip, m_digits, Levels[cnt].m_volume));
        ObjectSetInteger(ChartID(), deal_name, OBJPROP_ZORDER, 0);
        ObjectSetInteger(ChartID(), deal_name, OBJPROP_BACK, true);
        ObjectSetInteger(ChartID(), deal_name, OBJPROP_COLOR, m_colour);
        ObjectSetInteger(ChartID(), deal_name, OBJPROP_STYLE, m_style);
    }

    // void DeleteLine(uint const cnt) const {
    // if (Find(cnt)) {
    //    ObjectDelete(ChartID(), Name(cnt));
    //}
    //}

    /*bool Find(uint const cnt) const {
      return ObjectFind(ChartID(), Name(cnt)) >= 0;
    }*/

    void DeleteExcessLines() {
        // if (m_counter < Levels.Size()) {
        for (uint i{m_counter}; i < Levels.Size(); ++i) {
            // DeleteLine(cnt);
            ObjectDelete(ChartID(), Name(i));
        }
        //}
    }

    void DeleteLevels() {
        for (uint i{0}; i < Levels.Size(); ++i) {
            delete Levels[i];
        }
    }

    void DeleteExcessLevels() {
        // if (m_counter < Levels.Size()) {
        for (uint i{m_counter}; i < Levels.Size(); ++i) {
            delete Levels[i];
        }
        ArrayResize(Levels, m_counter);
        // PrintFormat("%s %u %u", __FUNCTION__, m_counter, Levels.Size());
        //}
    }
};