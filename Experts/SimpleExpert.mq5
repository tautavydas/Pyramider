#property copyright "TJ Productions"
#property link "https://www.mql5.com"
#property version "6.66"

// #resource "\\Indicators\\SubWindow.ex5"

#include <Generic/HashMap.mqh>

input double PriceRatioLong = 1, PriceRatioShort = 1,
             NotionalRatioLong = 1, NotionalRatioShort = 1,
             ProfitRatioLong = 1, ProfitRatioShort = 1,
             Xproportions = 0.025, Yproportions = 0.05;
// input uint PriceRatioDigits    = 3    , NotionalRatioDigits = 2;
input uint NotionalRatioDigits = 2;

/*class CDigitManager final {
  uint price_ratio_digits, notional_ratio_digits;
 public:
  CDigitManager() : price_ratio_digits(PriceRatioDigits), notional_ratio_digits(NotionalRatioDigits) {}

  void UpdateDigits() {}
};*/

class CProportionsManager final {
  public:
    uint button_width_pixels, button_height_pixels, start_pixel;

    void UpdateProportions() {
        long const Height{ChartGetInteger(ChartID(), CHART_HEIGHT_IN_PIXELS)};
        long const Width{ChartGetInteger(ChartID(), CHART_WIDTH_IN_PIXELS)};
        button_width_pixels  = uint(round(Xproportions * Width));
        button_height_pixels = uint(round(Yproportions * Height));
        start_pixel          = uint(round((Width - ListPeriods.Size() * button_width_pixels) / 2));
    }

} ProportionsManager;

double const Contract{SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE)}, const MarginCall{AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL) / 100};
long const   Leverage{AccountInfoInteger(ACCOUNT_LEVERAGE)};

struct CVolumes final {
    double const VolumeMin, const VolumeMax, const VolumeStep, const VolumeLimit;
    CVolumes() : VolumeMin(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)),
                 VolumeMax(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)),
                 VolumeStep(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP)),
                 VolumeLimit(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_LIMIT)) {}
} const Volumes;

struct CMagic final {
    long const Number;
    CMagic() : Number(666666666666666666) {}
} const Magic;

typedef double (*PtrConvert)(double const quote1, double const quote2);
double NoConvert(double const quote1, double const quote2) { return quote1; }
double ForwardConvert(double const quote1, double const quote2) { return quote1 * quote2; }
double BackwardConvert(double const quote1, double const quote2) { return quote1 / quote2; }

class CSubConverter final {
  private:
    string const     Pair;
    PtrConvert const Forward, const Backward;

  public:
    CSubConverter() : Pair(""), Forward(NoConvert), Backward(NoConvert) {}
    CSubConverter(string const pair) : Pair(pair), Forward(ForwardConvert), Backward(BackwardConvert) {}

    double ConvertForward(double const quote, ENUM_SYMBOL_INFO_DOUBLE const type) const {
        return Forward(quote, SymbolInfoDouble(Pair, type));
    }

    double ConvertBackward(double const quote, ENUM_SYMBOL_INFO_DOUBLE const type) const {
        return Backward(quote, SymbolInfoDouble(Pair, type));
    }
};

class CConverter final {
  private:
    CSubConverter const *const Arbiter, const *const Deposit;

  public:
    CConverter(string const quote, string const middle, string const account)
        : Arbiter(quote == middle ? new CSubConverter : new CSubConverter(quote + middle)),
          Deposit(account == middle ? new CSubConverter : new CSubConverter(account + middle)) {
    }

    ~CConverter() {
        delete Arbiter;
        delete Deposit;
    }

    double QuoteToArbiter(double const quote, ENUM_SYMBOL_INFO_DOUBLE const type) const {
        return Arbiter.ConvertForward(quote, type);
    }

    double ArbiterToDeposit(double const quote, ENUM_SYMBOL_INFO_DOUBLE const type) const {
        return Deposit.ConvertBackward(quote, type);
    }

    double QuoteToDeposit(double const quote, ENUM_SYMBOL_INFO_DOUBLE const type) const {
        return Deposit.ConvertBackward(Arbiter.ConvertForward(quote, type), type);
    }

    double DepositToQuote(double const quote, ENUM_SYMBOL_INFO_DOUBLE const type) const {
        return Arbiter.ConvertBackward(Deposit.ConvertForward(quote, type), type);
    }
} const Converter(SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT), "USD", AccountInfoString(ACCOUNT_CURRENCY));

typedef double (*OperationPtr)(double const, double const);
double Add(double const op1, double const op2) { return op1 + op2; }
double Sub(double const op1, double const op2) { return op1 - op2; }

class Parameters {
  protected:
    uint const coefX, const coefY, const coefW, const coefH;

  public:
    Parameters(uint const coefX_, uint const coefY_, uint const coefW_, uint const coefH_)
        : coefX(coefX_), coefY(coefY_), coefW(coefW_), coefH(coefH_) {}
    Parameters(uint const coefX_, ENUM_POSITION_TYPE const position_type, uint const coefW_, uint const coefH_)
        : coefX(coefX_), coefY(position_type == POSITION_TYPE_BUY ? 2 : 1), coefW(coefW_), coefH(coefH_) {}

    void DrawParameters(string const name) const {
        uint const size_x{SizeX()}, const size_y{SizeY()};
        ObjectSetInteger(ChartID(), name, OBJPROP_FONTSIZE, 2 + uint(round(sqrt(sqrt(size_x * size_y)))));
        ObjectSetInteger(ChartID(), name, OBJPROP_XDISTANCE, ProportionsManager.start_pixel + CoordinateX());
        ObjectSetInteger(ChartID(), name, OBJPROP_YDISTANCE, CoordinateY());
        ObjectSetInteger(ChartID(), name, OBJPROP_XSIZE, size_x);
        ObjectSetInteger(ChartID(), name, OBJPROP_YSIZE, size_y);
    }

  private:
    uint SizeX() const { return ProportionsManager.button_width_pixels * coefW; }
    uint SizeY() const { return ProportionsManager.button_height_pixels / coefH; }
    uint CoordinateX() const { return ProportionsManager.button_width_pixels * coefX; }

  protected:
    uint virtual CoordinateY() const { return ProportionsManager.button_height_pixels * coefY; }
};

class ParametersStandard : public Parameters {
  public:
    OperationPtr const Operation;
    ParametersStandard(uint const coefX_, ENUM_POSITION_TYPE const position_type, uint const coefW_, uint const coefH_)
        : Parameters(coefX_, position_type, coefW_, coefH_), Operation(Add) {}
};

class ParametersShifted final : public Parameters {
  public:
    OperationPtr const Operation;
    ParametersShifted(uint const coefX_, ENUM_POSITION_TYPE const position_type, uint const coefW_, uint const coefH_)
        : Parameters(coefX_, position_type, coefW_, coefH_), Operation(Sub) {}

  private:
    uint CoordinateY() const override { return Parameters::CoordinateY() + ProportionsManager.button_height_pixels / 2; }
};

class DrawableObject {
  public:
    string const name;

  protected:
    ENUM_OBJECT const object;
    string const      tooltip;
    color const       object_color, const background_color;

    DrawableObject(ENUM_OBJECT const object_, string const name_, string const tooltip_, color const object_color_, color const background_color_)
        : object(object_),
          name(name_), tooltip(tooltip_),
          object_color(object_color_), background_color(background_color_) {}

    ~DrawableObject() {
        Hide();
    }

  public:
    virtual void Draw() = 0;

    void Hide() const {
        ObjectDelete(ChartID(), name);
    }
};

void DrawableObject::Draw() {
    ObjectCreate(ChartID(), name, object, 0, 0, 0);
    // ObjectSetString(ChartID(), name,OBJPROP_FONT, "Calibri");
    ObjectSetInteger(ChartID(), name, OBJPROP_ZORDER, 1);
    ObjectSetInteger(ChartID(), name, OBJPROP_BACK, false);
    ObjectSetInteger(ChartID(), name, OBJPROP_ALIGN, ALIGN_CENTER);
    ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, object_color);
    ObjectSetInteger(ChartID(), name, OBJPROP_BGCOLOR, background_color);
    ObjectSetString(ChartID(), name, OBJPROP_TOOLTIP, tooltip);
}

template<typename TParameters>
class StateObject : public DrawableObject {
    string const text;
    color const  border_color;

  public:
    TParameters const *const Parameters;
    StateObject(string const name_, string const tooltip_, string const text_, TParameters const *const parameters)
        : DrawableObject(OBJ_BUTTON, name_, tooltip_, clrBlack, clrWhiteSmoke),
          text(text_),
          border_color(clrNONE),
          Parameters(parameters) {}

