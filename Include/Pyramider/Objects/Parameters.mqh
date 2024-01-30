// ###<Experts/Pyramider.mq5>

typedef double (*OperationPtr)(double const, double const);
double Add(double const op1, double const op2) { return op1 + op2; }
double Sub(double const op1, double const op2) { return op1 - op2; }

class Parameters {
   protected:
    CProportionsManager const* const ProportionsManager;
    uint const coefX, const coefY, const coefW, const coefH;

   public:
    Parameters(CProportionsManager const& proportions_manager, uint const coefX_, uint const coefY_, uint const coefW_, uint const coefH_)
        : ProportionsManager(&proportions_manager), coefX(coefX_), coefY(coefY_), coefW(coefW_), coefH(coefH_) {}
    Parameters(CProportionsManager const& proportions_manager, uint const coefX_, ENUM_POSITION_TYPE const position_type, uint const coefW_, uint const coefH_)
        : ProportionsManager(&proportions_manager), coefX(coefX_), coefY(position_type == POSITION_TYPE_BUY ? 2 : 1), coefW(coefW_), coefH(coefH_) {}

    void Draw(string const name) const {
        uint const size_x{SizeX()}, const size_y{SizeY()};
        ObjectSetInteger(ChartID(), name, OBJPROP_FONTSIZE, 2 + uint(round(sqrt(sqrt(size_x * size_y)))));
        ObjectSetInteger(ChartID(), name, OBJPROP_XDISTANCE, ProportionsManager.start_pixel + CoordinateX());
        ObjectSetInteger(ChartID(), name, OBJPROP_YDISTANCE, CoordinateY());
        ObjectSetInteger(ChartID(), name, OBJPROP_XSIZE, size_x);
        ObjectSetInteger(ChartID(), name, OBJPROP_YSIZE, size_y);
    }

   private:
    uint SizeX() const { return ProportionsManager.button_width_pixels * coefW; }
    uint SizeY() const { return ProportionsManager.button_height_pixels / coefH; }
    uint CoordinateX() const { return ProportionsManager.button_width_pixels * coefX; }

   protected:
    virtual uint CoordinateY() const { return ProportionsManager.button_height_pixels * coefY; }
};

class ParametersStandard : public Parameters {
   public:
    OperationPtr const Operation;
    ParametersStandard(CProportionsManager const& proportions_manager, uint const coefX_, ENUM_POSITION_TYPE const position_type, uint const coefW_, uint const coefH_)
        : Parameters(proportions_manager, coefX_, position_type, coefW_, coefH_), Operation(Add) {}
};

class ParametersShifted final : public Parameters {
   public:
    OperationPtr const Operation;
    ParametersShifted(CProportionsManager const& proportions_manager, uint const coefX_, ENUM_POSITION_TYPE const position_type, uint const coefW_, uint const coefH_)
        : Parameters(proportions_manager, coefX_, position_type, coefW_, coefH_), Operation(Sub) {}

   private:
    uint CoordinateY() const override { return Parameters::CoordinateY() + ProportionsManager.button_height_pixels / 2; }
};