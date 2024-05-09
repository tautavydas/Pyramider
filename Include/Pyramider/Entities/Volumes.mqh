// ###<Experts/Pyramider.mq5>

struct CVolumes final {
    double const VolumeMin, const VolumeMax, const VolumeStep, const VolumeLimit;
    long const AccountLimitOrders;
    CVolumes() : VolumeMin(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)),
                 VolumeMax(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)),
                 VolumeStep(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP)),
                 VolumeLimit(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_LIMIT)),
                 AccountLimitOrders(AccountInfoInteger(ACCOUNT_LIMIT_ORDERS)) {}
};