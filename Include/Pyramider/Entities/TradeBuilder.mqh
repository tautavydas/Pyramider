// ###<Experts/Pyramider.mq5>

#include <Pyramider/Collections/EditableCollection.mqh>
#include <Pyramider/Objects/ActionButton.mqh>
#include <Pyramider/Objects/DrawButton.mqh>
#include <Pyramider/Objects/EditableObject.mqh>

class ITradeBuilder {
   public:
    virtual void Hide() const = 0;
    virtual void Draw() = 0;
    virtual void onTick() const = 0;
    virtual void onPositionOpen() const = 0;
    virtual void onPositionChange() const = 0;
    virtual bool onEdit(string const &sparam) const = 0;
    virtual bool onButton(string const &sparam) = 0;
    virtual void CalcLevels() const = 0;
};

template <typename ExtremumType>
class CTradeBuilder : public ITradeBuilder {
    CPositionReporter *const PositionReporter;
    CEditableCollection<ExtremumType> *const EditableCollection;
    CEditableObject *const RestrictedDeals,
        const *const Price,
        const *const PriceRatio,
        const *const Volume,
        const *const NotionalRatio;
    DrawButton *const DrawDeals, *const DrawPositions, *const DrawMarginCall;
    ActionButton *const Trade, *const Reset;
    ExtremumType const MinMax;
    CConverter const *const Converter;

    ENUM_SYMBOL_INFO_DOUBLE const m_quote;
    ENUM_ORDER_TYPE const m_type;
    int const m_direction;
    bool m_reset_bool;

