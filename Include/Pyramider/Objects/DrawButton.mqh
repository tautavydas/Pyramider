// ###<Experts/Pyramider.mq5>

class DrawButton final : public StateObject<Parameters> {
   public:
    class Pair final {
       public:
        double price, volume;
        Pair(double const price_, double const volume_)
            : price(price_), volume(volume_) {}
    }* Levels[];

    string const line_tooltip;
    color const colour;
    uint const digits;

   public:
    uint counter;
    DrawButton(CProportionsManager const& proportions_manager, uint const coefX, ENUM_POSITION_TYPE const position_type, string const action, uint const digits_)
        : StateObject((position_type == POSITION_TYPE_BUY ? "Long" : "Short") + action,
                      (position_type == POSITION_TYPE_BUY ? "Long" : "Short") + action,
                      action,
                      new Parameters(proportions_manager, coefX, position_type, 2, 1)),
          counter(0),
          line_tooltip(action == "Deals" ? "trade_volume" : "total_volume"),
          colour(action == "Deals" ? (position_type == POSITION_TYPE_BUY ? Cyan : Orange) : (position_type == POSITION_TYPE_BUY ? Violet : Red)),
          digits(digits_) {}

    ~DrawButton() {
        delete Parameters;
        DeleteLines();
        DeleteLevels();
    }

    void Hide() {
        StateObject<Parameters>::Hide();
        DeleteLines();
    }

    void ResetCounter() { counter = 0; }
    uint SizeCounter() { return counter; }

    void Push(double const price, double const volume) {
        if (counter < Levels.Size()) {
            Levels[counter].price = price;
            Levels[counter].volume = volume;
            ++counter;
        } else {
            if (Levels.Push(new Pair(price, volume)))
                ++counter;
            else {
                PrintFormat("%s WTF", __FUNCTION__);
            }
        }
    }

    void Drop(uint const count) {
        counter -= fmin(counter, count);
    }

    void DeleteLevels() {
        for (uint i{0}; i < Levels.Size(); ++i) {
            delete Levels[i];
        }
    }

    void DrawLines() {
        uint cnt{0};
        for (; cnt < counter; ++cnt) {
            DrawLine(cnt);
        }
        DeleteExcessLines(cnt);
    }

    void DeleteLines() {
        uint cnt{0};
        for (; cnt < counter; ++cnt) {
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

    string Name(uint const cnt) const {
        return StringFormat("%s %u", name, cnt);
    }

   private:
    void DrawLine(uint const cnt) {
        string const deal_name{Name(cnt)};
        ObjectCreate(ChartID(), deal_name, OBJ_HLINE, 0, 0, Levels[cnt].price);
        ObjectSetString(ChartID(), deal_name, OBJPROP_TOOLTIP, StringFormat("%s %s %.*f", deal_name, line_tooltip, digits, Levels[cnt].volume));
        ObjectSetInteger(ChartID(), deal_name, OBJPROP_ZORDER, 0);
        ObjectSetInteger(ChartID(), deal_name, OBJPROP_BACK, true);
        ObjectSetInteger(ChartID(), deal_name, OBJPROP_COLOR, colour);
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
        if (counter < Levels.Size()) {
            for (; cnt < Levels.Size(); ++cnt) {
                // DeleteLine(cnt);
                ObjectDelete(ChartID(), Name(cnt));
            }
        }
    }

    void DeleteExcessLevels(uint cnt) {
        if (counter < Levels.Size()) {
            for (; cnt < Levels.Size(); ++cnt) {
                delete Levels[cnt];
            }
            ArrayResize(Levels, counter);
        }
    }
};