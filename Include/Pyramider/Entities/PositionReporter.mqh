// ###<Experts/Pyramider.mq5>

class CPositionReporter final {
   public:
    enum EnumPositionType {
        LONG = POSITION_TYPE_BUY,
        SHORT = POSITION_TYPE_SELL,
        NONE
    };

   private:
    bool m_status;
    double m_balance, m_equity, m_margin, m_price_open, m_price_current, m_volume, /*avg_volume,*/ m_profit, m_swap;

   public:
    /*void CalcLevels() const {
      for (uint i{0}; i < TradeBuilders.Size(); ++i) {
        TradeBuilders[i].CalcLevels();
      }
    }*/

    /*void UpdatePosition() {
      EnumPositionType const oldPosition{Position},
                       const newPosition{getPositionType()};
      if (oldPosition != newPosition) {
        Position = newPosition;
        //price = PositionGetDouble(POSITION_PRICE_OPEN);
        //updateStatus();
        //notify();
      }
    }*/

    // void notify() {}

    /*void updateStatus() {
      if (PositionSelect(Symbol())) {
        if (PositionType == PositionGetInteger(POSITION_TYPE)) {
           status=true;
        } else {
          status=false;
        }
      } else {
        status=false;
      }
    }*/

    bool getStatus() const {
        return PositionsTotal() && PositionSelect(Symbol()) && HistorySelectByPosition(PositionGetInteger(POSITION_TICKET));
    }

    /*void setPrice() {
      if (status) {
        price = PositionGetDouble(POSITION_PRICE_OPEN);
      }
    }*/

    double getBalance() const { return m_balance; }

    double getEquity() const { return m_equity; }

    double getMargin() const { return m_margin; }

    double getProfit() const { return m_profit; }

    double getSwap() const { return m_swap; }

    double getPriceOpen() const { return m_price_open; }

    double getPriceCurrent() const { return m_price_current; }

    double getVolume() const {
        return m_volume;
    }

    // double getAvgVolume() const { return avg_volume; }

    /*double getVolume() const {
      if (status) {
        return PositionGetDouble(POSITION_VOLUME);
      } else {
        return SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
      }
    }*/

    // AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE)

    // private:
    EnumPositionType getPositionType() {
        /*if (PositionsTotal()) {
            m_balance = AccountInfoDouble(ACCOUNT_BALANCE) / PositionsTotal();
            m_equity = AccountInfoDouble(ACCOUNT_EQUITY) / PositionsTotal();
            m_margin = AccountInfoDouble(ACCOUNT_MARGIN) / PositionsTotal();
        }
        else {
            m_balance = AccountInfoDouble(ACCOUNT_BALANCE);
            m_equity = AccountInfoDouble(ACCOUNT_EQUITY);
            m_margin = AccountInfoDouble(ACCOUNT_MARGIN);
        }*/

        if (getStatus()) {
            m_status = true;

            m_balance = AccountInfoDouble(ACCOUNT_BALANCE) / PositionsTotal();
            m_equity = AccountInfoDouble(ACCOUNT_EQUITY) / PositionsTotal();
            m_margin = AccountInfoDouble(ACCOUNT_MARGIN) / PositionsTotal();

            m_price_open = PositionGetDouble(POSITION_PRICE_OPEN);
            m_price_current = PositionGetDouble(POSITION_PRICE_CURRENT);
            m_volume = PositionGetDouble(POSITION_VOLUME);  // / HistoryDealsTotal();
            // PrintFormat("%s %f", __FUNCTION__, m_volume);

            // avg_volume = volume / HistoryDealsTotal();
            m_profit = PositionGetDouble(POSITION_PROFIT);
            m_swap = PositionGetDouble(POSITION_SWAP);

            return EnumPositionType(PositionGetInteger(POSITION_TYPE));
        } else {
            m_status = false;

            m_balance = AccountInfoDouble(ACCOUNT_BALANCE);
            m_equity = AccountInfoDouble(ACCOUNT_EQUITY);
            m_margin = AccountInfoDouble(ACCOUNT_MARGIN);

            double const zero{0};
            m_price_open = zero / zero;
            m_price_current = zero / zero;
            m_volume = Volumes.VolumeMin;
            // avg_volume = volume;
            m_profit = zero / zero;
            m_swap = zero / zero;

            return EnumPositionType::NONE;
        }
    }
};