   public:
    CTradeBuilder(CProportionsManager const &proportions_manager,
                  CPositionReporter &position_reporter,
                  ENUM_POSITION_TYPE const position_type)
        : PositionReporter(&position_reporter),
          Converter(new CConverter(SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT), "USD", AccountInfoString(ACCOUNT_CURRENCY))),
          EditableCollection(new CEditableCollection<ExtremumType>(proportions_manager, position_reporter, position_type, this)),
          Price(EditableCollection[0]),
          PriceRatio(EditableCollection[1]),
          Volume(EditableCollection[2]),
          NotionalRatio(EditableCollection[3]),
          RestrictedDeals(EditableCollection[4]),
          DrawDeals(new DrawButton(proportions_manager, 14, position_type, "Deals", Volume.m_digits)),
          DrawPositions(new DrawButton(proportions_manager, 16, position_type, "Positions", Volume.m_digits)),
          DrawMarginCall(new DrawButton(proportions_manager, 20, position_type, "MarginCall", 3)),
          Trade(new ActionButton(proportions_manager, 0, position_type, "Limit")),
          Reset(new ActionButton(proportions_manager, 0, position_type, "Reset")),
          m_quote(position_type == POSITION_TYPE_BUY ? SYMBOL_ASK : SYMBOL_BID),
          m_type(position_type == POSITION_TYPE_BUY ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT),
          m_direction(position_type == POSITION_TYPE_BUY ? -1 : 1),
          m_reset_bool(true) {}

    ~CTradeBuilder() {
        delete Converter;
        delete EditableCollection;
        delete Reset;
        delete Trade;
        delete DrawDeals;
        delete DrawPositions;
        delete DrawMarginCall;
    }

    void Draw() override {
        if (orderExists()) {
            Reset.Draw();
        } else {
            EditableCollection.Draw();
            DrawDeals.Draw();
            DrawPositions.Draw();
            DrawMarginCall.Draw();
            if (DrawDeals.State())
                Trade.Draw();
        }
    }

    void Hide() const {
        EditableCollection.Hide();
        Trade.Hide();
        Reset.Hide();
        DrawDeals.Hide();
        DrawPositions.Hide();
        DrawMarginCall.Hide();
    }

    void onTick() const override {
        // Trade.UpdatePrice();
        // Price.UpdatePrice();
        // CalcLevels();
    }

    // void onTrade() const { /*PrintFormat("%s", __FUNCTION__);*/
    //     // PrintFormat("%s VolumeLots %f", __FUNCTION__, volume_total);
    //     PrintFormat("%s Leverage %f", __FUNCTION__, Leverage);
    //     PrintFormat("%s Contract %f", __FUNCTION__, Contract);
    //     PrintFormat("%s Volume %f", __FUNCTION__, Contract * PositionReporter.getVolume());
    //     // PrintFormat("%s Price %f", __FUNCTION__, PositionReporter.getStatus() ? PositionReporter.getPrice() : Price.getValue());
    //     // PrintFormat("%s NotionalDrop %f", __FUNCTION__, Converter.DepositToQuote(fmin(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE)) - AccountInfoDouble(ACCOUNT_MARGIN) * MarginCall, m_quote));
    //     // PrintFormat("%s PriceDrop %f", __FUNCTION__, Converter.DepositToQuote(fmin(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE)) - AccountInfoDouble(ACCOUNT_MARGIN) * MarginCall, m_quote) / (Contract * volume));
    //     // PrintFormat("%s PriceMargin %f", __FUNCTION__, (PositionReporter.getStatus() ? PositionReporter.getPrice() : Price.getValue()) - Converter.DepositToQuote(fmin(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE)) - AccountInfoDouble(ACCOUNT_MARGIN) * MarginCall, m_quote) / (Contract * volume));
    // }

    void onPositionOpen() const { PrintFormat("%s", __FUNCTION__); }
    void onPositionChange() const { PrintFormat("%s", __FUNCTION__); }

    bool onEdit(string const &sparam) const override {
        return EditableCollection.onEdit(sparam);
    }

    bool onButton(string const &sparam) {
        if (Trade.name == sparam) {
            if (DrawDeals.State()) {
                Trade.Hide();
                DrawDeals.Hide();
                DrawPositions.Hide();
                RestrictedDeals.Hide();
                EditableCollection.Hide();
                Reset.Draw();
                MakeOrders();
            }
            m_reset_bool = true;
            // return false;
        } else if (Reset.name == sparam) {
            Reset.Hide();
            DrawDeals.Draw();
            DrawPositions.Draw();
            EditableCollection.Draw();
            CancelOrders();
            // DrawMarginCall.Draw();
            // PrintFormat("%s %f", __FUNCTION__, PositionGetDouble(POSITION_PRICE_CURRENT));
            // return false;
        } else if (DrawDeals.name == sparam || DrawPositions.name == sparam) {
            bool const draw_deals{DrawDeals.State()}, const draw_positions{DrawPositions.State()};
            if (draw_deals || draw_positions) {
                if (m_reset_bool) {
                    RestrictedDeals.Draw();
                    m_reset_bool = false;
                }
                if (draw_deals) {
                    Trade.Draw();
                }
            } else {
                RestrictedDeals.Hide();
                Trade.Hide();
                m_reset_bool = true;
            }

            if (!draw_deals) {
                Trade.Hide();
                DrawDeals.DeleteLines();
            }

            if (!draw_positions) {
                DrawPositions.DeleteLines();
            }

            return true;
        }

        return EditableCollection.onButton(sparam);
    }

    uint getCount() const {
        double const balance{PositionReporter.getBalance()},
            equity{PositionReporter.getEquity()},
            margin{PositionReporter.getMargin()},
            profit{PositionReporter.getProfit()},
            swap{PositionReporter.getSwap()},
            price_ratio{PriceRatio.getValue()},
            notional_ratio{NotionalRatio.getValue()};
        double
            price{PositionReporter.getStatus() ? PositionReporter.getPrice() : Price.getValue()},
            volume{Volume.getValue()}, volume_total{volume},
            notional{price * volume}, notional_total{notional},
            Margin{Converter.QuoteToDeposit(notional_total * Contract / Leverage, m_quote)};

        uint counter{0};
        while (Margin * MarginCall < equity && /*volume_total < Volumes.VolumeLimit*/ Volumes.VolumeLimit ? volume_total < Volumes.VolumeLimit : true && counter < Volumes.AccountLimitOrders) {
            price = fmax(0, MinMax.process(price * price_ratio, price + m_direction * Point()));
            notional *= notional_ratio;
            volume = floor(notional / price / Volumes.VolumeStep) * Volumes.VolumeStep;
            volume_total += volume;
            notional_total += volume * price;
            Margin += Converter.QuoteToDeposit(notional_total * Contract / Leverage, m_quote);
            ++counter;  // + uint(volume / Volumes.VolumeMax);
        }
        // PrintFormat("%s equity %f margin %f profit %f volumeLimit %f limitOrders %d", __FUNCTION__, equity, margin, profit, Volumes.VolumeLimit, Volumes.AccountLimitOrders);
        //  PrintFormat("%s price %f price_ratio %f volume %f total_volume %f notional %f notional_ratio %f total_notional %f Margin %f counter %d", __FUNCTION__, price, price_ratio, volume, volume_total, notional, notional_ratio, notional_total, Margin, counter);

        return counter;
    }

    void CalcLevels() const {
        bool const state_deals{DrawDeals.State()}, const state_positions{DrawPositions.State()};
        if (state_deals || state_positions) {
            double const balance{PositionReporter.getBalance()},
                equity{PositionReporter.getEquity()},
                margin{PositionReporter.getMargin()},
                profit{PositionReporter.getProfit()},
                swap{PositionReporter.getSwap()},
                price_ratio{PriceRatio.getValue()},
                notional_ratio{NotionalRatio.getValue()};
            double
                price{PositionReporter.getStatus() ? PositionReporter.getPrice() : Price.getValue()},
                volume{Volume.getValue()}, volume_total{volume},
                notional{price * volume}, notional_total{notional},
                Margin{Converter.QuoteToDeposit(notional_total * Contract / Leverage, m_quote)};

            DrawDeals.ResetCounter();
            DrawPositions.ResetCounter();
            while (Margin * MarginCall < equity && /*volume_total < Volumes.VolumeLimit*/ Volumes.VolumeLimit ? volume_total < Volumes.VolumeLimit : true && fmax(DrawDeals.SizeCounter(), DrawPositions.SizeCounter()) < Volumes.AccountLimitOrders) {
                if (state_deals) {
                    double rest_volume{volume}, curr_volume{rest_volume};
                    for (uint i{0}, num_iter{uint(floor(volume / Volumes.VolumeMax))}; i <= num_iter; ++i) {
                        curr_volume = Volumes.VolumeMax <= rest_volume ? Volumes.VolumeMax : rest_volume;
                        DrawDeals.Push(price, curr_volume);
                        // PrintFormat("%s %u %u", __FUNCTION__, i, DrawDeals.SizeCounter());
                        rest_volume -= curr_volume;
                    }
                }
                if (state_positions)
                    DrawPositions.Push(notional_total / volume_total, volume_total);

                price = fmax(0, MinMax.process(price * price_ratio, price + m_direction * Point()));
                notional *= notional_ratio;

                volume = fmax(floor(notional / price / Volumes.VolumeStep) * Volumes.VolumeStep, Volumes.VolumeStep);
                volume_total += volume;
                notional_total += volume * price;
                Margin += Converter.QuoteToDeposit(notional_total * Contract / Leverage, m_quote);
            }
            uint const restricted_deals{uint(RestrictedDeals.getValue())};
            DrawDeals.Drop(restricted_deals);
            DrawPositions.Drop(restricted_deals);

            if (state_deals)
                DrawDeals.DrawLines();
            if (state_positions) {
                DrawPositions.DrawLines();
                // PrintFormat("%s VolumeLots %f", __FUNCTION__, volume_total);
                // PrintFormat("%s Leverage %f", __FUNCTION__, Leverage);
                // PrintFormat("%s Contract %f", __FUNCTION__, Contract);
                // PrintFormat("%s Volume %f", __FUNCTION__, Contract * volume_total);
                // PrintFormat("%s Price %f", __FUNCTION__, PositionReporter.getStatus() ? PositionReporter.getPrice() : Price.getValue());
                // PrintFormat("%s NotionalDrop %f", __FUNCTION__, Converter.DepositToQuote(fmin(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE)) - AccountInfoDouble(ACCOUNT_MARGIN) * MarginCall, m_quote));
                // PrintFormat("%s PriceDrop %f", __FUNCTION__, Converter.DepositToQuote(fmin(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE)) - AccountInfoDouble(ACCOUNT_MARGIN) * MarginCall, m_quote) / (Contract * volume));
                // PrintFormat("%s PriceMargin %f", __FUNCTION__, (PositionReporter.getStatus() ? PositionReporter.getPrice() : Price.getValue()) - Converter.DepositToQuote(fmin(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE)) - AccountInfoDouble(ACCOUNT_MARGIN) * MarginCall, m_quote) / (Contract * volume));
            }
        }

        // ObjectCreate(ChartID(), "MarginCall", OBJ_HLINE, 0, 0, PositionGetDouble(POSITION_PRICE_CURRENT) - Settings.Direction * Converter.DepositToQuote(fmin(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE)) - AccountInfoDouble(ACCOUNT_MARGIN) * MarginCall, Settings.QuoteOut) / (Contract * PositionGetDouble(POSITION_VOLUME)));
        // double yo = (PositionReporter.getStatus() ? PositionReporter.getPrice() : Price.getValue()) - m_direction * Converter.DepositToQuote(fmin(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE)) - AccountInfoDouble(ACCOUNT_MARGIN) * MarginCall, m_quote) / (Contract * PositionGetDouble(POSITION_VOLUME));
        // PrintFormat("%s %f %f", __FUNCTION__, yo, fmin(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE)));
        // PrintFormat("%s %f %f", __FUNCTION__, AccountInfoDouble(ACCOUNT_MARGIN), MarginCall);
        // PrintFormat("%s %f", __FUNCTION__, Converter.DepositToQuote(fmin(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE)) - AccountInfoDouble(ACCOUNT_MARGIN) * MarginCall, m_quote));
    }

   private:
    void MakeOrders() const {
        // uint total_iterations{0};
        for (uint counter{0}; counter < DrawDeals.SizeCounter(); ++counter) {
            /*uint num_iter{uint(floor(DrawDeals.Levels[counter].m_volume / Volumes.VolumeMax))};
            total_iterations += num_iter + 1;

            if (total_iterations > Volumes.AccountLimitOrders) break;

            double rest_volume{DrawDeals.Levels[counter].m_volume}, curr_volume{rest_volume};
            for (uint i{0}; i <= num_iter; ++i) {
                curr_volume = Volumes.VolumeMax <= rest_volume ? Volumes.VolumeMax : rest_volume;
                rest_volume -= curr_volume;

                MqlTradeRequest const Request{TRADE_ACTION_PENDING, Magic.Number, 0, Symbol(), curr_volume, DrawDeals.Levels[counter].m_price, 0, 0, 0, 0, m_type, ORDER_FILLING_FOK, 0, 0, DrawDeals.Name(counter), 0, 0};
                Send(Request);
            }*/
            MqlTradeRequest const Request{TRADE_ACTION_PENDING, Magic.Number, 0, Symbol(), DrawDeals.Levels[counter].m_volume, DrawDeals.Levels[counter].m_price, 0, 0, 0, 0, m_type, ORDER_FILLING_FOK, 0, 0, DrawDeals.Name(counter), 0, 0};
            Send(Request);
            // PrintFormat("%s %d %d %d", __FUNCTION__, total_iterations, Volumes.AccountLimitOrders, DrawDeals.SizeCounter());
        }
    }

    void CancelOrders() const {
        for (int i{OrdersTotal() - 1}; i >= 0; i--) {
            ulong const order_ticket{OrderGetTicket(i)}, const magic_number{OrderGetInteger(ORDER_MAGIC)}, const order_type{OrderGetInteger(ORDER_TYPE)};
            // PrintFormat("%s %ld %ld %s %s", __FUNCTION__, magic_number, Magic.Number, EnumToString(ENUM_ORDER_TYPE(order_type)), EnumToString(ENUM_ORDER_TYPE(m_type)));
            if (magic_number == Magic.Number && order_type == m_type) {
                MqlTradeRequest const Request{TRADE_ACTION_REMOVE, magic_number, order_ticket, Symbol(), 0, 0, 0, 0, 0, 0, m_type, ORDER_FILLING_FOK, 0, 0, "set your systems volume control for slightly above the normal listening level", 0, 0};
                Send(Request);
            }
        }
    }

    void Send(MqlTradeRequest const &request) const {
        MqlTradeCheckResult Check{NULL};
        MqlTradeResult Result{NULL};
        if (OrderCheck(request, Check)) {
            // PrintFormat("OrderCheck 1: retcode %u balance %g equity %g profit %g margin %g margin_free %g margin_level %g comment %s", Check.retcode, Check.balance, Check.equity, Check.profit, Check.margin, Check.margin_free, Check.margin_level, Check.comment);
            if (OrderSendAsync(request, Result)) {
                // PrintFormat("OrderSend 1: retcode %u deal %llu order %llu volume %g price %g bid %g ask %g comment %s request_id %u retcode_external %u", Result.retcode, Result.deal, Result.order, Result.volume, Result.price, Result.bid, Result.ask, Result.comment, Result.request_id, Result.retcode_external);
            } else {
                PrintFormat("OrderSend 2: retcode %u | deal %llu | order %llu | volume %g | price %g | bid %g | ask %g | comment %s | request_id %u | retcode_external %u", Result.retcode, Result.deal, Result.order, Result.volume, Result.price, Result.bid, Result.ask, Result.comment, Result.request_id, Result.retcode_external);
            }
        } else {
            PrintFormat("%s %f", __FUNCTION__, request.volume);
            PrintFormat("OrderCheck 2: retcode %u | balance %g | equity %g | profit %g | margin %g | margin_free %g | margin_level %g | comment %s", Check.retcode, Check.balance, Check.equity, Check.profit, Check.margin, Check.margin_free, Check.margin_level, Check.comment);
        }
    }

    bool orderExists() const {
        for (int i{OrdersTotal() - 1}; i >= 0; i--) {
            OrderGetTicket(i);
            if (Magic.Number == OrderGetInteger(ORDER_MAGIC) && m_type == OrderGetInteger(ORDER_TYPE)) {
                return true;
            }
        }

        return false;
    }
};