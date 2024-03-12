// ###<Experts/Pyramider.mq5>

typedef double (*PtrConvert)(double const quote1, double const quote2);
double NoConvert(double const quote1, double const quote2) { return quote1; }
double ForwardConvert(double const quote1, double const quote2) { return quote1 * quote2; }
double BackwardConvert(double const quote1, double const quote2) { return quote1 / quote2; }

class CSubConverter final {
   private:
    string const m_symbol_pair;
    PtrConvert const Forward, const Backward;

   public:
    CSubConverter() : m_symbol_pair(""), Forward(NoConvert), Backward(NoConvert) {}
    CSubConverter(string const symbol_pair) : m_symbol_pair(symbol_pair), Forward(ForwardConvert), Backward(BackwardConvert) {}

    double ConvertForward(double const quote, ENUM_SYMBOL_INFO_DOUBLE const type) const {
        return Forward(quote, SymbolInfoDouble(m_symbol_pair, type));
    }

    double ConvertBackward(double const quote, ENUM_SYMBOL_INFO_DOUBLE const type) const {
        return Backward(quote, SymbolInfoDouble(m_symbol_pair, type));
    }
};

class CConverter final {
   private:
    CSubConverter const *const Arbiter, const *const Deposit;

   public:
    CConverter(string const quote, string const middle, string const account)
        : Arbiter(quote == middle ? new CSubConverter() : new CSubConverter(quote + middle)),
          Deposit(account == middle ? new CSubConverter() : new CSubConverter(account + middle)) {
    }

    ~CConverter() {
        delete Arbiter;
        delete Deposit;
    }

    double QuoteToArbiter(double const quote, ENUM_SYMBOL_INFO_DOUBLE const type) const {
        return Arbiter.ConvertForward(quote, type);
    }

    double ArbiterToDeposit(double const quote, ENUM_SYMBOL_INFO_DOUBLE const type) const {
        return Deposit.ConvertBackward(quote, type);
    }

    double QuoteToDeposit(double const quote, ENUM_SYMBOL_INFO_DOUBLE const type) const {
        return Deposit.ConvertBackward(Arbiter.ConvertForward(quote, type), type);
    }

    double DepositToQuote(double const quote, ENUM_SYMBOL_INFO_DOUBLE const type) const {
        return Arbiter.ConvertBackward(Deposit.ConvertForward(quote, type), type);
    }
};