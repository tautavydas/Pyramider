// ###<Experts/Pyramider.mq5>

class IAction {
   public:
    virtual double onInit() const = 0;
    virtual double onButton(double const) const = 0;
    virtual double onTick(double const) const = 0;
};
