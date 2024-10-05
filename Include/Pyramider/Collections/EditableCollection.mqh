// ###<Experts/Pyramider.mq5>
#include <Pyramider/Actions/ClampNotionalRatio.mqh>
#include <Pyramider/Actions/ClampPrice.mqh>
#include <Pyramider/Actions/ClampPriceRatio.mqh>
#include <Pyramider/Actions/ClampRestricted.mqh>
#include <Pyramider/Actions/ClampVolume.mqh>
#include <Pyramider/Objects/ChangeButton.mqh>

template <typename ExtremumType>
class CEditableCollection final {
   public:
    template <typename ChangeButtonType>
    class CPair final {
        CEditableObject const *const EditableObject;
        ChangeButtonType const *const ChangeButton;

       public:
        CPair(CEditableObject const &editable_object, ChangeButtonType const &change_button)
            : EditableObject(&editable_object), ChangeButton(&change_button) {}

        void onButton() const {
            EditableObject.onButton(ChangeButton.Parameters.Operation);
            ChangeButton.Unset();
        }
    };

   private:
    CPositionReporter *PositionReporter;
    CEditableObject *Edits[5];
    CHashMap<string, CEditableObject *> *const MapEdit;
    CHashMap<string, CPair<ChangeButton<ParametersStandard>> *> *const ValueUp;
    CHashMap<string, CPair<ChangeButton<ParametersShifted>> *> *const ValueDown;

   public:
    CEditableCollection(CProportionsManager const &proportions_manager, CPositionReporter &position_reporter, ENUM_POSITION_TYPE const position_type, CTradeBuilder<ExtremumType> const &trade_builder)
        : PositionReporter(&position_reporter),
          MapEdit(new CHashMap<string, CEditableObject *>),
          ValueUp(new CHashMap<string, CPair<ChangeButton<ParametersStandard>> *>),
          ValueDown(new CHashMap<string, CPair<ChangeButton<ParametersShifted>> *>) {
        uint const
            price_digits{uint(ceil(fabs(log10(Point() / (position_type == POSITION_TYPE_BUY ? SymbolInfoDouble(Symbol(), SYMBOL_BID) : SymbolInfoDouble(Symbol(), SYMBOL_ASK))))))},
            volume_digits{uint(ceil(fabs(log10(g_volumes.m_volume_min))))},
            notional_digits{3},
            restricted_digits{0};

        Edits[0] = new CEditableObject(proportions_manager, new ClampPrice<ExtremumType>(position_type), 2, position_type, "Price", Digits(), true);
        Edits[1] = new CEditableObject(proportions_manager, new ClampPriceRatio(position_type), 5, position_type, "PriceRatio", price_digits, true);
        Edits[2] = new CEditableObject(proportions_manager, new ClampVolume(position_reporter), 8, position_type, "VolumeInit", volume_digits, true);
        Edits[3] = new CEditableObject(proportions_manager, new ClampNotionalRatio(), 11, position_type, "NotionalRatio", notional_digits, true);
        Edits[4] = new CEditableObject(proportions_manager, new ClampRestricted<ExtremumType>(trade_builder), 16, position_type, "RestrictedTrades", restricted_digits, true);

        for (uint i{0}; i < Edits.Size(); ++i) {
            MapEdit.Add(Edits[i].m_name, Edits[i]);
            ValueUp.Add(Edits[i].ValueUp.m_name, new CPair<ChangeButton<ParametersStandard>>(Edits[i], Edits[i].ValueUp));
            ValueDown.Add(Edits[i].ValueDown.m_name, new CPair<ChangeButton<ParametersShifted>>(Edits[i], Edits[i].ValueDown));
        }
    }

    ~CEditableCollection() {
        CKeyValuePair<string, CEditableObject *> *Edit[];
        MapEdit.CopyTo(Edit);
        for (uint i{0}; i < Edit.Size(); ++i) {
            delete Edit[i].Value();
            delete Edit[i];
        }
        delete MapEdit;

        CKeyValuePair<string, CPair<ChangeButton<ParametersStandard>> *> *PairsUp[];
        ValueUp.CopyTo(PairsUp);
        for (uint i{0}; i < PairsUp.Size(); ++i) {
            delete PairsUp[i].Value();
            delete PairsUp[i];
        }
        delete ValueUp;

        CKeyValuePair<string, CPair<ChangeButton<ParametersShifted>> *> *PairsDown[];
        ValueDown.CopyTo(PairsDown);
        for (uint i{0}; i < PairsDown.Size(); ++i) {
            delete PairsDown[i].Value();
            delete PairsDown[i];
        }
        delete ValueDown;
    }

    CEditableObject *const operator[](uint const index) const { return Edits[index]; }

    /*void Draw() {
        if (!PositionReporter.getStatus()) {
            Edits[0].Draw();
            Edits[2].Draw();
        }

        // Edits[1].Draw();
        // Edits[3].Draw();
        //  Edits[4].Draw();
    }*/

    void UpdatePosition() {
        Edits[0].UpdatePosition();
        Edits[1].UpdatePosition();
        Edits[2].UpdatePosition();
        Edits[3].UpdatePosition();
        Edits[4].UpdatePosition();
    }

    void Hide() {
        for (uint i{0}; i < Edits.Size(); ++i)
            Edits[i].Hide();
    }

    bool onEdit(string const &sparam) const {
        CEditableObject *EditableObject;
        if (MapEdit.TryGetValue(sparam, EditableObject)) {
            EditableObject.onEdit();
            return true;
        }
        return false;
    }

    bool onButton(string const &sparam) const {
        CPair<ChangeButton<ParametersStandard>> *PairUp;
        if (ValueUp.TryGetValue(sparam, PairUp)) {
            PairUp.onButton();
            return true;
        }

        CPair<ChangeButton<ParametersShifted>> *PairDown;
        if (ValueDown.TryGetValue(sparam, PairDown)) {
            PairDown.onButton();
            return true;
        }

        return false;
    }
};