    ~StateObject() { delete Parameters; }

  public:
    void Draw() {
        DrawableObject::Draw();
        ObjectSetString(ChartID(), name, OBJPROP_TEXT, text);
        ObjectSetInteger(ChartID(), name, OBJPROP_BORDER_COLOR, border_color);
        Parameters.DrawParameters(name);
    }

    void Set() const { ObjectSetInteger(ChartID(), name, OBJPROP_STATE, true); }
    void Unset() const { ObjectSetInteger(ChartID(), name, OBJPROP_STATE, false); }
};

class DrawButton final : public StateObject<Parameters> {
  public:
    class Pair final {
      public:
        double price, volume;
        Pair(double const price_, double const volume_)
            : price(price_), volume(volume_) {}
    } *Levels[];

    string const line_tooltip;
    color const  colour;
    uint const   digits;

  public:
    uint counter;
    DrawButton(uint const coefX, ENUM_POSITION_TYPE const position_type, string const action, uint const digits_)
        : StateObject((position_type == POSITION_TYPE_BUY ? "Long" : "Short") + action,
                      (position_type == POSITION_TYPE_BUY ? "Long" : "Short") + action,
                      action,
                      new Parameters(coefX, position_type, 2, 1)),
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
        if(counter < Levels.Size()) {
            Levels[counter].price  = price;
            Levels[counter].volume = volume;
            ++counter;
        } else {
            if(Levels.Push(new Pair(price, volume)))
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
        for(uint i{0}; i < Levels.Size(); ++i) {
            delete Levels[i];
        }
    }

    void DrawLines() {
        uint cnt{0};
        for(; cnt < counter; ++cnt) {
            DrawLine(cnt);
        }
        DeleteExcessLines(cnt);
    }

    void DeleteLines() {
        uint cnt{0};
        for(; cnt < counter; ++cnt) {
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
        if(counter < Levels.Size()) {
            for(; cnt < Levels.Size(); ++cnt) {
                // DeleteLine(cnt);
                ObjectDelete(ChartID(), Name(cnt));
            }
        }
    }

    void DeleteExcessLevels(uint cnt) {
        if(counter < Levels.Size()) {
            for(; cnt < Levels.Size(); ++cnt) {
                delete Levels[cnt];
            }
            ArrayResize(Levels, counter);
        }
    }
};

class PeriodButton : public StateObject<Parameters> {
  public:
    PeriodButton(ENUM_TIMEFRAMES const &periods[], uint const coefX)
        : StateObject(EnumToString(periods[coefX]),
                      EnumToString(periods[coefX]),
                      StringSubstr(EnumToString(periods[coefX]), 7),
                      new Parameters(coefX, 0, 1, 1)) {}
};

class ActionButton : public StateObject<Parameters> {
  public:
    ActionButton(uint const coefX, ENUM_POSITION_TYPE const position_type, string const action)
        : StateObject((position_type == POSITION_TYPE_BUY ? "Long" : "Short") + action,
                      position_type == POSITION_TYPE_BUY ? "Buy" : "Sell",
                      action,
                      new Parameters(coefX, position_type, 2, 1)) {}

    // void UpdatePrice() const {/*PrintFormat("%s yo", __FUNCTION__);*//*Edit.SetValue();*/}
};

template<typename TParams>
class ChangeButton final : public StateObject<TParams> {
  public:
    ChangeButton(uint const coefX, ENUM_POSITION_TYPE const position_type, string const name_)
        : StateObject(name_ + (typename(TParams) == typename(ParametersStandard) ? "Up" : "Down"),
                      typename(TParams) == typename(ParametersStandard) ? "Increase" : "Decrease",
                      typename(TParams) == typename(ParametersStandard) ? "Up" : "Down",
                      new TParams(coefX + 2, position_type, 1, 2)) {
    }
};

class CListPeriods final {
  public:
    class CPair final {
      public:
        ENUM_TIMEFRAMES const     Timeframe;
        PeriodButton const *const Button;
        CPair(ENUM_TIMEFRAMES const timeframe, PeriodButton const &button)
            : Timeframe(timeframe), Button(&button) {
        }
    };

  private:
    ENUM_TIMEFRAMES Periods[];
    PeriodButton *Buttons[], const *Button;
    CHashMap<string, CPair *> *const Map;

  public:
    CListPeriods()
        : Map(new CHashMap<string, CPair *>) {
        ENUM_TIMEFRAMES const periods[]{PERIOD_M1, PERIOD_M2, PERIOD_M3, PERIOD_M4, PERIOD_M5, PERIOD_M6, PERIOD_M10, PERIOD_M12, PERIOD_M15, PERIOD_M20, PERIOD_M30, PERIOD_H1, PERIOD_H2, PERIOD_H3, PERIOD_H4, PERIOD_H6, PERIOD_H8, PERIOD_H12, PERIOD_D1, PERIOD_W1, PERIOD_MN1};

        ArrayResize(Buttons, ArrayCopy(Periods, periods));
        for(uint i{0}; i < Buttons.Size(); ++i) {
            Buttons[i] = new PeriodButton(Periods, i);
            Map.Add(Buttons[i].name, new CPair(Periods[i], Buttons[i]));
        }

        Draw();
    }

    ~CListPeriods() {
        CKeyValuePair<string, CPair *> *Pairs[];
        Map.CopyTo(Pairs);
        for(uint i{0}; i < Pairs.Size(); ++i) {
            delete Buttons[i];
            delete Pairs[i].Value();
            delete Pairs[i];
        }
        delete Map;
    }

    uint Size() const { return Buttons.Size(); }

    void Draw() {
        for(uint i{0}; i < Buttons.Size(); ++i) {
            Buttons[i].Draw();
            if(Period() == Periods[i]) {
                Button = Buttons[i];
                Button.Set();
            }
        }
    }

    void UpdateButton() {
        CPair *Pair;
        if(Map.TryGetValue(EnumToString(ENUM_TIMEFRAMES(Period())), Pair)) {
            Button.Unset();
            Button = Pair.Button;
            Button.Set();
        }
    }

    void ChangePeriod(string const &sparam) {
        CPair *Pair;
        if(Map.TryGetValue(sparam, Pair)) {
            if(Button != Pair.Button) {
                ChartSetSymbolPeriod(ChartID(), Symbol(), Pair.Timeframe);
            }
            Button.Unset();
            Button = Pair.Button;
            Button.Set();
        }
    }
} ListPeriods;

class IFunction {
  public:
    virtual double Init() const                 = 0;
    virtual double onButton(double const) const = 0;
    virtual double onTick(double const) const   = 0;
};

class ExtremumMin final {
  public:
    double process(double const val1, double const val2) const { return fmin(val1, val2); }
};

class ExtremumMax final {
  public:
    double process(double const val1, double const val2) const { return fmax(val1, val2); }
};

template<typename TMinMax>
class ClampPrice final : public IFunction {
    TMinMax const MinMax;
    double const  PriceRatio;

  public:
    ENUM_SYMBOL_INFO_DOUBLE const QuoteIn;
    ClampPrice(ENUM_POSITION_TYPE const position_type, double const price_ratio)
        : PriceRatio(price_ratio),
          QuoteIn(position_type == POSITION_TYPE_BUY ? SYMBOL_ASK : SYMBOL_BID) {}

    double Init() const override { return onButton(SymbolInfoDouble(Symbol(), QuoteIn)) * PriceRatio; }
    double onTick(double const val) const override { return MinMax.process(SymbolInfoDouble(Symbol(), QuoteIn), val); }
    double onButton(double const val) const override {
        double const Val{fmax(0, val)}, const current_price{SymbolInfoDouble(Symbol(), QuoteIn)};
        // if (PositionReporter.getStatus()) {
        // PrintFormat("%s %f %f %f | %f", __FUNCTION__, PositionReporter.getPrice(), current_price, val, MinMax.process(MinMax.process(PositionReporter.getPrice(), current_price), val));
        //  return MinMax.process(MinMax.process(PositionReporter.getPrice(), current_price), val);
        //} else {
        return MinMax.process(current_price, val);
        //}
    }
};

class ClampPriceRatio final : public IFunction {
    double const default_value, const lower_boundary, const higher_boundary;

  public:
    ClampPriceRatio(ENUM_POSITION_TYPE const position_type, double const default_value_)
        : default_value(default_value_),
          lower_boundary(position_type == POSITION_TYPE_BUY ? 0 : 1),
          higher_boundary(position_type == POSITION_TYPE_BUY ? 1 : DBL_MAX) {}

