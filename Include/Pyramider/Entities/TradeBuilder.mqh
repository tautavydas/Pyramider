// ###<Experts/Pyramider.mq5>

#include <Pyramider/Collections/EditableCollection.mqh>
#include <Pyramider/Objects/ActionButton.mqh>
#include <Pyramider/Objects/DrawButton.mqh>
#include <Pyramider/Objects/EditableObject.mqh>

class ITradeBuilder {
   public:
    virtual void Hide() const = 0;
    virtual void Draw() = 0;
    virtual void UpdatePrice() const = 0;
    virtual bool EventEdit(string const &sparam) const = 0;
    virtual bool EventButton(string const &sparam) = 0;
    virtual void CalcLevels() const = 0;
};

template <typename ExtremumType>
class CTradeBuilder : public ITradeBuilder {
    CConverter const *const Converter;
    CPositionReporter *const PositionReporter;
    ExtremumType const MinMax;
    ENUM_SYMBOL_INFO_DOUBLE const Quote;
    CEditableCollection<ExtremumType> *const EditableCollection;
    CEditableObject *const RestrictedDeals,
        const *const Price,
        const *const PriceRatio,
        const *const Volume,
        const *const NotionalRatio;
    DrawButton *const DrawDeals, *const DrawPositions;
    ActionButton *const Trade, *const Reset;

    ENUM_ORDER_TYPE const Type;
    int const Direction;
    bool ResetBool;

