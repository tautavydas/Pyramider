// ###<Experts/Pyramider.mq5>

#include <Pyramider/Collections/PeriodCollection.mqh>

class CProportionsManager final {
    uint const m_size;
    double const m_xProportions, const m_yProportions;

   public:
    CProportionsManager(uint const size, double const xproportions, double const yproportions)
        : m_xProportions(xproportions), m_yProportions(yproportions), m_size(size) {}
    uint button_width_pixels, button_height_pixels, start_pixel;

    void UpdateProportions() {
        long const Height{ChartGetInteger(ChartID(), CHART_HEIGHT_IN_PIXELS)};
        long const Width{ChartGetInteger(ChartID(), CHART_WIDTH_IN_PIXELS)};
        button_width_pixels = uint(round(m_xProportions * Width));
        button_height_pixels = uint(round(m_yProportions * Height));
        start_pixel = uint(round((Width - m_size * button_width_pixels) / 2));
    }
};