    double Init() const override { return onButton(default_value); }
    double onTick(double const val) const override { return val; }
    double onButton(double const val) const override { return fmax(lower_boundary, fmin(higher_boundary, val)); }
};

class ClampVolumeInit final : public IFunction {
  public:
    ClampVolumeInit() {}

    double Init() const override { return onButton(PositionReporter.getAvgVolume()); }
    double onTick(double const val) const override { return val; }
    double onButton(double const val) const override { return fmax(Volumes.VolumeMin, val); }
};

class ClampValue final : public IFunction {
    double const init_value, const lower_boundary, const higher_boundary;

  public:
    ClampValue(double const init_value_, double const lower_boundary_, double const higher_boundary_)
        : init_value(init_value_),
          lower_boundary(lower_boundary_),
          higher_boundary(higher_boundary_) {}

    double Init() const override { return onButton(init_value); }
    double onTick(double const val) const override { return val; }
    double onButton(double const val) const override { return fmax(lower_boundary, fmin(higher_boundary, val)); }
};

template<typename T>
class ClampRestricted final : public IFunction {
    // double const init_value, const lower_boundary;
    CObject<T> const *const Parent;

  public:
    ClampRestricted(CObject<T> const &parent)
        :   // init_value(0),
            // lower_boundary(0),
          Parent(&parent) {}

    double Init() const override { return onButton(0); }
    double onTick(double const val) const override { return val; }
    double onButton(double const val) const override { return fmax(0, fmin(Parent.getCount(), val)); }
};

class CEdit final : public DrawableObject {
    color const  border_color;
    double const step;
    bool         BoolInit;

  public:
    IFunction const *const                  Function;
    Parameters const *const                 Params;
    ChangeButton<ParametersStandard> *const ValueUp;
    ChangeButton<ParametersShifted> *const  ValueDown;
    uint const                              digits;
    CEdit(IFunction const *const function, uint const coefX, ENUM_POSITION_TYPE const position_type, string const name_, double const digits_)
        : DrawableObject(OBJ_EDIT, (position_type == POSITION_TYPE_BUY ? "Long" : "Short") + name_, name_, position_type == POSITION_TYPE_BUY ? clrBlue : clrRed, clrLightGray),
          border_color(clrGray),
          step(pow(10.0, -digits_)),
          BoolInit(true),
          Function(function),
          Params(new Parameters(coefX, position_type, 2, 1)),
          ValueUp(new ChangeButton<ParametersStandard>(coefX, position_type, name)),
          ValueDown(new ChangeButton<ParametersShifted>(coefX, position_type, name)),
          digits(uint(digits_)) {}

    ~CEdit() {
        delete Function;
        delete Params;
        delete ValueUp;
        delete ValueDown;
    }

    void Draw() {
        DrawableObject::Draw();
        ObjectSetInteger(ChartID(), name, OBJPROP_BORDER_COLOR, border_color);
        ValueUp.Draw();
        ValueDown.Draw();
        Params.DrawParameters(name);
        if(BoolInit) {
            setText(Function.Init());
            BoolInit = false;
        }
    }

    void Hide() {
        DrawableObject::Hide();
        ValueUp.Hide();
        ValueDown.Hide();
        BoolInit = true;
    }

    double getValue() const { return StringToDouble(ObjectGetString(ChartID(), name, OBJPROP_TEXT)); }
    void   editValue() const { setText(Function.onButton(getValue())); }
    void   changeValue(OperationPtr const &Operation) const { setText(Function.onButton(Operation(getValue(), step))); }

  private:
    void setValue() const { setText(Function.onTick(getValue())); }
    void setText(double const display_value) const { ObjectSetString(ChartID(), name, OBJPROP_TEXT, StringFormat("%.*f", digits, display_value)); }
};

template<typename TMinMax>
class CListEdits final {
  public:
    template<typename TChangeButton>
    class CPair final {
        CEdit const *const         Edit;
        TChangeButton const *const Button;

      public:
        CPair(CEdit const &edit, TChangeButton const *const button)
            : Edit(&edit), Button(button) {}

        void ChangeValue() const {
            Edit.changeValue(Button.Parameters.Operation);
            Button.Unset();
        }
    };

  private:
    CEdit                                                             *Edits[5];
    CHashMap<string, CEdit *> *const                                   MapEdit;
    CHashMap<string, CPair<ChangeButton<ParametersStandard>> *> *const ValueUp;
    CHashMap<string, CPair<ChangeButton<ParametersShifted>> *> *const  ValueDown;

  public:
    CListEdits(ENUM_POSITION_TYPE const position_type, double const price_ratio, double const notional_ratio, CObject<TMinMax> const &parent)
        : MapEdit(new CHashMap<string, CEdit *>),
          ValueUp(new CHashMap<string, CPair<ChangeButton<ParametersStandard>> *>),
          ValueDown(new CHashMap<string, CPair<ChangeButton<ParametersShifted>> *>) {

        Edits[0] = new CEdit(new ClampPrice<TMinMax>(position_type, price_ratio), 2, position_type, "Price", Digits());
        Edits[1] = new CEdit(new ClampPriceRatio(position_type, price_ratio), 5, position_type, "PriceRatio", Digits());
        Edits[2] = new CEdit(new ClampVolumeInit(), 8, position_type, "VolumeInit", -log10(Volumes.VolumeMin));
        Edits[3] = new CEdit(new ClampValue(notional_ratio, 1, DBL_MAX), 11, position_type, "NotionalRatio", NotionalRatioDigits);
        Edits[4] = new CEdit(new ClampRestricted<TMinMax>(parent), 18, position_type, "RestrictedTrades", 0);

        for(uint i{0}; i < Edits.Size(); ++i) {
            MapEdit.Add(Edits[i].name, Edits[i]);
            ValueUp.Add(Edits[i].ValueUp.name, new CPair<ChangeButton<ParametersStandard>>(Edits[i], Edits[i].ValueUp));
            ValueDown.Add(Edits[i].ValueDown.name, new CPair<ChangeButton<ParametersShifted>>(Edits[i], Edits[i].ValueDown));
        }
    }

    ~CListEdits() {
        CKeyValuePair<string, CEdit *> *Edit[];
        MapEdit.CopyTo(Edit);
        for(uint i{0}; i < Edit.Size(); ++i) {
            delete Edit[i].Value();
            delete Edit[i];
        }
        delete MapEdit;

        CKeyValuePair<string, CPair<ChangeButton<ParametersStandard>> *> *PairsUp[];
        ValueUp.CopyTo(PairsUp);
        for(uint i{0}; i < PairsUp.Size(); ++i) {
            delete PairsUp[i].Value();
            delete PairsUp[i];
        }
        delete ValueUp;

        CKeyValuePair<string, CPair<ChangeButton<ParametersShifted>> *> *PairsDown[];
        ValueDown.CopyTo(PairsDown);
        for(uint i{0}; i < PairsDown.Size(); ++i) {
            delete PairsDown[i].Value();
            delete PairsDown[i];
        }
        delete ValueDown;
    }

    CEdit *const operator[] (uint const index) const { return Edits[index]; }

    void Draw() {
        if(PositionReporter.getStatus()) {
            Edits[0].Draw();
            Edits[1].Draw();
            Edits[2].Draw();
            Edits[3].Draw();
        } else {
            Edits[0].Draw();
            Edits[1].Draw();
            Edits[2].Draw();
            Edits[3].Draw();
        }
    }

    void Hide() {
        for(uint i{0}; i < Edits.Size(); ++i)
            Edits[i].Hide();
    }

    bool ProcessEdit(string const &sparam) const {
        CEdit *Edit;
        if(MapEdit.TryGetValue(sparam, Edit)) {
            Edit.editValue();
            return true;
        }
        return false;
    }

    bool ChangeEdit(string const &sparam) const {
        CPair<ChangeButton<ParametersStandard>> *PairUp;
        if(ValueUp.TryGetValue(sparam, PairUp)) {
            PairUp.ChangeValue();
            return true;
        }

        CPair<ChangeButton<ParametersShifted>> *PairDown;
        if(ValueDown.TryGetValue(sparam, PairDown)) {
            PairDown.ChangeValue();
            return true;
        }

        return false;
    }
};

class CPositionReporter final {
  public:
    enum EnumPositionType {
        LONG  = POSITION_TYPE_BUY,
        SHORT = POSITION_TYPE_SELL,
        NONE
    };

  private:
    bool   status;
    double balance, equity, margin, price, volume, avg_volume, profit, swap;

