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
    // int m_history_orders_total;
    bool m_old_status;
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
          m_old_status(PositionReporter.getStatus()),
          PeriodCollection(new CPeriodCollection(ProportionsManager)),
          LongBuilder(new CTradeBuilder<ExtremumMin>(ProportionsManager, PositionReporter, POSITION_TYPE_BUY)),
          ShortBuilder(new CTradeBuilder<ExtremumMax>(ProportionsManager, PositionReporter, POSITION_TYPE_SELL)) {
        // PositionSelect(Symbol());
        // HistorySelectByPosition(PositionGetInteger(POSITION_TICKET));
        // m_history_orders_total = HistoryOrdersTotal();

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

    // void onTrade() {
    //     PositionReporter.getStatus();
    //     PositionReporter.getPositionType();
    //     // if (isNewPosition()) {
    //     //     for (uint i{0}; i < TradeBuilders.Size(); ++i) {
    //     //         TradeBuilders[i].onTrade();
    //     //     }
    //     // }
    // }

    void onTrade() {
        // PositionReporter.getStatus();
        // PositionReporter.getPositionType();
        // if (PositionReporter.getStatus()) {
        //     if (m_history_orders_total != HistoryOrdersTotal()) {
        //         if (m_history_orders_total) {
        //             // continueing position
        //             // PrintFormat("continue position %d", PositionGetInteger(POSITION_TICKET));
        //             // TradeBuilders[].onPositionChange();
        //             if (HistoryOrdersTotal()) {
        //                 PrintFormat("continue position %d", PositionGetInteger(POSITION_TICKET));
        //             } else {
        //                 PrintFormat("close position %d", PositionGetInteger(POSITION_TICKET));
        //             }

        //         } else {
        //             // open position
        //             PrintFormat("open position %d", PositionGetInteger(POSITION_TICKET));
        //             // TradeBuilders[PositionGetInteger(POSITION_TICKET)].onPositionOpen();
        //         }
        //         m_history_orders_total = HistoryOrdersTotal();
        //     }
        //     // for (uint i{0}; i < TradeBuilders.Size(); ++i) {
        //     //     TradeBuilders[i].onTrade();
        //     // }
        // } else {
        //     PrintFormat("close position");
        // }
        bool const new_status{PositionReporter.getStatus()};
        if (!m_old_status && new_status) {
            PrintFormat("%s open position, %s %s", __FUNCTION__, string(m_old_status), string(new_status));
        } else if (m_old_status && new_status) {
            PrintFormat("%s continue position, %s %s", __FUNCTION__, string(m_old_status), string(new_status));
        } else if (m_old_status && !new_status) {
            PrintFormat("%s close position, %s %s", __FUNCTION__, string(m_old_status), string(new_status));
        }

        m_old_status = new_status;
    }

   private:
    // bool isNewPosition() {
    //     // if (PositionSelect(Symbol()) && HistorySelectByPosition(PositionGetInteger(POSITION_TICKET)) && m_history_orders_total != HistoryOrdersTotal()) {
    //     if (PositionReporter.getStatus() && m_history_orders_total != HistoryOrdersTotal()) {
    //         m_history_orders_total = HistoryOrdersTotal();
    //         // PrintFormat("%s %d %d", __FUNCTION__, m_history_orders_total, OrdersTotal());
    //         return true;
    //     }

    //     return false;
    // }
};