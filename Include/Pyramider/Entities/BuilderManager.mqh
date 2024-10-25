// ###<Experts/Pyramider.mq5>

#include <Pyramider/Collections/PeriodCollection.mqh>
#include <Pyramider/Entities/Converter.mqh>
#include <Pyramider/Entities/PositionReporter.mqh>
// #include <Pyramider/Entities/ProportionsManager.mqh>
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
    // bool m_old_status;
    double m_volume;
    // bool m_initialized;
    uint /*m_orders_count,*/ m_orders_total;
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
           // m_old_status(PositionReporter.getStatus()),
           // m_volume(PositionGetDouble(POSITION_VOLUME)),
          // m_initialized(false),
          ProportionsManager(new CProportionsManager(periods.Size(), x_proportions, y_proportions)),
          PeriodCollection(new CPeriodCollection(ProportionsManager, periods)),
          LongBuilder(new CTradeBuilder<ExtremumMin>(ProportionsManager, PositionReporter, POSITION_TYPE_BUY)),
          ShortBuilder(new CTradeBuilder<ExtremumMax>(ProportionsManager, PositionReporter, POSITION_TYPE_SELL)),
          m_orders_total(OrdersTotal()) {
        // PositionSelect(Symbol());
        // HistorySelectByPosition(PositionGetInteger(POSITION_TICKET));
        // m_history_orders_total = HistoryOrdersTotal();
        // PrintFormat("%s %s %f", __FUNCTION__, string(m_old_status), m_old_volume);

        PositionReporter.getStatus();
        m_volume = PositionGetDouble(POSITION_VOLUME);

        TradeBuilders[0] = LongBuilder;
        TradeBuilders[1] = ShortBuilder;
    }

    ~CBuilderManager() {
        for (uint i{0}; i < TradeBuilders.Size(); ++i)
            delete TradeBuilders[i];
        delete ProportionsManager;
        delete PeriodCollection;
    }

    // void UpdatePosition() {
    //  PrintFormat("%s %s", __FUNCTION__, string(bool(ProportionsManager.IsProportionsChanged())));
    //  if (ProportionsManager.IsProportionsChanged()) {
    // ProportionsManager.UpdateProportions();
    // PeriodCollection.UpdatePosition();
    // for (uint i{0}; i < TradeBuilders.Size(); ++i) {
    //     TradeBuilders[i].UpdatePosition();
    //}
    // PeriodCollection.UpdateButton();
    // PeriodCollection.Draw();
    //}
    //}

    void Draw() {
        /*if (!m_initialized) {
            PeriodCollection.UpdateButton();
            m_initialized = true;
            PeriodCollection.Draw();
        }*/
        bool const proportions_changed = ProportionsManager.IsProportionsChanged();
        if (proportions_changed) {
            ProportionsManager.UpdateProportions();
            PeriodCollection.UpdatePosition();
            for (uint i{0}; i < TradeBuilders.Size(); ++i) {
                TradeBuilders[i].UpdatePosition();
            }
            PeriodCollection.Draw();
        }
        int const orders_total = OrdersTotal();
        if (proportions_changed || m_orders_total != orders_total) {
            // PeriodCollection.Draw();
            //  PrintFormat("%s", __FUNCTION__);
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
                TradeBuilders[PositionType % 2].Draw();
                TradeBuilders[(PositionType + 1) % 2].Hide();
            }
            m_orders_total = orders_total;
            // PrintFormat("%s %u", __FUNCTION__, m_orders_total);
            //  ChartRedraw();
        }
    }

    void onTick() {
        /*if (bid != SymbolInfoDouble(Symbol(), SYMBOL_BID)) {
            bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
        }*/
        // m_quote(position_type == POSITION_TYPE_BUY ? SYMBOL_ASK : SYMBOL_BID);
        // if (PositionReporter.getStatus()) {
        /*case CPositionReporter::EnumPositionType::LONG:
            LongBuilder.onTick();
            LongBuilder.DrawLevels();
            break;
        case CPositionReporter::EnumPositionType::SHORT:
            ShortBuilder.onTick();
            ShortBuilder.DrawLevels();
            break;*/
        //}

        CPositionReporter::EnumPositionType const PositionType{PositionReporter.getPositionType()};
        if (PositionType == CPositionReporter::EnumPositionType::NONE) {
            for (uint i{0}; i < TradeBuilders.Size(); ++i) {
                TradeBuilders[i].onTick();
            }
        } else {
            TradeBuilders[PositionType % 2].onTick();
        }

        /*for (uint i{0}; i < TradeBuilders.Size(); ++i) {
            TradeBuilders[i].onTick();
            TradeBuilders[i].DrawLevels();
        }*/
        // ChartRedraw();
    }

    void onEdit(string const &sparam) const {
        for (uint i{0}; i < TradeBuilders.Size(); ++i) {
            if (TradeBuilders[i].onEdit(sparam)) {
                TradeBuilders[i].drawLevels();
                return;
            }
        }
    }

    void onButton(string const &sparam) {
        for (uint i{0}; i < TradeBuilders.Size(); ++i) {
            if (TradeBuilders[i].onButton(sparam)) {
                // TradeBuilders[i].drawLevels();
                //  m_orders_count = TradeBuilders[i].OrdersCount();
                //   PrintFormat("%s index %u order_count %u", __FUNCTION__, i, m_orders_count);
                //  ChartRedraw();
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
        PositionReporter.getStatus();
        double const new_volume{PositionGetDouble(POSITION_VOLUME)};
        if (!m_volume && new_volume) {
            PrintFormat("%s open position %f %f", __FUNCTION__, m_volume, new_volume);
        } else if (m_volume == new_volume) {
            // PrintFormat("%s same position %f %f", __FUNCTION__, m_old_volume, new_volume);
        } else if (m_volume < new_volume) {
            PrintFormat("%s augment position %f %f", __FUNCTION__, m_volume, new_volume);
        } else if (m_volume > new_volume) {
            PrintFormat("%s diminish position %f %f", __FUNCTION__, m_volume, new_volume);
        } else if (m_volume && !new_volume) {
            PrintFormat("%s close position %f %f", __FUNCTION__, m_volume, new_volume);
            /*for (uint i{0}; i < TradeBuilders.Size(); ++i) {
                TradeBuilders[i].Draw();
            }*/
        }

        // if (m_volume != new_volume) {
        // PrintFormat("%s %f", __FUNCTION__, new_volume);
        //}  // m_old_status = new_status;
        m_volume = new_volume;
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

        // PrintFormat("%s", __FUNCTION__);
        //  if (m_orders_total == OrdersTotal()) {
        //  PrintFormat("%s %u %u | %u", __FUNCTION__, TradeBuilders[0].OrdersCount(), TradeBuilders[1].OrdersCount(), OrdersTotal());
        // }
        //  PrintFormat("%s %u %u", __FUNCTION__, m_orders_total, OrdersTotal());
        // if (m_orders_total != OrdersTotal()) {
        //    m_orders_total = OrdersTotal();
        //    PrintFormat("%s %u", __FUNCTION__, m_orders_total);
        // PrintFormat("%s %f", __FUNCTION__, PositionGetDouble(POSITION_VOLUME));
        /*CPositionReporter::EnumPositionType const PositionType{PositionReporter.getPositionType()};
            if (PositionType == CPositionReporter::EnumPositionType::NONE) {
                for (uint i{0}; i < TradeBuilders.Size(); ++i) {
                    TradeBuilders[i].Draw();
                }
            } else {
                TradeBuilders[PositionType % 2].Draw();
                TradeBuilders[(PositionType + 1) % 2].Hide();
            }*/
        // PrintFormat("%s %u", __FUNCTION__, OrdersTotal());
        Draw();
        /*if (OrdersTotal() == 0) {
            TradeBuilders[0].cancelOrdersHide();
            TradeBuilders[1].cancelOrdersHide();
        }*/

        // ChartRedraw();
        //  PrintFormat("%s %d", __FUNCTION__, m_orders_total);

        /*if (OrdersTotal() == 0) {
            ChartRedraw();
        }*/
        //  }
    }

    // private:
    //  bool isNewPosition() {
    //      // if (PositionSelect(Symbol()) && HistorySelectByPosition(PositionGetInteger(POSITION_TICKET)) && m_history_orders_total != HistoryOrdersTotal()) {
    //      if (PositionReporter.getStatus() && m_history_orders_total != HistoryOrdersTotal()) {
    //          m_history_orders_total = HistoryOrdersTotal();
    //          // PrintFormat("%s %d %d", __FUNCTION__, m_history_orders_total, OrdersTotal());
    //          return true;
    //      }

    //     return false;
    // }
};