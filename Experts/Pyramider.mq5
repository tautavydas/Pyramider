#property copyright "TJ Productions"
#property link "https://www.mql5.com"
#property version "420.666"

// #resource "\\Indicators\\SubWindow.ex5"
#include <Generic/HashMap.mqh>
#include <Pyramider/Entities/BuilderManager.mqh>
#include <Pyramider/Entities/MagicNumber.mqh>
#include <Pyramider/Entities/Volumes.mqh>

input double  // PriceRatioLong = 1, PriceRatioShort = 1,
              // NotionalRatioLong = 1,
    // NotionalRatioShort = 1,
    // ProfitRatioLong = 1, ProfitRatioShort = 1,
    xProportions = 0.025,
    yProportions = 0.05;
// input uint PriceRatioDigits    = 3    , NotionalRatioDigits = 2;
// input uint NotionalRatioDigits = 2;

double const g_contract{SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE)}, const g_margin_call{AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL) / 100.0};
long const g_leverage{AccountInfoInteger(ACCOUNT_LEVERAGE)};
ulong const g_cooloff_period{1000};
ulong g_tick_count_milliseconds{GetTickCount64() - g_cooloff_period};

CVolumes const g_volumes;
CMagicNumber const g_magic;

ENUM_TIMEFRAMES const Periods[]{PERIOD_M1, PERIOD_M2, PERIOD_M3, PERIOD_M4, PERIOD_M5, PERIOD_M6, PERIOD_M10, PERIOD_M12, PERIOD_M15, PERIOD_M20, PERIOD_M30, PERIOD_H1, PERIOD_H2, PERIOD_H3, PERIOD_H4, PERIOD_H6, PERIOD_H8, PERIOD_H12, PERIOD_D1, PERIOD_W1, PERIOD_MN1};
CBuilderManager BuilderManager(xProportions, yProportions, Periods);

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

    // BuilderManager.UpdateProportions();
    // PrintFormat("%s", __FUNCTION__);
    // PeriodCollection.UpdateButton();
    // ProportionsManager.UpdateProportions();

    string str_print = "", str_alert = "";
    bool success = INIT_SUCCEEDED;
    if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
        str_print += StringFormat("%s %s\n", EnumToString(TERMINAL_TRADE_ALLOWED), string(bool(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))));
        str_alert += "Terminal trading is not allowed\n";
        success = INIT_FAILED;
    }

    if (!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)) {
        str_print += StringFormat("%s %s\n", EnumToString(ACCOUNT_TRADE_ALLOWED), string(bool(AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))));
        str_alert += "Account trading is not allowed\n";
        success = INIT_FAILED;
    }

    if (AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_NETTING) {
        str_print += EnumToString(ENUM_ACCOUNT_MARGIN_MODE(AccountInfoInteger(ACCOUNT_MARGIN_MODE)));
        str_alert += "Account Margin Mode should be netting";
        success = INIT_FAILED;
    }

    if (success == INIT_FAILED) {
        // ExpertRemove();
        PrintFormat("%s %s", __FUNCTION__, str_print);
        Alert(str_alert);
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
    Comment("");
}

