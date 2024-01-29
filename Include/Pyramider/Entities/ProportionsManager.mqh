// ###<Experts/Pyramider.mq5>

#include <Pyramider/Collections/PeriodCollection.mqh>

class CProportionsManager final {
   public:
    CProportionsManager() {}
    uint button_width_pixels,
        button_height_pixels, start_pixel;

    void UpdateProportions(uint const size) {
        long const Height{ChartGetInteger(ChartID(), CHART_HEIGHT_IN_PIXELS)};
        long const Width{ChartGetInteger(ChartID(), CHART_WIDTH_IN_PIXELS)};
        button_width_pixels = uint(round(Xproportions * Width));
        button_height_pixels = uint(round(Yproportions * Height));
        start_pixel = uint(round((Width - size * button_width_pixels) / 2));
    }
};