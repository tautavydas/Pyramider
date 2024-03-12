// ###<Experts/Pyramider.mq5>

#include <Pyramider/Collections/PeriodCollection.mqh>
#include <Pyramider/Entities/PositionReporter.mqh>
#include <Pyramider/Entities/ProportionsManager.mqh>
#include <Pyramider/Entities/TradeBuilder.mqh>

class ExtremumMin final {
   public:
    double process(double const val1, double const val2) const { return fmin(val1, val2); }
};

class ExtremumMax final {
   public:
    double process(double const val1, double const val2) const { return fmax(val1, val2); }
};

class CBuilderManager final {
    double m_Xproportions, m_Yproportions;
    int m_position_total;
    CProportionsManager ProportionsManager;
    CPositionReporter PositionReporter;
    CPeriodCollection *PeriodCollection;
    ITradeBuilder *TradeBuilders[2];
    CTradeBuilder<ExtremumMin> *LongBuilder;
    CTradeBuilder<ExtremumMax> *ShortBuilder;

   public:
    CBuilderManager()
        : m_Xproportions(Xproportions),
          m_Yproportions(Yproportions),
          m_position_total(PositionsTotal()),
          PeriodCollection(new CPeriodCollection(ProportionsManager)),
          LongBuilder(new CTradeBuilder<ExtremumMin>(ProportionsManager, PositionReporter, POSITION_TYPE_BUY)),
          ShortBuilder(new CTradeBuilder<ExtremumMax>(ProportionsManager, PositionReporter, POSITION_TYPE_SELL)) {
        TradeBuilders[0] = LongBuilder;
        TradeBuilders[1] = ShortBuilder;
    }

    ~CBuilderManager() {
        for (uint i{0}; i < TradeBuilders.Size(); ++i)
            delete TradeBuilders[i];
        delete PeriodCollection;
    }

    void Draw() {
        ProportionsManager.UpdateProportions(PeriodCollection.Size());
        switch (PositionReporter.getPositionType()) {
            case CPositionReporter::EnumPositionType::LONG:
                LongBuilder.Draw();
                LongBuilder.CalcLevels();
                ShortBuilder.Hide();
                break;
            case CPositionReporter::EnumPositionType::SHORT:
                ShortBuilder.Draw();
                ShortBuilder.CalcLevels();
                LongBuilder.Hide();
                break;
            default:
                for (uint i{0}; i < TradeBuilders.Size(); ++i) {
                    TradeBuilders[i].Draw();
                    TradeBuilders[i].CalcLevels();
                }
        }
        PeriodCollection.UpdateButton();
        PeriodCollection.Draw();
    }

    void onTick() const {
        for (uint i{0}; i < TradeBuilders.Size(); ++i) {
            TradeBuilders[i].onTick();
            TradeBuilders[i].CalcLevels();
        }
    }

    void onEdit(string const &sparam) const {
        for (uint i{0}; i < TradeBuilders.Size(); ++i) {
            if (TradeBuilders[i].onEdit(sparam)) {
                TradeBuilders[i].CalcLevels();
                return;
            }
        }
    }

    void onButton(string const &sparam) {
        for (uint i{0}; i < TradeBuilders.Size(); ++i) {
            if (TradeBuilders[i].onButton(sparam)) {
                TradeBuilders[i].CalcLevels();
                return;
            }
        }
        PeriodCollection.ChangePeriod(sparam);
    }

    bool isNewPosition() {
        if (m_position_total != PositionsTotal()) {
            m_position_total = PositionsTotal();

            return true;
        }

        return false;
    }

    // void onTrade() {
    //     for (uint i{0}; i < TradeBuilders.Size(); ++i) {
    //         TradeBuilders[i].onTrade();
    //     }
    // }
};