void OnTick() {
    /*ObjectLong.Update();
    ObjectShort.Update();
    ChartRedraw();*/
    // PositionReporter.SetValue();
    BuilderManager.onTick();
    // ChartRedraw();

    // if (Symbol() == "BTCUSD") {
    //     PositionsTotal();
    // PositionSelect(Symbol());
    // PositionGetSymbol(0);
    // HistorySelectByPosition(PositionGetInteger(POSITION_TICKET));
    // PrintFormat("%s 1# %d", __FUNCTION__, PositionsTotal());
    // PrintFormat("%s 2# %d", __FUNCTION__, PositionSelect(Symbol()));
    // PrintFormat("%s 3# %d", __FUNCTION__, PositionGetSymbol(0));
    // PrintFormat("%s 4# %d", __FUNCTION__, HistorySelectByPosition(PositionGetInteger(POSITION_TICKET)));
    // PrintFormat("%s 5# %d", __FUNCTION__, HistoryOrdersTotal());
    // PrintFormat("%s 6 %d", __FUNCTION__, HistoryDealsTotal());
    // }

    // if (m_old_staPositionReporter.getStatus())
    // if (BuilderManager.isNewPosition()) {
    //     // PrintFormat("%s 1", __FUNCTION__);
    // } else {
    //     // PrintFormat("%s 2", __FUNCTION__);
    // }
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
    // BuilderManager.onTrade();
    // PositionReporter.getPositionType();

    // PrintFormat("%d", PositionsTotal());

    // PositionSelect(Symbol());
    // if (BuilderManager.isNewPosition()) {
    //     PrintFormat("%s 1", __FUNCTION__);
    // } else {
    //     PrintFormat("%s %u", __FUNCTION__, HistoryOrdersTotal());
    // }
    /*PositionsTotal();
    PositionSelect(Symbol());
    PrintFormat("%s %d %d", __FUNCTION__, HistoryOrdersTotal(), HistoryDealsTotal());*/

    // PrintFormat("%s %d", __FUNCTION__, OrdersTotal());

    // if (BuilderManager.isNewPosition()) {
    //     // PrintFormat("%s 1", __FUNCTION__);

    //     } else {
    //     // PrintFormat("%s 2", __FUNCTION__);
    // }

    BuilderManager.onTrade();
    // PrintFormat("%s", __FUNCTION__);
    //  ChartRedraw();
}