  public:
    /*void CalcLevels() const {
      for (uint i{0}; i < Observers.Size(); ++i) {
        Observers[i].CalcLevels();
      }
    }*/

    /*void UpdatePosition() {
      EnumPositionType const oldPosition{Position},
                       const newPosition{getPositionType()};
      if (oldPosition != newPosition) {
        Position = newPosition;
        //price = PositionGetDouble(POSITION_PRICE_OPEN);
        //updateStatus();
        //notify();
      }
    }*/

    // void notify() {}

    /*void updateStatus() {
      if (PositionSelect(Symbol())) {
        if (PositionType == PositionGetInteger(POSITION_TYPE)) {
           status=true;
        } else {
          status=false;
        }
      } else {
        status=false;
      }
    }*/

    bool getStatus() const { return status; }

    /*void setPrice() {
      if (status) {
        price = PositionGetDouble(POSITION_PRICE_OPEN);
      }
    }*/

    double getBalance() const { return balance; }

    double getEquity() const { return equity; }

    double getMargin() const { return margin; }

    double getProfit() const { return profit; }

    double getSwap() const { return swap; }

    double getPrice() const { return price; }

    double getVolume() const { return volume; }

    double getAvgVolume() const { return avg_volume; }

    /*double getVolume() const {
      if (status) {
        return PositionGetDouble(POSITION_VOLUME);
      } else {
        return SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
      }
    }*/

    // AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE)

    // private:
    EnumPositionType getPositionType() {
        if(PositionsTotal()) {
            balance = AccountInfoDouble(ACCOUNT_BALANCE) / PositionsTotal();
            equity  = AccountInfoDouble(ACCOUNT_EQUITY) / PositionsTotal();
            margin  = AccountInfoDouble(ACCOUNT_MARGIN) / PositionsTotal();
        } else {
            balance = AccountInfoDouble(ACCOUNT_BALANCE);
            equity  = AccountInfoDouble(ACCOUNT_EQUITY);
            margin  = AccountInfoDouble(ACCOUNT_MARGIN);
        }

        if(PositionSelect(Symbol()) && HistorySelectByPosition(PositionGetInteger(POSITION_TICKET))) {
            status = true;
            price  = PositionGetDouble(POSITION_PRICE_OPEN);
            volume = PositionGetDouble(POSITION_VOLUME);
            // PrintFormat("%s %u", __FUNCTION__, HistorySelectByPosition(PositionGetInteger(POSITION_TICKET)));
            avg_volume = volume / HistoryDealsTotal();
            profit     = PositionGetDouble(POSITION_PROFIT);
            swap       = PositionGetDouble(POSITION_SWAP);
            return EnumPositionType(PositionGetInteger(POSITION_TYPE));
        } else {
            status = false;
            double const zero{0};
            price      = zero / zero;
            volume     = Volumes.VolumeMin;   // SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
            avg_volume = zero / zero;
            profit     = zero / zero;
            swap       = zero / zero;
            return EnumPositionType::NONE;
        }
    }
} PositionReporter;

class IObject {
  public:
    virtual void Hide() const                          = 0;
    virtual void Draw()                                = 0;
    virtual void UpdatePrice() const                   = 0;
    virtual bool EventEdit(string const &sparam) const = 0;
    virtual bool EventButton(string const &sparam)     = 0;
    virtual void CalcLevels() const                    = 0;
};

template<typename TMinMax>
class CObject : public IObject {
    TMinMax const                 MinMax;
    ENUM_SYMBOL_INFO_DOUBLE const Quote;
    CListEdits<TMinMax> *const    ListEdits;
    CEdit *const                  RestrictedDeals,
        const *const              Price,
        const *const              PriceRatio,
        const *const              Volume,
        const *const              NotionalRatio;
    DrawButton *const DrawDeals, *const DrawPositions;
    ActionButton *const Trade, *const Reset;

    ENUM_ORDER_TYPE const Type;
    int const             Direction;
    bool                  ResetBool;

  public:
    CObject(ENUM_POSITION_TYPE const position_type, double const price_ratio, double const notional_ratio)
        : Quote(position_type == POSITION_TYPE_BUY ? SYMBOL_ASK : SYMBOL_BID),
          ListEdits(new CListEdits<TMinMax>(position_type, price_ratio, notional_ratio, this)),
          Price(ListEdits[0]),
          PriceRatio(ListEdits[1]),
          Volume(ListEdits[2]),
          NotionalRatio(ListEdits[3]),
          RestrictedDeals(ListEdits[4]),
          DrawDeals(new DrawButton(14, position_type, "Deals", Volume.digits)),
          DrawPositions(new DrawButton(16, position_type, "Positions", Volume.digits)),
          Trade(new ActionButton(0, position_type, "Trade")),
          Reset(new ActionButton(0, position_type, "Reset")),

          Type(position_type == POSITION_TYPE_BUY ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT),
          Direction(position_type == POSITION_TYPE_BUY ? -1 : 1),
          ResetBool(true) {}

    ~CObject() {
        delete ListEdits;
        delete Reset;
        delete Trade;
        delete DrawDeals;
        delete DrawPositions;
    }

    void UpdatePrice() const override {
        // Trade.UpdatePrice();
        CalcLevels();
    }

    void Draw() override {
        if(orderExists()) {
            Reset.Draw();
        } else {
            ListEdits.Draw();
            DrawDeals.Draw();
            DrawPositions.Draw();
            if(DrawDeals.State())
                Trade.Draw();
        }
    }

    void Hide() const {
        ListEdits.Hide();
        Trade.Hide();
        DrawDeals.Hide();
        DrawPositions.Hide();
        Reset.Hide();
    }

    bool EventButton(string const &sparam) {
        if(Trade.name == sparam) {
            if(DrawDeals.State()) {
                Trade.Hide();
                DrawDeals.Hide();
                DrawPositions.Hide();
                RestrictedDeals.Hide();
                ListEdits.Hide();
                for(uint i{0}; i < DrawDeals.SizeCounter(); ++i) {
                    TradeLine(i);
                }
                Reset.Draw();
            }
            ResetBool = true;
            return true;
        } else if(Reset.name == sparam) {
            Reset.Hide();
            DrawDeals.Draw();
            DrawPositions.Draw();
            ListEdits.Draw();
            for(int i{OrdersTotal() - 1}; i >= 0; i--) {
                ulong const order_ticket{OrderGetTicket(i)}, const magic_number{OrderGetInteger(ORDER_MAGIC)}, const order_type{OrderGetInteger(ORDER_TYPE)};
                // PrintFormat("%s %ld %ld %s %s", __FUNCTION__, magic_number, Magic.Number, EnumToString(ENUM_ORDER_TYPE(order_type)), EnumToString(ENUM_ORDER_TYPE(Type)));
                if(magic_number == Magic.Number && order_type == Type) {
                    MqlTradeRequest const Request{TRADE_ACTION_REMOVE, magic_number, order_ticket, Symbol(), 0, 0, 0, 0, 0, 0, Type, ORDER_FILLING_FOK, 0, 0, "set your systems volume control slightly above the normal listening level", 0, 0};
                    Send(Request);
                }
            }
        } else if(DrawDeals.name == sparam || DrawPositions.name == sparam) {
            bool const draw_deals{DrawDeals.State()}, const draw_positions{DrawPositions.State()};
            if(draw_deals || draw_positions) {
                if(ResetBool) {
                    RestrictedDeals.Draw();
                    ResetBool = false;
                }
                if(draw_deals) {
                    Trade.Draw();
                }
            } else {
                RestrictedDeals.Hide();
                Trade.Hide();
                ResetBool = true;
            }

            if(!draw_deals) {
                Trade.Hide();
                DrawDeals.DeleteLines();
            }
            if(!draw_positions)
                DrawPositions.DeleteLines();

            return true;
        }

        return ListEdits.ChangeEdit(sparam);
    }

    bool EventEdit(string const &sparam) const override {
        return ListEdits.ProcessEdit(sparam);
    }

