// ###<Experts/Pyramider.mq5>

#include <Generic/HashMap.mqh>
#include <Pyramider/Entities/ProportionsManager.mqh>
#include <Pyramider/Objects/PeriodButton.mqh>

class CPeriodCollection final {
   public:
    class CPair final {
       public:
        ENUM_TIMEFRAMES const Timeframe;
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
    CPeriodCollection(CProportionsManager const &proportions_manager)
        : Map(new CHashMap<string, CPair *>) {
        ENUM_TIMEFRAMES const periods[]{PERIOD_M1, PERIOD_M2, PERIOD_M3, PERIOD_M4, PERIOD_M5, PERIOD_M6, PERIOD_M10, PERIOD_M12, PERIOD_M15, PERIOD_M20, PERIOD_M30, PERIOD_H1, PERIOD_H2, PERIOD_H3, PERIOD_H4, PERIOD_H6, PERIOD_H8, PERIOD_H12, PERIOD_D1, PERIOD_W1, PERIOD_MN1};

        ArrayResize(Buttons, ArrayCopy(Periods, periods));
        for (uint i{0}; i < Buttons.Size(); ++i) {
            Buttons[i] = new PeriodButton(proportions_manager, Periods, i);
            Map.Add(Buttons[i].name, new CPair(Periods[i], Buttons[i]));
        }

        Draw();
    }

    ~CPeriodCollection() {
        CKeyValuePair<string, CPair *> *Pairs[];
        Map.CopyTo(Pairs);
        for (uint i{0}; i < Pairs.Size(); ++i) {
            delete Buttons[i];
            delete Pairs[i].Value();
            delete Pairs[i];
        }
        delete Map;
    }

    uint Size() const { return Buttons.Size(); }

    void Draw() {
        for (uint i{0}; i < Buttons.Size(); ++i) {
            Buttons[i].Draw();
            if (Period() == Periods[i]) {
                Button = Buttons[i];
                Button.Set();
            }
        }
    }

    void UpdateButton() {
        CPair *Pair;
        if (Map.TryGetValue(EnumToString(ENUM_TIMEFRAMES(Period())), Pair)) {
            Button.Unset();
            Button = Pair.Button;
            Button.Set();
        }
    }

    void ChangePeriod(string const &sparam) {
        CPair *Pair;
        if (Map.TryGetValue(sparam, Pair)) {
            if (Button != Pair.Button) {
                ChartSetSymbolPeriod(ChartID(), Symbol(), Pair.Timeframe);
            }
            Button.Unset();
            Button = Pair.Button;
            Button.Set();
        }
    }
};