void OnTradeTransaction(MqlTradeTransaction const &transaction, MqlTradeRequest const &request, MqlTradeResult const &result) {
    /*PrintFormat("%s Request: action %s magic %llu order %llu symbol %s volume %g price %g stoplimit %g sl %g tp %g devation %llu type %s type_filling %s type_time %s expiration %s comment %s position %llu position_by %llu",
                __FUNCTION__,
                EnumToString(ENUM_TRADE_REQUEST_ACTIONS(request.action)),
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
                TimeToString(request.type_time, TIME_DATE | TIME_MINUTES | TIME_SECONDS),
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
                result.retcode_external);*/

    /*PrintFormat("%s Transaction: deal %llu order %llu symbol %s type %s order_type %s order_state %s deal_type %s time_type %s time_expiration %s price %g price_trigger %g price_sl %g price_tp %g volume %g position %llu position_by %llu",
                __FUNCTION__,
                transaction.deal,
                transaction.order,
                transaction.symbol,
                EnumToString(transaction.type),
                EnumToString(ENUM_ORDER_TYPE(transaction.order_type)),
                EnumToString(transaction.order_state),
                EnumToString(transaction.deal_type),
                EnumToString(transaction.time_type),
                TimeToString(transaction.time_expiration, TIME_DATE | TIME_MINUTES | TIME_SECONDS),
                transaction.price,
                transaction.price_trigger,
                transaction.price_sl,
                transaction.price_tp,
                transaction.volume,
                transaction.position,
                transaction.position_by);*/

    // PrintFormat("%s %d", __FUNCTION__, OrdersTotal());

    // bool select = HistorySelectByPosition(PositionGetInteger(POSITION_TICKET));
    // PrintFormat("%s %s %d", __FUNCTION__, string(select), HistoryOrdersTotal());

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
    if (transaction.type == TRADE_TRANSACTION_HISTORY_ADD) {
        // TransactionInProgress=false;
        // ObjectsDeleteAll(ChartID(), 0, OBJ_HLINE);
        // PrintFormat("%s %s %s", __FUNCTION__, transaction.symbol, request.symbol);
        // PositionReporter.UpdatePrice();
        // PositionReporter.Draw();
        // PrintFormat("%s in %s %s", __FUNCTION__, transaction.symbol, request.symbol);
    } else if (transaction.type == TRADE_TRANSACTION_REQUEST) {
        // BuilderManager.UpdatePrice();
        // BuilderManager.Draw();
        // BuilderManager.SetGeometry();
        // ChartRedraw();
    }
    // PrintFormat("%s", __FUNCTION__);
    //  PrintFormat("%s %s '%s' %s", __FUNCTION__, EnumToString(transaction.type), transaction.symbol, EnumToString(request.type));
    //  PrintFormat("%s %s %s", __FUNCTION__, EnumToString(transaction.type), EnumToString(PositionReporter.getPositionType()));
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
    //  BuilderManager.SetGeometry();
    //   ChartRedraw();
    if (id == CHARTEVENT_CLICK) {
        // PrintFormat("%s", __FUNCTION__);
    } else if (id == CHARTEVENT_MOUSE_MOVE) {
    } else if (id == CHARTEVENT_CUSTOM) {
    } else if (id == CHARTEVENT_OBJECT_ENDEDIT) {
        // ObjectLong.EventEdit(sparam);
        // ObjectShort.EventEdit(sparam);
        BuilderManager.onEdit(sparam);
        // PositionReporter.CalcLevels();
        ChartRedraw();
        // ObjectLong.CalcLevels();
        // ObjectShort.CalcLevels();
    } else if (id == CHARTEVENT_OBJECT_CLICK) {
        // ObjectLong.EventButtonClick(sparam);
        // ObjectShort.EventButtonClick(sparam);
        // ObjectLong.CalcLevels();
        // ObjectShort.CalcLevels();
        // ObjectLong.EventTradeClick(sparam);
        // ObjectShort.EventTradeClick(sparam);
        // PrintFormat("%s %s", __FUNCTION__,sparam);
        // PrintFormat("%s", __FUNCTION__);
        PrintFormat("%s %s", __FUNCTION__, EnumToString(ENUM_CHART_EVENT(id)));
        BuilderManager.onButton(sparam);
        // PositionReporter.CalcLevels();
        // PeriodCollection.ChangePeriod(sparam);
        ChartRedraw();
    } else if (id == CHARTEVENT_CHART_CHANGE) {
        // ProportionsManager.UpdateProportions();
        // PrintFormat("%s %s %I64u %I64u", __FUNCTION__, EnumToString(ENUM_CHART_EVENT(id)), GetTickCount64() - tick_count_milliseconds, GetMicrosecondCount() - tick_count_microseconds);

        // BuilderManager.UpdatePosition();
        // BuilderManager.Draw();
        //  PeriodCollection.UpdateButton();
        //  PeriodCollection.Draw();
        if (g_tick_count_milliseconds + g_cooloff_period <= GetTickCount64()) {
            PrintFormat("%s %s %I64u", __FUNCTION__, EnumToString(ENUM_CHART_EVENT(id)), GetTickCount64() - g_tick_count_milliseconds);
            g_tick_count_milliseconds = GetTickCount64();
            // BuilderManager.UpdatePosition();
            BuilderManager.Draw();
            ChartRedraw();
        }
    } else if (id == CHARTEVENT_CLICK) {
        PrintFormat("%s %s", __FUNCTION__, EnumToString(ENUM_CHART_EVENT(id)));
    }
    // PrintFormat("1 %s | %s | %u | %u | %s", __FUNCTION__, EnumToString(ENUM_CHART_EVENT(id)), lparam, dparam, sparam);
}

// typedef string (*PrtStringSpread)();
// string StringFloatSpread() { return StringFormat("%.*f", Digits(), SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) * Point()); }
// string StringIntegerSpread() { return StringFormat("%u", SymbolInfoInteger(Symbol(), SYMBOL_SPREAD)); }

// class CSpread final {
//    public:
//     PrtStringSpread String;
//     CSpread()
//     /*: String(SymbolInfoInteger(Symbol(), SYMBOL_SPREAD_FLOAT)?StringFloatSpread:StringIntegerSpread)*/ {
//         if (SymbolInfoInteger(Symbol(), SYMBOL_SPREAD_FLOAT))
//             String = StringFloatSpread;
//         else
//             String = StringIntegerSpread;
//     }
// };

// class CAdministrative final {
//    private:
//     uint const last;