    uint getCount() const {
        double balance{PositionReporter.getBalance()},
            equity{PositionReporter.getEquity()},
            margin{PositionReporter.getMargin()},
            profit{PositionReporter.getProfit()},
            swap{PositionReporter.getSwap()},
            // price   {PositionReporter.getStatus() ? PositionReporter.getPrice() : Price.getValue()},
            price{Price.getValue()},
            price_ratio{PriceRatio.getValue()},
            // volume  {PositionReporter.getStatus() ? PositionReporter.getAvgVolume() : VolumeInit.getValue()},
            volume{Volume.getValue()},
            // volume  {PositionReporter.getAvgVolume()},
            total_volume{volume + PositionReporter.getVolume()},
            notional{price * volume},
            notional_ratio{NotionalRatio.getValue()},
            total_notional{notional + PositionReporter.getPrice() * PositionReporter.getVolume()},
            Margin{Converter.QuoteToDeposit(total_notional * Contract / Leverage, Quote)};

        uint counter{0};
        while(Margin * MarginCall < equity && total_volume < Volumes.VolumeLimit && counter < AccountInfoInteger(ACCOUNT_LIMIT_ORDERS)) {
            price           = fmax(0, MinMax.process(price * price_ratio, price + Direction * Point()));
            notional       *= notional_ratio;
            volume          = floor(notional / price / Volumes.VolumeStep) * Volumes.VolumeStep;
            total_volume   += volume;
            total_notional += volume * price;
            Margin         += Converter.QuoteToDeposit(total_notional * Contract / Leverage, Quote);
            ++counter;
        }

        return counter;
    }

    void CalcLevels() const {
        bool const state_deals{DrawDeals.State()}, const state_positions{DrawPositions.State()};
        if(state_deals || state_positions) {
            double balance{PositionReporter.getBalance()},
                equity{PositionReporter.getEquity()},
                margin{PositionReporter.getMargin()},
                profit{PositionReporter.getProfit()},
                swap{PositionReporter.getSwap()},
                // price   {PositionReporter.getStatus() ? PositionReporter.getPrice() : Price.getValue()},
                price{Price.getValue()},
                price_ratio{PriceRatio.getValue()},
                // volume  {PositionReporter.getStatus() ? PositionReporter.getAvgVolume() : VolumeInit.getValue()},
                volume{Volume.getValue()},
                // volume {PositionReporter.getAvgVolume()},
                total_volume{volume + PositionReporter.getVolume()},
                notional{price * volume},
                notional_ratio{NotionalRatio.getValue()},
                total_notional{notional + PositionReporter.getPrice() * PositionReporter.getVolume()},
                Margin{Converter.QuoteToDeposit(total_notional * Contract / Leverage, Quote)};

            // PrintFormat("%s %f %f %f | %f", __FUNCTION__, PositionReporter.getPrice(), PositionReporter.getVolume(), PositionReporter.getPrice() * PositionReporter.getVolume(), total_notional);
            // PrintFormat("%f %f %f", price, PositionReporter.getPrice(), Price.getValue());
            // PrintFormat("%s %s %f | %f %f %f %f | %f %f %f | %f %f | %u", __FUNCTION__, string(PositionReporter.getStatus()), price, SymbolInfoDouble(Symbol(), SYMBOL_BIDLOW), SymbolInfoDouble(Symbol(), SYMBOL_BIDHIGH), SymbolInfoDouble(Symbol(), SYMBOL_ASKLOW), SymbolInfoDouble(Symbol(), SYMBOL_ASKHIGH), SymbolInfoDouble(Symbol(), SYMBOL_ASKHIGH) - SymbolInfoDouble(Symbol(), SYMBOL_BIDLOW), (SymbolInfoDouble(Symbol(), SYMBOL_ASKHIGH) - SymbolInfoDouble(Symbol(), SYMBOL_BIDLOW)) / Point(), Point() / (SymbolInfoDouble(Symbol(), SYMBOL_ASKHIGH) - SymbolInfoDouble(Symbol(), SYMBOL_BIDLOW)), Point(), SymbolInfoDouble(Symbol(), SYMBOL_POINT), SymbolInfoInteger(Symbol(), SYMBOL_DIGITS));

            // if (state_deals    ) DrawDeals    .ResetCounter();
            // if (state_positions) DrawPositions.ResetCounter();
            DrawDeals.ResetCounter();
            DrawPositions.ResetCounter();
            while(Margin * MarginCall < equity && total_volume < Volumes.VolumeLimit && fmax(DrawDeals.SizeCounter(), DrawPositions.SizeCounter()) < AccountInfoInteger(ACCOUNT_LIMIT_ORDERS)) {
                if(state_deals)
                    DrawDeals.Push(price, volume);
                if(state_positions)
                    DrawPositions.Push(total_notional / total_volume, total_volume);

                price     = fmax(0, MinMax.process(price * price_ratio, price + Direction * Point()));
                notional *= NotionalRatio.getValue();

                volume          = fmax(floor(notional / price / Volumes.VolumeStep) * Volumes.VolumeStep, Volumes.VolumeStep);
                total_volume   += volume;
                total_notional += volume * price;
                Margin         += Converter.QuoteToDeposit(total_notional * Contract / Leverage, Quote);
            }
        }
        DrawDeals.Drop(uint(RestrictedDeals.getValue()));
        DrawPositions.Drop(uint(RestrictedDeals.getValue()));

        if(state_deals)
            DrawDeals.DrawLines();
        if(state_positions)
            DrawPositions.DrawLines();
    }

  private:
    void TradeLine(uint const counter) const {
        double rest_volume{DrawDeals.Levels[counter].volume}, curr_volume{rest_volume};
        for(uint i{0}, num_iter{uint(floor(DrawDeals.Levels[counter].volume / Volumes.VolumeMax))}; i <= num_iter; ++i) {
            curr_volume  = Volumes.VolumeMax <= rest_volume ? Volumes.VolumeMax : rest_volume;
            rest_volume -= curr_volume;

            MqlTradeRequest const Request{TRADE_ACTION_PENDING, Magic.Number, 0, Symbol(), curr_volume, DrawDeals.Levels[counter].price, 0, 0, 0, 0, Type, ORDER_FILLING_FOK, 0, 0, DrawDeals.Name(counter), 0, 0};
            Send(Request);
        }
    }

    void Send(MqlTradeRequest const &request) const {
        MqlTradeCheckResult Check{NULL};
        MqlTradeResult      Result{NULL};
        if(OrderCheck(request, Check)) {
            // PrintFormat("OrderCheck 1: retcode %u balance %g equity %g profit %g margin %g margin_free %g margin_level %g comment %s", Check.retcode, Check.balance, Check.equity, Check.profit, Check.margin, Check.margin_free, Check.margin_level, Check.comment);
            if(OrderSendAsync(request, Result)) {
                // PrintFormat("OrderSend 1: retcode %u deal %llu order %llu volume %g price %g bid %g ask %g comment %s request_id %u retcode_external %u", Result.retcode, Result.deal, Result.order, Result.volume, Result.price, Result.bid, Result.ask, Result.comment, Result.request_id, Result.retcode_external);
            } else {
                PrintFormat("OrderSend 2: retcode %u | deal %llu | order %llu | volume %g | price %g | bid %g | ask %g | comment %s | request_id %u | retcode_external %u", Result.retcode, Result.deal, Result.order, Result.volume, Result.price, Result.bid, Result.ask, Result.comment, Result.request_id, Result.retcode_external);
            }
        } else {
            PrintFormat("OrderCheck 2: retcode %u | balance %g | equity %g | profit %g | margin %g | margin_free %g | margin_level %g | comment %s", Check.retcode, Check.balance, Check.equity, Check.profit, Check.margin, Check.margin_free, Check.margin_level, Check.comment);
        }
    }

    bool orderExists() const {
        for(int i{OrdersTotal() - 1}; i >= 0; i--) {
            OrderGetTicket(i);
            if(Magic.Number == OrderGetInteger(ORDER_MAGIC) && Type == OrderGetInteger(ORDER_TYPE)) {
                return true;
            }
        }

        return false;
    }
    /*double ExtremumExtremum(double const val) {
      if (SmartPosition.getStatus()) {
        return Extremum.process(Extremum.process(SmartPosition.getPrice(), SymbolInfoDouble(Symbol(), QuoteIn)), val);
      } else {
        return Extremum.process(SymbolInfoDouble(Symbol(), QuoteIn), val);
      }
    }*/

    /*double clampPrice(double const val) const {
      return fmax(0, val);
    }*/

    /*double clampPriceRatio(double const val) const {
      return fmax(PriceRatioLimitLow, fmin(PriceRatioLimitHigh, val));
    }*/

    /*double clampVolumeInit(double const val) const {
      return fmax(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN), val);
    }*/

    /*double clampNotionalRatio(double const val) const {
      return fmax(1, val);
    }*/

