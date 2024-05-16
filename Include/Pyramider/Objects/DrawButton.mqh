// ###<Experts/Pyramider.mq5>

class DrawButton final : public StateObject<Parameters> {
   public:
    class Pair final {
       public:
        double m_price, m_volume;
        Pair(double const price, double const volume)
            : m_price(price), m_volume(volume) {}
    }* Levels[];

    string const m_line_tooltip;
    color const m_colour;
    uint const m_digits;

   public:
    uint m_counter;
    DrawButton(CProportionsManager const& proportions_manager, uint const coefX, ENUM_POSITION_TYPE const position_type, string const action, uint const digits)
        : StateObject((position_type == POSITION_TYPE_BUY ? "Long" : "Short") + action,
                      (position_type == POSITION_TYPE_BUY ? "Long" : "Short") + action,
                      action,
                      new Parameters(proportions_manager, coefX, position_type, 2, 1)),
          m_counter(0),
          m_line_tooltip(action == "Deals" ? "trade_volume" : "total_volume"),
          m_colour(action == "Deals" ? (position_type == POSITION_TYPE_BUY ? Cyan : Orange) : (position_type == POSITION_TYPE_BUY ? Violet : Red)),
          m_digits(digits) {}

    ~DrawButton() {
        delete Parameters;
        DeleteLines();
        DeleteLevels();
    }

    void Hide() {
        StateObject<Parameters>::Hide();
        DeleteLines();
    }

    void ResetCounter() { m_counter = 0; }
    uint SizeCounter() { return m_counter; }

    void Push(double const price, double const volume) {
        if (m_counter < Levels.Size()) {
            Levels[m_counter].m_price = price;
            Levels[m_counter].m_volume = volume;
            ++m_counter;
        } else {
            if (Levels.Push(new Pair(price, volume)))
                ++m_counter;
            else {
                PrintFormat("%s WTF", __FUNCTION__);
            }
        }
    }

    void Drop(uint const count) {
        m_counter -= fmin(m_counter, count);
    }

    void DeleteLevels() {
        for (uint i{0}; i < Levels.Size(); ++i) {
            delete Levels[i];
        }
    }

    void DrawLines() {
        uint cnt{0};
        for (; cnt < m_counter; ++cnt) {
            DrawLine(cnt);
        }
        DeleteExcessLines(cnt);
    }

    void DeleteLines() {
        uint cnt{0};
        for (; cnt < m_counter; ++cnt) {
            // DeleteLine(cnt);
            ObjectDelete(ChartID(), Name(cnt));
        }
        DeleteExcessLines(cnt);
        DeleteExcessLevels(cnt);
    }

    bool State() const { return bool(ObjectGetInteger(ChartID(), name, OBJPROP_STATE)); }

    /*double Price(uint const cnt) const {
      return ObjectGetDouble(ChartID(), Name(cnt), OBJPROP_PRICE);
    }*/

    /*double Volume(uint const cnt) const {
      string result[];
      uint const size{StringSplit(ObjectGetString(ChartID(), Name(cnt), OBJPROP_TOOLTIP), ' ', result)};
      return size > 0 ? StringToDouble(result[size - 1]) : 6.66;
    }*/

    string Name(uint const cnt) const { return StringFormat("%s %u", name, cnt); }

   private:
    void DrawLine(uint const cnt) {
        string const deal_name{Name(cnt)};
        ObjectCreate(ChartID(), deal_name, OBJ_HLINE, 0, 0, Levels[cnt].m_price);
        ObjectSetString(ChartID(), deal_name, OBJPROP_TOOLTIP, StringFormat("%s %s %.*f", deal_name, m_line_tooltip, m_digits, Levels[cnt].m_volume));
        ObjectSetInteger(ChartID(), deal_name, OBJPROP_ZORDER, 0);
        ObjectSetInteger(ChartID(), deal_name, OBJPROP_BACK, true);
        ObjectSetInteger(ChartID(), deal_name, OBJPROP_COLOR, m_colour);
        ObjectSetInteger(ChartID(), deal_name, OBJPROP_STYLE, STYLE_DOT);
    }

    // void DeleteLine(uint const cnt) const {
    // if (Find(cnt)) {
    //    ObjectDelete(ChartID(), Name(cnt));
    //}
    //}

    /*bool Find(uint const cnt) const {
      return ObjectFind(ChartID(), Name(cnt)) >= 0;
    }*/

    void DeleteExcessLines(uint cnt) {
        if (m_counter < Levels.Size()) {
            for (; cnt < Levels.Size(); ++cnt) {
                // DeleteLine(cnt);
                ObjectDelete(ChartID(), Name(cnt));
            }
        }
    }

    void DeleteExcessLevels(uint cnt) {
        if (m_counter < Levels.Size()) {
            for (; cnt < Levels.Size(); ++cnt) {
                delete Levels[cnt];
            }
            ArrayResize(Levels, m_counter);
        }
    }
};