//    public:
//     double Fee, RangeDiff[], Leverage[];
//     CAdministrative()
//         : last(ArrayResize(Leverage, ArrayResize(RangeDiff, 3) + 1)) {
//         // PrintFormat("%s %s %s", SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE), SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT), SymbolInfoString(Symbol(), SYMBOL_CURRENCY_MARGIN));
//         // PrintFormat("%s: %s WTF", __FUNCTION__, EnumToString(ENUM_SYMBOL_SECTOR(SymbolInfoInteger(Symbol(), SYMBOL_SECTOR))));

//         if (SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE) == "BTC") {
//             Fee = 0.000035;
//             RangeDiff[0] = 500000;
//             RangeDiff[1] = 5000000 - 500000;
//             RangeDiff[2] = 10000000 - 5000000;
//             Leverage[0] = 1000;
//             Leverage[1] = 500;
//             Leverage[2] = 100;
//             Leverage[3] = 50;
//         } else if (SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE) == "BTC") {
//             Fee = 0.000750;
//             RangeDiff[0] = 50000;
//             RangeDiff[1] = 500000 - 50000;
//             RangeDiff[2] = 1000000 - 500000;
//             Leverage[0] = 100;
//             Leverage[1] = 50;
//             Leverage[2] = 25;
//             Leverage[3] = 10;
//         } else if (SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE) == "DOG") {
//             Fee = 0.000750;
//             RangeDiff[0] = 5000;
//             RangeDiff[1] = 50000 - 5000;
//             RangeDiff[2] = 100000 - 50000;
//             Leverage[0] = 100;
//             Leverage[1] = 50;
//             Leverage[2] = 25;
//             Leverage[3] = 10;
//         }

//         /*switch(ENUM_SYMBOL_SECTOR(SymbolInfoInteger(Symbol(), SYMBOL_SECTOR))) {
//           case SECTOR_CURRENCY:
//             Fee=0.0000315;
//             RangeDiff[0]=500000;
//             RangeDiff[1]=5000000-500000;
//             RangeDiff[2]=10000000-5000000;
//             Leverage[0]=1000;
//             Leverage[1]=500;
//             Leverage[2]=100;
//             Leverage[3]=50;
//             break;
//           case SECTOR_CURRENCY_CRYPTO:
//             Fee=0.000750;
//             if(SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE)=="BTC") {
//               RangeDiff[0]=50000;
//               RangeDiff[1]=500000-50000;
//               RangeDiff[2]=1000000-500000;
//             } else {
//               RangeDiff[0]=5000;
//               RangeDiff[1]=50000-5000;
//               RangeDiff[2]=100000-50000;
//             }
//             Leverage[0]=100;
//             Leverage[1]=50;
//             Leverage[2]=25;
//             Leverage[3]=10;
//             break;
//           case SECTOR_UNDEFINED:
//             Fee=0.000750;
//             if(SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE)=="BTC") {
//               RangeDiff[0]=50000;
//               RangeDiff[1]=500000-50000;
//               RangeDiff[2]=1000000-500000;
//             } else {
//               RangeDiff[0]=5000;
//               RangeDiff[1]=50000-5000;
//               RangeDiff[2]=100000-50000;
//             }
//             Leverage[0]=100;
//             Leverage[1]=50;
//             Leverage[2]=25;
//             Leverage[3]=10;
//             break;
//           default: PrintFormat("%s: %s WTF", __FUNCTION__, EnumToString(ENUM_SYMBOL_SECTOR(SymbolInfoInteger(Symbol(), SYMBOL_SECTOR))));
//         }*/
//     }

//     double Margin(double const residual, uint const curr) const {
//         if (curr + 1 < last)
//             if (residual < RangeDiff[curr])
//                 return residual / Leverage[curr];
//             else
//                 return fmin(residual, RangeDiff[curr]) / Leverage[curr] + Margin(residual - RangeDiff[curr], curr + 1);
//         else
//             return residual / Leverage[curr];
//     }
// } const Administrative;

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