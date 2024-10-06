// ###<Experts/Pyramider.mq5>
#include <Pyramider/Actions/IAction.mqh>
#include <Pyramider/Objects/Parameters.mqh>

class CEditableObject final : public IDrawable {
    color const m_border_color;
    double const m_step;
    bool m_initialized;

   public:
    IAction const *const Action;
    Parameters *const Params;
    ChangeButton<ParametersStandard> *const ValueUp;
    ChangeButton<ParametersShifted> *const ValueDown;
    uint const m_digits;
    bool const m_save_last_value;
    CEditableObject(CProportionsManager const &proportions_manager, IAction const &action, uint const coefX, ENUM_POSITION_TYPE const position_type, string const name_, uint const digits, bool const save_last_value)
        : IDrawable(OBJ_EDIT, (position_type == POSITION_TYPE_BUY ? "Long" : "Short") + name_, name_, position_type == POSITION_TYPE_BUY ? clrBlue : clrRed, clrLightGray),
          m_border_color(clrGray),
          m_step(pow(10.0, -double(digits))),
          m_initialized(false),
          Action(&action),
          Params(new Parameters(proportions_manager, coefX, position_type, 2, 1)),
          ValueUp(new ChangeButton<ParametersStandard>(proportions_manager, coefX, position_type, m_name)),
          ValueDown(new ChangeButton<ParametersShifted>(proportions_manager, coefX, position_type, m_name)),
          m_digits(digits),
          m_save_last_value(save_last_value) {}

    ~CEditableObject() {
        Hide();
        delete Action;
        delete Params;
        delete ValueUp;
        delete ValueDown;
    }

    void UpdatePosition() {
        Params.UpdateCoordinates();
        ValueUp.UpdatePosition();
        ValueDown.UpdatePosition();
    }

    void Draw() {
        IDrawable::Draw();

        ObjectSetInteger(ChartID(), m_name, OBJPROP_BORDER_COLOR, m_border_color);
        Params.SetCoordinates(m_name);
        ValueUp.DrawFresh();
        ValueDown.DrawFresh();

        if (!m_initialized) {
            if (m_save_last_value) {
                string const file_name = StringFormat("%s_%s", Symbol(), m_name);
                if (FileIsExist(file_name)) {
                    int const file_handle = FileOpen(file_name, FILE_READ | FILE_BIN);
                    if (file_handle != INVALID_HANDLE) {
                        setValue(FileReadDouble(file_handle));
                        FileClose(file_handle);
                    } else {
                        PrintFormat("Failed to open %s file for reading: %d", file_name, GetLastError());
                    }
                } else {
                    setValue(Action.onInit());
                }
            } else {
                setValue(Action.onInit());
            }

            m_initialized = true;
        }
    }

    void Hide() {
        if (m_initialized && m_save_last_value) {
            string const file_name = StringFormat("%s_%s", Symbol(), m_name);
            int const file_handle = FileOpen(file_name, FILE_WRITE | FILE_BIN);
            if (file_handle != INVALID_HANDLE) {
                FileWriteDouble(file_handle, getValue());
                FileClose(file_handle);
            } else {
                PrintFormat("Failed to open %s file for writing: %d", file_name, GetLastError());
            }
        }

        IDrawable::Hide();
        ValueUp.Hide();
        ValueDown.Hide();
        m_initialized = false;
    }

    double getValue() const {
        return StringToDouble(ObjectGetString(ChartID(), m_name, OBJPROP_TEXT));
    }

    void setValue(double const display_value) const {
        ObjectSetString(ChartID(), m_name, OBJPROP_TEXT, StringFormat("%.*f", m_digits, display_value));
    }

    /*void onTick() const {
        setText(Action.onTick(getValue()));
    }*/

    void onEdit() const {
        setValue(Action.clamp(getValue()));
    }

    void onButton(OperationPtr const &Operation) const {
        setValue(Action.clamp(Operation(getValue(), m_step)));
    }
};