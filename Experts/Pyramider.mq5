#property copyright "TJ Productions"
#property link "https://www.mql5.com"
#property version "420.666"

#include <Pyramider/Entities/BuilderManager.mqh>
#include <Pyramider/Entities/MagicNumber.mqh>
#include <Pyramider/Entities/Volumes.mqh>

input double i_xProportions = 0.025, i_yProportions = 0.05;

double const g_contract{SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE)}, const g_margin_call{AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL) / 100.0};
long const g_leverage{AccountInfoInteger(ACCOUNT_LEVERAGE)};
ulong const g_cooloff_period{1000};
ulong g_tick_count_milliseconds{GetTickCount64() - g_cooloff_period};

CVolumes const g_volumes;
CMagicNumber const g_magic;

ENUM_TIMEFRAMES const Periods[]{PERIOD_M1, PERIOD_M2, PERIOD_M3, PERIOD_M4, PERIOD_M5, PERIOD_M6, PERIOD_M10, PERIOD_M12, PERIOD_M15, PERIOD_M20, PERIOD_M30, PERIOD_H1, PERIOD_H2, PERIOD_H3, PERIOD_H4, PERIOD_H6, PERIOD_H8, PERIOD_H12, PERIOD_D1, PERIOD_W1, PERIOD_MN1};
CBuilderManager BuilderManager(i_xProportions, i_yProportions, Periods);

int OnInit() {
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
        PrintFormat("%s %s", __FUNCTION__, str_print);
        Alert(str_alert);
    }

    return success;
}

void OnDeinit(const int reason) {
    Comment("");
}

void OnTick() {
    BuilderManager.onTick();
}

void OnTrade() {
    BuilderManager.onTrade();
}

void OnTradeTransaction(MqlTradeTransaction const &transaction, MqlTradeRequest const &request, MqlTradeResult const &result) {
    if (transaction.type == TRADE_TRANSACTION_HISTORY_ADD) {
    } else if (transaction.type == TRADE_TRANSACTION_REQUEST) {
    }
}

void OnChartEvent(int const id, long const &lparam, double const &dparam, string const &sparam) {
    if (id == CHARTEVENT_CLICK) {
    } else if (id == CHARTEVENT_MOUSE_MOVE) {
    } else if (id == CHARTEVENT_CUSTOM) {
    } else if (id == CHARTEVENT_OBJECT_ENDEDIT) {
        BuilderManager.onEdit(sparam);
        ChartRedraw();
    } else if (id == CHARTEVENT_OBJECT_CLICK) {
        // PrintFormat("%s %s", __FUNCTION__, EnumToString(ENUM_CHART_EVENT(id)));
        BuilderManager.onButton(sparam);
        ChartRedraw();
    } else if (id == CHARTEVENT_CHART_CHANGE) {
        if (g_tick_count_milliseconds + g_cooloff_period <= GetTickCount64()) {
            // PrintFormat("%s %s %I64u", __FUNCTION__, EnumToString(ENUM_CHART_EVENT(id)), GetTickCount64() - g_tick_count_milliseconds);
            g_tick_count_milliseconds = GetTickCount64();
            BuilderManager.Draw();
            ChartRedraw();
        }
    } else if (id == CHARTEVENT_CLICK) {
        // PrintFormat("%s %s", __FUNCTION__, EnumToString(ENUM_CHART_EVENT(id)));
    }
    // PrintFormat("1 %s | %s | %u | %u | %s", __FUNCTION__, EnumToString(ENUM_CHART_EVENT(id)), lparam, dparam, sparam);
}