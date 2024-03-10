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
    double m_balance, m_equity, margin, price, volume, /*avg_volume,*/ profit, swap;

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

    bool getStatus() const { return m_status; }

    /*void setPrice() {
      if (status) {
        price = PositionGetDouble(POSITION_PRICE_OPEN);
      }
    }*/

    double getBalance() const { return m_balance; }

    double getEquity() const { return m_equity; }

    double getMargin() const { return margin; }

    double getProfit() const { return profit; }

    double getSwap() const { return swap; }

    double getPrice() const { return price; }

    double getVolume() const { return volume; }

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
        if (PositionsTotal()) {
            m_balance = AccountInfoDouble(ACCOUNT_BALANCE) / PositionsTotal();
            m_equity = AccountInfoDouble(ACCOUNT_EQUITY) / PositionsTotal();
            margin = AccountInfoDouble(ACCOUNT_MARGIN) / PositionsTotal();
        } else {
            m_balance = AccountInfoDouble(ACCOUNT_BALANCE);
            m_equity = AccountInfoDouble(ACCOUNT_EQUITY);
            margin = AccountInfoDouble(ACCOUNT_MARGIN);
        }

        if (PositionSelect(Symbol()) && HistorySelectByPosition(PositionGetInteger(POSITION_TICKET))) {
            m_status = true;
            price = PositionGetDouble(POSITION_PRICE_OPEN);
            volume = PositionGetDouble(POSITION_VOLUME) / HistoryDealsTotal();
            // avg_volume = volume / HistoryDealsTotal();
            profit = PositionGetDouble(POSITION_PROFIT);
            swap = PositionGetDouble(POSITION_SWAP);
            return EnumPositionType(PositionGetInteger(POSITION_TYPE));
        } else {
            m_status = false;
            double const zero{0};
            price = zero / zero;
            volume = Volumes.VolumeMin;
            // avg_volume = volume;
            profit = zero / zero;
            swap = zero / zero;
            return EnumPositionType::NONE;
        }
    }
};