    /*void DrawLine(string const type, uint const counter, double const price, string const tooltip, double const value, color const colour) const {
       string const deal_name{StringFormat("%s%s %u", Name, type, counter)};
       ObjectCreate    (ChartID(), deal_name, OBJ_HLINE, 0, 0, price);
       ObjectSetString (ChartID(), deal_name, OBJPROP_TEXT, StringFormat("%.*f", DigitS, value));
       ObjectSetString (ChartID(), deal_name, OBJPROP_TOOLTIP, StringFormat("%s %s %.*f", deal_name, tooltip, DigitS, value));
       ObjectSetInteger(ChartID(), deal_name, OBJPROP_ZORDER, 0);
       ObjectSetInteger(ChartID(), deal_name, OBJPROP_BACK, true);
       ObjectSetInteger(ChartID(), deal_name, OBJPROP_COLOR, colour);
       ObjectSetInteger(ChartID(), deal_name, OBJPROP_STYLE, STYLE_DOT);
    }

    bool DeleteLine(string const type, uint const counter) const {
      bool const found{ObjectFind(ChartID(), StringFormat("%s%s %u", Name, type, counter)) >= 0};
      if (found) {
        ObjectDelete(ChartID(), StringFormat("%s%s %u", Name, type, counter));
      }
      return found;
    }*/
};

class CObjectLong final : public CObject<ExtremumMin> {
  public:
    CObjectLong() : CObject(POSITION_TYPE_BUY, PriceRatioLong, NotionalRatioLong) {}
};

class CObjectShort final : public CObject<ExtremumMax> {
  public:
    CObjectShort() : CObject(POSITION_TYPE_SELL, PriceRatioShort, NotionalRatioShort) {}
};

class CObjectManager final {
    double   X_proportions, Y_proportions;
    IObject *Observers[2], *LongObserver, *ShortObserver;

  public:
    CObjectManager()
        : X_proportions(Xproportions), Y_proportions(Yproportions) {
        LongObserver = Observers[0] = new CObjectLong;
        ShortObserver = Observers[1] = new CObjectShort;
    }

    ~CObjectManager() {
        for(uint i{0}; i < Observers.Size(); ++i)
            delete Observers[i];
    }

    void Draw() {
        switch(PositionReporter.getPositionType()) {
            case CPositionReporter::EnumPositionType::LONG:
                // printFormat("%s %s", __FUNCTION__, EnumToString(CPositionReporter::EnumPositionType::LONG));
                LongObserver.Draw();
                LongObserver.CalcLevels();
                ShortObserver.Hide();
                break;
            case CPositionReporter::EnumPositionType::SHORT:
                ShortObserver.Draw();
                ShortObserver.CalcLevels();
                LongObserver.Hide();
                break;
            default:
                for(uint i{0}; i < Observers.Size(); ++i) {
                    Observers[i].Draw();
                    Observers[i].CalcLevels();
                }
        }
    }

    void UpdatePrice() const {
        for(uint i{0}; i < Observers.Size(); ++i) {
            Observers[i].UpdatePrice();
            Observers[i].CalcLevels();
        }
    }

    void EventEdit(string const &sparam) const {
        for(uint i{0}; i < Observers.Size(); ++i) {
            if(Observers[i].EventEdit(sparam)) {
                Observers[i].CalcLevels();
                return;
            }
        }
    }

    void EventButton(string const &sparam) {
        for(uint i{0}; i < Observers.Size(); ++i) {
            if(Observers[i].EventButton(sparam)) {
                Observers[i].CalcLevels();
                return;
            }
        }
        ListPeriods.ChangePeriod(sparam);
    }
} ObjectManager;

int OnInit() {

    /*Base * base = new Derived;
    Base * base1 = base;
    base1.function();
    delete base1;*/
    // IndicatorSetString(INDICATOR_SHORTNAME,"yo");

    /*double price = 1.2000;
    int shift = 0;
    int subWindow = 1;

    // Create a horizontal line in subwindow 1
    Print(ChartWindowFind());
    ObjectCreate(ChartID(), "MyLine", OBJ_HLINE, subWindow, shift, price);
    ObjectSetInteger(ChartID(), "MyLine", OBJPROP_COLOR, Red);
    ObjectSetInteger(ChartID(), "MyLine", OBJPROP_STYLE, STYLE_DASHDOTDOT);*/

    // int RSIperiod=14;
    // int handle=iRSI(Symbol(),PERIOD_CURRENT,RSIperiod,PRICE_CLOSE);Period())

    // Print(ChartID(), " ", (int)ChartGetInteger(0,CHART_WINDOWS_TOTAL,0));
    // Print(__FUNCTION__, " Exp ", ChartGetInteger(ChartID(), CHART_WINDOWS_TOTAL, 0));
    // Print(ChartGetInteger(ChartID(), CHART_WINDOWS_TOTAL, 0));

    // Print("yo ", ChartIndicatorsTotal(ChartID(), int(ChartGetInteger(ChartID(), CHART_WINDOWS_TOTAL, 0)) - 1));

    // Print("yo ", ChartIndicatorGet(ChartID(), int(ChartGetInteger(ChartID(), CHART_WINDOWS_TOTAL, 0)) - 1, ChartIndicatorName(ChartID(), int(ChartGetInteger(ChartID(), CHART_WINDOWS_TOTAL, 0) - 1), 0)));

    /*for (uint i{0}; i < 3; ++i)
      for (uint j{0}; j < 3; ++j)
        Print(i, " ", j, " ", ChartIndicatorName(ChartID(), i, j));*/
    // Print("yo ", int(ChartGetInteger(ChartID(), CHART_WINDOWS_TOTAL, 0)));
    // Print(ChartIndicatorName(ChartID(), int(ChartGetInteger(ChartID(), CHART_WINDOWS_TOTAL, 0) - 1), 0));

    // ChartIndicatorGet(ChartID(), int(ChartGetInteger(ChartID(), CHART_WINDOWS_TOTAL, 0)) - 1, ChartIndicatorName(ChartID(), int(ChartGetInteger(ChartID(), CHART_WINDOWS_TOTAL, 0) - 1), 0))
    // Print(int(ChartGetInteger(ChartID(), CHART_WINDOWS_TOTAL) - 1), " ", int(ChartGetInteger(ChartID(), CHART_WINDOWS_TOTAL) - 1), " ", int(ChartGetInteger(ChartID(), CHART_WINDOWS_TOTAL) - 1));
    /*if (int(ChartGetInteger(ChartID(), CHART_WINDOWS_TOTAL) - 1) == 0) {
        ChartIndicatorAdd(ChartID(), 1, iCustom(Symbol(), Period(), "SubWindow"));
    }*/

    // PositionReporter.DrawAll();
    // if (!(ChartGetInteger(ChartID(), CHART_WINDOWS_TOTAL, 0) - 1)) {
    //   ChartIndicatorAdd(ChartID(), int(ChartGetInteger(ChartID(), CHART_WINDOWS_TOTAL, 0)), handle);
    // }

    // ObjectManager.UpdateProportions();
    // PrintFormat("%s", __FUNCTION__);
    // ListPeriods.UpdateButton();
    // ProportionsManager.UpdateProportions();

    string str     = "";
    bool   success = INIT_SUCCEEDED;
    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
        str     += EnumToString(TERMINAL_TRADE_ALLOWED) + " ";
        success  = INIT_FAILED;
    }

    if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)) {
        str     += EnumToString(ACCOUNT_TRADE_ALLOWED) + " ";
        success  = INIT_FAILED;
    }

    if(AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_NETTING) {
        str     += EnumToString(ENUM_ACCOUNT_MARGIN_MODE(AccountInfoInteger(ACCOUNT_MARGIN_MODE)));
        success  = INIT_FAILED;
    }

    if(success == INIT_FAILED) {
        // ExpertRemove();
        PrintFormat("%s %s", __FUNCTION__, str);
    }

    return success;
}

void OnDeinit(const int reason) {
    /*ObjectsDeleteAll(ChartID(), 0, OBJ_BUTTON);
    ObjectsDeleteAll(ChartID(), 0, OBJ_EDIT);*/

    // ObjectsDeleteAll(ChartID(), 0, OBJ_HLINE);

    /*if (reason == REASON_REMOVE || reason == REASON_PROGRAM) {
      ChartIndicatorDelete(ChartID(), 1, ChartIndicatorName(ChartID(), 1, 0));
    }*/
}

void OnTick() {
    /*ObjectLong.Update();
    ObjectShort.Update();
    ChartRedraw();*/
    // PositionReporter.SetValue();
    ObjectManager.UpdatePrice();
}

