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
    // double m_Xproportions, m_Yproportions;
    //  int m_history_orders_total;
    bool m_old_status;
    double m_old_volume;
    uint m_orders_count, m_orders_total;
    CProportionsManager *const ProportionsManager;
    CPeriodCollection *PeriodCollection;
    CPositionReporter PositionReporter;
    ITradeBuilder *TradeBuilders[2];
    CTradeBuilder<ExtremumMin> *LongBuilder;
    CTradeBuilder<ExtremumMax> *ShortBuilder;

   public:
    CBuilderManager(double const x_proportions, double const y_proportions, ENUM_TIMEFRAMES const &periods[])
        :  // m_Xproportions(Xproportions),
           // m_Yproportions(Yproportions),
          m_old_status(PositionReporter.getStatus()),
          m_old_volume(PositionReporter.getVolume()),

          ProportionsManager(new CProportionsManager(periods.Size(), x_proportions, y_proportions)),
          PeriodCollection(new CPeriodCollection(ProportionsManager, periods)),
          LongBuilder(new CTradeBuilder<ExtremumMin>(ProportionsManager, PositionReporter, POSITION_TYPE_BUY)),
          ShortBuilder(new CTradeBuilder<ExtremumMax>(ProportionsManager, PositionReporter, POSITION_TYPE_SELL)),
          m_orders_total(OrdersTotal()) {
        // PositionSelect(Symbol());
        // HistorySelectByPosition(PositionGetInteger(POSITION_TICKET));
        // m_history_orders_total = HistoryOrdersTotal();

        TradeBuilders[0] = LongBuilder;
        TradeBuilders[1] = ShortBuilder;
    }

    ~CBuilderManager() {
        for (uint i{0}; i < TradeBuilders.Size(); ++i)
            delete TradeBuilders[i];
        delete ProportionsManager;
        delete PeriodCollection;
    }

    void UpdatePosition() {
        ProportionsManager.UpdateProportions();
        PeriodCollection.UpdatePosition();
        for (uint i{0}; i < TradeBuilders.Size(); ++i) {
            TradeBuilders[i].UpdatePosition();
        }
        // PeriodCollection.UpdateButton();
        // PeriodCollection.Draw();
    }

    void Draw() {
        PeriodCollection.Draw();
        PeriodCollection.UpdateButton();
        /*switch (PositionReporter.getPositionType()) {
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
        }*/
        CPositionReporter::EnumPositionType const PositionType{PositionReporter.getPositionType()};
        if (PositionType == CPositionReporter::EnumPositionType::NONE) {
            for (uint i{0}; i < TradeBuilders.Size(); ++i) {
                TradeBuilders[i].Draw();
            }
        } else {
            // PrintFormat("%s %d %d %d", __FUNCTION__, PositionType, (PositionType - 1) % 2, PositionType % 2);
            TradeBuilders[PositionType % 2].Draw();
            TradeBuilders[(PositionType - 1) % 2].Hide();
            /*if (OrdersTotal() == Volumes.AccountLimitOrders) {
                TradeBuilders[(PositionType - 1) % 2].Hide();
            } else {
                TradeBuilders[(PositionType - 1) % 2].Draw();
            }*/
        }
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
                m_orders_count = TradeBuilders[i].OrdersCount();
                // PrintFormat("%s index %u order_count %u", __FUNCTION__, i, m_orders_count);
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
        // PositionReporter.getPositionType();
        // bool const new_status{PositionReporter.getStatus()};
        double const new_volume{PositionReporter.getVolume()};
        if (!m_old_volume && new_volume) {
            // PrintFormat("%s open position", __FUNCTION__);
        } else if (m_old_volume == new_volume) {
            // PrintFormat("%s same position", __FUNCTION__);
        } else if (m_old_volume < new_volume) {
            // PrintFormat("%s augment position", __FUNCTION__);
        } else if (m_old_volume > new_volume) {
            // PrintFormat("%s diminish position", __FUNCTION__);
        } else if (m_old_volume && !new_volume) {
            // PrintFormat("%s close position", __FUNCTION__);
            /*for (uint i{0}; i < TradeBuilders.Size(); ++i) {
                TradeBuilders[i].Draw();
            }*/
        }

        // m_old_status = new_status;
        m_old_volume = new_volume;
        // PrintFormat("%s %f %f", __FUNCTION__, m_old_volume, PositionReporter.getVolume());

        /*for (uint i{0}; i < TradeBuilders.Size(); ++i) {
            if (TradeBuilders[i].orderExists()) {
                TradeBuilders[i].DisplayDependingOnOrderStatus();
            }
        }*/
        /*if (PositionReporter.getStatus()) {
            TradeBuilders[PositionReporter.getPositionType()].onTrade();
        } else {
            for (uint i{0}; i < TradeBuilders.Size(); ++i) {
                TradeBuilders[i].onTrade();
            }
        }*/

        // PrintFormat("%s %d", __FUNCTION__, OrdersTotal());
        // if (m_orders_total == OrdersTotal()) {
        // PrintFormat("%s %u %u | %u", __FUNCTION__, TradeBuilders[0].OrdersCount(), TradeBuilders[1].OrdersCount(), OrdersTotal());
        //}
        // PrintFormat("%s %u %u", __FUNCTION__, m_orders_total, OrdersTotal());
        if (m_orders_total != OrdersTotal()) {
            m_orders_total = OrdersTotal();
            CPositionReporter::EnumPositionType const PositionType{PositionReporter.getPositionType()};
            if (PositionType == CPositionReporter::EnumPositionType::NONE) {
                for (uint i{0}; i < TradeBuilders.Size(); ++i) {
                    TradeBuilders[i].Draw();
                }
            } else {
                TradeBuilders[PositionType % 2].Draw();
                TradeBuilders[(PositionType + 1) % 2].Hide();
            }
            ChartRedraw();
        }
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