   public:
    CTradeBuilder(CProportionsManager const &proportions_manager,
                  CPositionReporter &position_reporter,
                  ENUM_POSITION_TYPE const position_type,
                  double const price_ratio,
                  double const notional_ratio)
        : PositionReporter(&position_reporter),
          Converter(new CConverter(SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT), "USD", AccountInfoString(ACCOUNT_CURRENCY))),
          Quote(position_type == POSITION_TYPE_BUY ? SYMBOL_ASK : SYMBOL_BID),
          EditableCollection(new CEditableCollection<ExtremumType>(proportions_manager, position_reporter, position_type, price_ratio, notional_ratio, this)),
          Price(EditableCollection[0]),
          PriceRatio(EditableCollection[1]),
          Volume(EditableCollection[2]),
          NotionalRatio(EditableCollection[3]),
          RestrictedDeals(EditableCollection[4]),
          DrawDeals(new DrawButton(proportions_manager, 14, position_type, "Deals", Volume.digits)),
          DrawPositions(new DrawButton(proportions_manager, 16, position_type, "Positions", Volume.digits)),
          Trade(new ActionButton(proportions_manager, 0, position_type, "Trade")),
          Reset(new ActionButton(proportions_manager, 0, position_type, "Reset")),

          Type(position_type == POSITION_TYPE_BUY ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT),
          Direction(position_type == POSITION_TYPE_BUY ? -1 : 1),
          ResetBool(true) {}

    ~CTradeBuilder() {
        delete Converter;
        delete EditableCollection;
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
        if (orderExists()) {
            Reset.Draw();
        } else {
            EditableCollection.Draw();
            DrawDeals.Draw();
            DrawPositions.Draw();
            if (DrawDeals.State())
                Trade.Draw();
        }
    }

    void Hide() const {
        EditableCollection.Hide();
        Trade.Hide();
        DrawDeals.Hide();
        DrawPositions.Hide();
        Reset.Hide();
    }

    bool EventButton(string const &sparam) {
        if (Trade.name == sparam) {
            if (DrawDeals.State()) {
                Trade.Hide();
                DrawDeals.Hide();
                DrawPositions.Hide();
                RestrictedDeals.Hide();
                EditableCollection.Hide();
                for (uint i{0}; i < DrawDeals.SizeCounter(); ++i) {
                    TradeLine(i);
                }
                Reset.Draw();
            }
            ResetBool = true;
            return true;
        } else if (Reset.name == sparam) {
            Reset.Hide();
            DrawDeals.Draw();
            DrawPositions.Draw();
            EditableCollection.Draw();
            for (int i{OrdersTotal() - 1}; i >= 0; i--) {
                ulong const order_ticket{OrderGetTicket(i)}, const magic_number{OrderGetInteger(ORDER_MAGIC)}, const order_type{OrderGetInteger(ORDER_TYPE)};
                // PrintFormat("%s %ld %ld %s %s", __FUNCTION__, magic_number, Magic.Number, EnumToString(ENUM_ORDER_TYPE(order_type)), EnumToString(ENUM_ORDER_TYPE(Type)));
                if (magic_number == Magic.Number && order_type == Type) {
                    MqlTradeRequest const Request{TRADE_ACTION_REMOVE, magic_number, order_ticket, Symbol(), 0, 0, 0, 0, 0, 0, Type, ORDER_FILLING_FOK, 0, 0, "set your systems volume control slightly above the normal listening level", 0, 0};
                    Send(Request);
                }
            }
        } else if (DrawDeals.name == sparam || DrawPositions.name == sparam) {
            bool const draw_deals{DrawDeals.State()}, const draw_positions{DrawPositions.State()};
            if (draw_deals || draw_positions) {
                if (ResetBool) {
                    RestrictedDeals.Draw();
                    ResetBool = false;
                }
                if (draw_deals) {
                    Trade.Draw();
                }
            } else {
                RestrictedDeals.Hide();
                Trade.Hide();
                ResetBool = true;
            }

            if (!draw_deals) {
                Trade.Hide();
                DrawDeals.DeleteLines();
            }
            if (!draw_positions)
                DrawPositions.DeleteLines();

            return true;
        }

        return EditableCollection.ChangeEdit(sparam);
    }

    bool EventEdit(string const &sparam) const override {
        return EditableCollection.ProcessEdit(sparam);
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
        while (Margin * MarginCall < equity && total_volume < Volumes.VolumeLimit && counter < AccountInfoInteger(ACCOUNT_LIMIT_ORDERS)) {
            price = fmax(0, MinMax.process(price * price_ratio, price + Direction * Point()));
            notional *= notional_ratio;
            volume = floor(notional / price / Volumes.VolumeStep) * Volumes.VolumeStep;
            total_volume += volume;
            total_notional += volume * price;
            Margin += Converter.QuoteToDeposit(total_notional * Contract / Leverage, Quote);
            ++counter;
        }

        return counter;
    }

    void CalcLevels() const {
        bool const state_deals{DrawDeals.State()}, const state_positions{DrawPositions.State()};
        if (state_deals || state_positions) {
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
            while (Margin * MarginCall < equity && total_volume < Volumes.VolumeLimit && fmax(DrawDeals.SizeCounter(), DrawPositions.SizeCounter()) < AccountInfoInteger(ACCOUNT_LIMIT_ORDERS)) {
                if (state_deals)
                    DrawDeals.Push(price, volume);
                if (state_positions)
                    DrawPositions.Push(total_notional / total_volume, total_volume);

                price = fmax(0, MinMax.process(price * price_ratio, price + Direction * Point()));
                notional *= NotionalRatio.getValue();

                volume = fmax(floor(notional / price / Volumes.VolumeStep) * Volumes.VolumeStep, Volumes.VolumeStep);
                total_volume += volume;
                total_notional += volume * price;
                Margin += Converter.QuoteToDeposit(total_notional * Contract / Leverage, Quote);
            }
        }
        DrawDeals.Drop(uint(RestrictedDeals.getValue()));
        DrawPositions.Drop(uint(RestrictedDeals.getValue()));

        if (state_deals)
            DrawDeals.DrawLines();
        if (state_positions)
            DrawPositions.DrawLines();
    }

   private:
    void TradeLine(uint const counter) const {
        double rest_volume{DrawDeals.Levels[counter].volume}, curr_volume{rest_volume};
        for (uint i{0}, num_iter{uint(floor(DrawDeals.Levels[counter].volume / Volumes.VolumeMax))}; i <= num_iter; ++i) {
            curr_volume = Volumes.VolumeMax <= rest_volume ? Volumes.VolumeMax : rest_volume;
            rest_volume -= curr_volume;

            MqlTradeRequest const Request{TRADE_ACTION_PENDING, Magic.Number, 0, Symbol(), curr_volume, DrawDeals.Levels[counter].price, 0, 0, 0, 0, Type, ORDER_FILLING_FOK, 0, 0, DrawDeals.Name(counter), 0, 0};
            Send(Request);
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
            PrintFormat("OrderCheck 2: retcode %u | balance %g | equity %g | profit %g | margin %g | margin_free %g | margin_level %g | comment %s", Check.retcode, Check.balance, Check.equity, Check.profit, Check.margin, Check.margin_free, Check.margin_level, Check.comment);
        }
    }

    bool orderExists() const {
        for (int i{OrdersTotal() - 1}; i >= 0; i--) {
            OrderGetTicket(i);
            if (Magic.Number == OrderGetInteger(ORDER_MAGIC) && Type == OrderGetInteger(ORDER_TYPE)) {
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