void OnTrade() {
    /*PositionLong.setStatus();
    PositionLong.setPrice();
    PositionShort.setStatus();
    PositionShort.setPrice();*/
    // PositionLong.update();
    // PositionShort.update();
    // PositionReporter.UpdatePosition();
    // if (Symbol() )
    // PositionReporter.UpdatePrice();
    // PositionReporter.Draw();
    // PrintFormat("%s", __FUNCTION__);

    // PrintFormat("%s", __FUNCTION__);
    // PrintFormat("%s %s", __FUNCTION__, EnumToString(PositionReporter.getPositionType()));

    // Draw();
    // SetText();
    // Refresh();
    // PositionReporter.Refresh();
    // PositionReporter.SetGeometry(0.025, 0.05);
}

void OnTradeTransaction(MqlTradeTransaction const &transaction, MqlTradeRequest const &request, MqlTradeResult const &result) {
    /*PrintFormat("%s Request: action %s magic %llu order %llu symbol %s volume %g price %g stoplimit %g sl %g tp %g devation %llu type %s type_filling %s type_time %s expiration %s comment %s position %llu position_by %llu",
      __FUNCTION__,
      EnumToString(request.action),
      request.magic,
      request.order,
      request.symbol,
      request.volume,
      request.price,
      request.stoplimit,
      request.sl,
      request.tp,
      request.deviation,
      EnumToString(request.type),
      EnumToString(request.type_filling),
      EnumToString(request.type_time),
      TimeToString(request.type_time, TIME_DATE|TIME_MINUTES|TIME_SECONDS),
      request.comment,
      request.position,
      request.position_by);

    PrintFormat("%s Result: retcode %u deal %llu order %llu volume %g price %g bid %g ask %g comment %s request_id %u retcode_external %u",
      __FUNCTION__,
      result.retcode,
      result.deal,
      result.order,
      result.volume,
      result.price,
      result.bid,
      result.ask,
      result.comment,
      result.request_id,
      result.retcode_external);

    PrintFormat("%s Transaction: deal %llu order %llu symbol %s type %s order_type %s order_state %s deal_type %s time_type %s time_expiration %s price %g price_trigger %g price_sl %g price_tp %g volume %g position %llu position_by %llu",
      __FUNCTION__,
      transaction.deal,
      transaction.order,
      transaction.symbol,
      EnumToString(transaction.type),
      EnumToString(transaction.order_type),
      EnumToString(transaction.order_state),
      EnumToString(transaction.deal_type),
      EnumToString(transaction.time_type),
      TimeToString(transaction.time_expiration, TIME_DATE|TIME_MINUTES|TIME_SECONDS),
      transaction.price,
      transaction.price_trigger,
      transaction.price_sl,
      transaction.price_tp,
      transaction.volume,
      transaction.position,
      transaction.position_by);*/

    /*PrintFormat("%s Request: action %s type %s type_filling %s type_time %s",
      __FUNCTION__,
      EnumToString(request.action),
      EnumToString(request.type),
      EnumToString(request.type_filling),
      EnumToString(request.type_time));

    PrintFormat("%s Transaction: type %s order_type %s order_state %s deal_type %s",
      __FUNCTION__,
      EnumToString(transaction.type),
      EnumToString(transaction.order_type),
      EnumToString(transaction.order_state),
      EnumToString(transaction.deal_type));*/

    // PrintFormat("%s %s", __FUNCTION__, EnumToString(transaction.type));
    if(transaction.type == TRADE_TRANSACTION_HISTORY_ADD) {
        // TransactionInProgress=false;
        // ObjectsDeleteAll(ChartID(), 0, OBJ_HLINE);
        // PrintFormat("%s %s %s", __FUNCTION__, transaction.symbol, request.symbol);
        // PositionReporter.UpdatePrice();
        // PositionReporter.Draw();
        // PrintFormat("%s in %s %s", __FUNCTION__, transaction.symbol, request.symbol);
    } else if(transaction.type == TRADE_TRANSACTION_REQUEST) {
        // ObjectManager.UpdatePrice();
        // ObjectManager.Draw();
        // ObjectManager.SetGeometry();
        // ChartRedraw();
    }
    // PrintFormat("%s %s '%s' %s", __FUNCTION__, EnumToString(transaction.type), transaction.symbol, EnumToString(request.type));
    // PrintFormat("%s %s %s", __FUNCTION__, EnumToString(transaction.type), EnumToString(PositionReporter.getPositionType()));
}

/*double DealMax() {
  double max{-DBL_MAX};
  for(uint i{HistoryDealsTotal()-1}; i!=UINT_MAX; --i) {
    ulong const ticket{HistoryDealGetTicket(i)};
    if(HistoryDealGetInteger(ticket, DEAL_TYPE) == DEAL_TYPE_SELL) {
      //Print(i," ", HistoryDealGetDouble(ticket, DEAL_PRICE), " ", HistoryDealGetInteger(ticket, DEAL_TICKET), " ", HistoryDealGetInteger(ticket, DEAL_ORDER), " ", TimeToString(HistoryDealGetInteger(ticket, DEAL_TIME), TIME_DATE|TIME_MINUTES|TIME_SECONDS), " ", EnumToString(ENUM_DEAL_TYPE(HistoryDealGetInteger(ticket, DEAL_TYPE))));
      max = fmax(max, HistoryDealGetDouble(ticket, DEAL_PRICE));
    }
  }
  return max;
}

double DealMin() {
  double min{DBL_MAX};
  for(uint i{HistoryDealsTotal()-1}; i!=UINT_MAX; --i) {
    ulong const ticket{HistoryDealGetTicket(i)};
    if(HistoryDealGetInteger(ticket, DEAL_TYPE) == DEAL_TYPE_BUY) {
      //Print(i," ", HistoryDealGetDouble(ticket, DEAL_PRICE), " ", HistoryDealGetInteger(ticket, DEAL_TICKET), " ", HistoryDealGetInteger(ticket, DEAL_ORDER), " ", TimeToString(HistoryDealGetInteger(ticket, DEAL_TIME), TIME_DATE|TIME_MINUTES|TIME_SECONDS), " ", EnumToString(ENUM_DEAL_TYPE(HistoryDealGetInteger(ticket, DEAL_TYPE))));
      min = fmin(min, HistoryDealGetDouble(ticket, DEAL_PRICE));
    }
  }
  return min;
}*/

/*void ChangePeriod(string const& sparam) {
  if (sparam == EnumToString(ChartPeriod(ChartID()))) {
    ObjectSetInteger(ChartID(), sparam, OBJPROP_STATE, true);
  } else {
    for(uint i{0}; i < Periods.Size(); ++i) {
      if(sparam == EnumToString(Periods[i])) {
        ChartSetSymbolPeriod(ChartID(), Symbol(), Periods[i]);
        break;
      }
    }
  }
}*/

void OnChartEvent(int const id, long const &lparam, double const &dparam, string const &sparam) {
    // PrintFormat("%s %s l %ld d %f s %s", __FUNCTION__, EnumToString(ENUM_CHART_EVENT(id)), lparam, dparam, sparam);
    // if (ProportionsManager.GeometryChanged()) {

    // PrintFormat("%s ", __FUNCTION__);
    //  ObjectManager.SetGeometry();
    //   ChartRedraw();
    if(id == CHARTEVENT_CLICK) {
        // PrintFormat("%s", __FUNCTION__);
    } else if(id == CHARTEVENT_MOUSE_MOVE) {
    } else if(id == CHARTEVENT_CUSTOM) {
    } else if(id == CHARTEVENT_OBJECT_ENDEDIT) {
        // ObjectLong.EventEdit(sparam);
        // ObjectShort.EventEdit(sparam);
        ObjectManager.EventEdit(sparam);
        // PositionReporter.CalcLevels();
        ChartRedraw();
        // ObjectLong.CalcLevels();
        // ObjectShort.CalcLevels();
    } else if(id == CHARTEVENT_OBJECT_CLICK) {
        // ObjectLong.EventButtonClick(sparam);
        // ObjectShort.EventButtonClick(sparam);
        // ObjectLong.CalcLevels();
        // ObjectShort.CalcLevels();
        // ObjectLong.EventTradeClick(sparam);
        // ObjectShort.EventTradeClick(sparam);
        // PrintFormat("%s %s", __FUNCTION__,sparam);
        // PrintFormat("%s", __FUNCTION__);
        ObjectManager.EventButton(sparam);
        // PositionReporter.CalcLevels();
        // ListPeriods.ChangePeriod(sparam);
        ChartRedraw();
    } else if(id == CHARTEVENT_CHART_CHANGE) {
        ;
        ProportionsManager.UpdateProportions();
        ObjectManager.Draw();
        ListPeriods.UpdateButton();
        ListPeriods.Draw();
        ChartRedraw();
    }
    // PrintFormat("1 %s | %s | %u | %u | %s", __FUNCTION__, EnumToString(ENUM_CHART_EVENT(id)), lparam, dparam, sparam);
}

