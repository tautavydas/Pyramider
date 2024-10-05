// ###<Experts/Pyramider.mq5>

struct CVolumes final {
    double const m_volume_min, const m_volume_max, const m_volume_step, const m_volume_limit;
    long const m_account_limit_orders;
    CVolumes() : m_volume_min(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)),
                 m_volume_max(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)),
                 m_volume_step(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP)),
                 m_volume_limit(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_LIMIT)),
                 m_account_limit_orders(AccountInfoInteger(ACCOUNT_LIMIT_ORDERS)) {}
};