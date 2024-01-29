// ###<Experts/Pyramider.mq5>

class CPositionReporter final {
   public:
    enum EnumPositionType {
        LONG = POSITION_TYPE_BUY,
        SHORT = POSITION_TYPE_SELL,
        NONE
    };

   private:
    bool status;
    double balance, equity, margin, price, volume, avg_volume, profit, swap;

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

    bool getStatus() const { return status; }

    /*void setPrice() {
      if (status) {
        price = PositionGetDouble(POSITION_PRICE_OPEN);
      }
    }*/

    double getBalance() const { return balance; }

    double getEquity() const { return equity; }

    double getMargin() const { return margin; }

    double getProfit() const { return profit; }

    double getSwap() const { return swap; }

    double getPrice() const { return price; }

    double getVolume() const { return volume; }

    double getAvgVolume() const { return avg_volume; }

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
            balance = AccountInfoDouble(ACCOUNT_BALANCE) / PositionsTotal();
            equity = AccountInfoDouble(ACCOUNT_EQUITY) / PositionsTotal();
            margin = AccountInfoDouble(ACCOUNT_MARGIN) / PositionsTotal();
        } else {
            balance = AccountInfoDouble(ACCOUNT_BALANCE);
            equity = AccountInfoDouble(ACCOUNT_EQUITY);
            margin = AccountInfoDouble(ACCOUNT_MARGIN);
        }

        if (PositionSelect(Symbol()) && HistorySelectByPosition(PositionGetInteger(POSITION_TICKET))) {
            status = true;
            price = PositionGetDouble(POSITION_PRICE_OPEN);
            volume = PositionGetDouble(POSITION_VOLUME);
            // PrintFormat("%s %u", __FUNCTION__, HistorySelectByPosition(PositionGetInteger(POSITION_TICKET)));
            avg_volume = volume / HistoryDealsTotal();
            profit = PositionGetDouble(POSITION_PROFIT);
            swap = PositionGetDouble(POSITION_SWAP);
            return EnumPositionType(PositionGetInteger(POSITION_TYPE));
        } else {
            status = false;
            double const zero{0};
            price = zero / zero;
            volume = Volumes.VolumeMin;  // SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
            avg_volume = zero / zero;
            profit = zero / zero;
            swap = zero / zero;
            return EnumPositionType::NONE;
        }
    }
};