typedef string (*PrtStringSpread)();
string StringFloatSpread() { return StringFormat("%.*f", Digits(), SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) * Point()); }
string StringIntegerSpread() { return StringFormat("%u", SymbolInfoInteger(Symbol(), SYMBOL_SPREAD)); }

class CSpread final {
  public:
    PrtStringSpread String;
    CSpread()
    /*: String(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD_FLOAT)?StringFloatSpread:StringIntegerSpread)*/ {
        if(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD_FLOAT))
            String = StringFloatSpread;
        else
            String = StringIntegerSpread;
    }
};

class CAdministrative final {
  private:
    uint const last;

  public:
    double Fee, RangeDiff[], Leverage[];
    CAdministrative()
        : last(ArrayResize(Leverage, ArrayResize(RangeDiff, 3) + 1)) {
        // PrintFormat("%s %s %s", SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE), SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT), SymbolInfoString(Symbol(), SYMBOL_CURRENCY_MARGIN));
        // PrintFormat("%s: %s WTF", __FUNCTION__, EnumToString(ENUM_SYMBOL_SECTOR(SymbolInfoInteger(Symbol(), SYMBOL_SECTOR))));

        if(SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE) == "BTC") {
            Fee          = 0.000035;
            RangeDiff[0] = 500000;
            RangeDiff[1] = 5000000 - 500000;
            RangeDiff[2] = 10000000 - 5000000;
            Leverage[0]  = 1000;
            Leverage[1]  = 500;
            Leverage[2]  = 100;
            Leverage[3]  = 50;
        } else if(SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE) == "BTC") {
            Fee          = 0.000750;
            RangeDiff[0] = 50000;
            RangeDiff[1] = 500000 - 50000;
            RangeDiff[2] = 1000000 - 500000;
            Leverage[0]  = 100;
            Leverage[1]  = 50;
            Leverage[2]  = 25;
            Leverage[3]  = 10;
        } else if(SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE) == "DOG") {
            Fee          = 0.000750;
            RangeDiff[0] = 5000;
            RangeDiff[1] = 50000 - 5000;
            RangeDiff[2] = 100000 - 50000;
            Leverage[0]  = 100;
            Leverage[1]  = 50;
            Leverage[2]  = 25;
            Leverage[3]  = 10;
        }

        /*switch(ENUM_SYMBOL_SECTOR(SymbolInfoInteger(Symbol(), SYMBOL_SECTOR))) {
          case SECTOR_CURRENCY:
            Fee=0.0000315;
            RangeDiff[0]=500000;
            RangeDiff[1]=5000000-500000;
            RangeDiff[2]=10000000-5000000;
            Leverage[0]=1000;
            Leverage[1]=500;
            Leverage[2]=100;
            Leverage[3]=50;
            break;
          case SECTOR_CURRENCY_CRYPTO:
            Fee=0.000750;
            if(SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE)=="BTC") {
              RangeDiff[0]=50000;
              RangeDiff[1]=500000-50000;
              RangeDiff[2]=1000000-500000;
            } else {
              RangeDiff[0]=5000;
              RangeDiff[1]=50000-5000;
              RangeDiff[2]=100000-50000;
            }
            Leverage[0]=100;
            Leverage[1]=50;
            Leverage[2]=25;
            Leverage[3]=10;
            break;
          case SECTOR_UNDEFINED:
            Fee=0.000750;
            if(SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE)=="BTC") {
              RangeDiff[0]=50000;
              RangeDiff[1]=500000-50000;
              RangeDiff[2]=1000000-500000;
            } else {
              RangeDiff[0]=5000;
              RangeDiff[1]=50000-5000;
              RangeDiff[2]=100000-50000;
            }
            Leverage[0]=100;
            Leverage[1]=50;
            Leverage[2]=25;
            Leverage[3]=10;
            break;
          default: PrintFormat("%s: %s WTF", __FUNCTION__, EnumToString(ENUM_SYMBOL_SECTOR(SymbolInfoInteger(Symbol(), SYMBOL_SECTOR))));
        }*/
    }

    double Margin(double const residual, uint const curr) const {
        if(curr + 1 < last)
            if(residual < RangeDiff[curr])
                return residual / Leverage[curr];
            else
                return fmin(residual, RangeDiff[curr]) / Leverage[curr] + Margin(residual - RangeDiff[curr], curr + 1);
        else
            return residual / Leverage[curr];
    }
} const Administrative;

/*uint CalcLevels(double const balance_old, double const position_volume_old, double const position_price_old, double const deal_volume_old, double const deal_price_old, uint const start, uint const curr) {
  double const deal_price_new{deal_price_old*Settings.PriceRatio},
         const notional_add{Settings.NotionalRatio*deal_volume_old*deal_price_old},
         const notional_new{position_volume_old*position_price_old+notional_add},
         const deal_volume_new{notional_add/deal_price_new},
         const position_volume_new{position_volume_old+deal_volume_new},
         const position_price_new{notional_new/position_volume_new},
         const balance_new{balance_old-Contract*Converter.QuoteToDeposit(Settings.Direction*position_volume_old*(position_price_old-deal_price_new)+deal_volume_new*SymbolInfoInteger(Symbol(), SYMBOL_SPREAD)*Point()+Administrative.Fee*notional_add, Settings.QuoteIn)},
         const margin{AccountInfoDouble(ACCOUNT_MARGIN)+Converter.ArbiterToDeposit(Administrative.Margin(Converter.QuoteToArbiter(Contract*notional_new, Settings.QuoteIn), 0), Settings.QuoteIn)};

  if(balance_new>margin*MarginCall) {
    if(LevelsState) {
      uint const index{start+curr};
      string const deal_name  {StringFormat("Fill[%u]"      , index)},
             const open_name  {StringFormat("BreakEven[%u]" , index)},
             const margin_name{StringFormat("MarginCall[%u]", index)},
             const info       {StringFormat("%g|%g|%g%%", balance_new, margin,100*balance_new/margin)};

      ObjectCreate    (ChartID(), deal_name  , OBJ_HLINE, 0, 0, deal_price_new);
      ObjectSetInteger(ChartID(), deal_name  , OBJPROP_COLOR, Orange);
      ObjectSetInteger(ChartID(), deal_name  , OBJPROP_STYLE, STYLE_DOT);
      ObjectSetString (ChartID(), deal_name  , OBJPROP_TOOLTIP, StringFormat("%s||addNotional %g --> addVolume %g||%s",deal_name, Contract*notional_add, deal_volume_new, info));

      ObjectCreate    (ChartID(), open_name  , OBJ_HLINE, 0, 0, position_price_new);
      ObjectSetInteger(ChartID(), open_name  , OBJPROP_COLOR, Purple);
      ObjectSetInteger(ChartID(), open_name  , OBJPROP_STYLE, STYLE_DOT);
      ObjectSetString (ChartID(), open_name  , OBJPROP_TOOLTIP, StringFormat("%s||newNotional %g --> newVolume %g||%s", open_name, Contract*notional_new, position_volume_new, info));

      ObjectCreate    (ChartID(), margin_name, OBJ_HLINE,0,0,position_price_new-Settings.Direction*Converter.DepositToQuote(balance_new-margin*MarginCall, Settings.QuoteOut)/(Contract*position_volume_new));
      ObjectSetInteger(ChartID(), margin_name, OBJPROP_COLOR, Red);
      ObjectSetInteger(ChartID(), margin_name, OBJPROP_STYLE,STYLE_DOT);
      ObjectSetString (ChartID(), margin_name, OBJPROP_TOOLTIP, margin_name);
    }

    return CalcLevels(balance_new, position_volume_new, position_price_new, deal_volume_new, deal_price_new, start, curr+1);
  } else {
    if(LevelsState) {
      ObjectCreate    (ChartID(), "MarginCall", OBJ_HLINE, 0, 0, PositionGetDouble(POSITION_PRICE_CURRENT)-Settings.Direction*Converter.DepositToQuote(fmin(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE)) - AccountInfoDouble(ACCOUNT_MARGIN)*MarginCall, Settings.QuoteOut)/(Contract*PositionGetDouble(POSITION_VOLUME)));
      ObjectSetInteger(ChartID(), "MarginCall", OBJPROP_COLOR, Red);
      ObjectSetInteger(ChartID(), "MarginCall", OBJPROP_STYLE, STYLE_SOLID);
    }

    return curr;
  }
}*/