// ###<Experts/Pyramider.mq5>

#include <Pyramider/Collections/PeriodCollection.mqh>

class CProportionsManager final {
    uint const m_size;
    double const m_proportion_x, const m_proportions_y;

    long m_chart_heigth_pixels, m_chart_width_pixels;

   public:
    uint button_width_pixels, button_height_pixels, start_pixel;

    CProportionsManager(uint const size, double const proportions_x, double const proportions_y)
        : m_proportion_x(proportions_x), m_proportions_y(proportions_y), m_size(size), m_chart_heigth_pixels(LONG_MIN), m_chart_width_pixels(LONG_MIN) {}

    bool IsProportionsChanged() const {
        return m_chart_heigth_pixels != ChartGetInteger(ChartID(), CHART_HEIGHT_IN_PIXELS) || m_chart_width_pixels != ChartGetInteger(ChartID(), CHART_WIDTH_IN_PIXELS);
    }

    void UpdateProportions() {
        m_chart_heigth_pixels = ChartGetInteger(ChartID(), CHART_HEIGHT_IN_PIXELS);
        m_chart_width_pixels = ChartGetInteger(ChartID(), CHART_WIDTH_IN_PIXELS);

        button_width_pixels = uint(round(m_proportion_x * m_chart_width_pixels));
        button_height_pixels = uint(round(m_proportions_y * m_chart_heigth_pixels));
        start_pixel = uint(round((m_chart_width_pixels - m_size * button_width_pixels) / 2));
    }
};
