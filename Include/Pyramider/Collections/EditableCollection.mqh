// ###<Experts/Pyramider.mq5>

#include <Pyramider/Actions/ClampPrice.mqh>
#include <Pyramider/Actions/ClampPriceRatio.mqh>
#include <Pyramider/Actions/ClampRestricted.mqh>
#include <Pyramider/Actions/ClampValue.mqh>
#include <Pyramider/Actions/ClampVolumeInit.mqh>
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

        void ChangeValue() const {
            EditableObject.changeValue(ChangeButton.Parameters.Operation);
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
    CEditableCollection(CProportionsManager const &proportions_manager, CPositionReporter &position_reporter, ENUM_POSITION_TYPE const position_type, double const notional_ratio, CTradeBuilder<ExtremumType> const &trade_builder)
        : PositionReporter(&position_reporter),
          MapEdit(new CHashMap<string, CEditableObject *>),
          ValueUp(new CHashMap<string, CPair<ChangeButton<ParametersStandard>> *>),
          ValueDown(new CHashMap<string, CPair<ChangeButton<ParametersShifted>> *>) {
        Edits[0] = new CEditableObject(proportions_manager, new ClampPrice<ExtremumType>(position_type, 1 /*+ (position_type == POSITION_TYPE_BUY ? -0.05 : +0.05)*/), 2, position_type, "Price", Digits());
        Edits[1] = new CEditableObject(proportions_manager, new ClampPriceRatio(position_type, 1 /*+ (position_type == POSITION_TYPE_BUY ? -0.05 : 0.05)*/), 5, position_type, "PriceRatio", uint(-round(log10(Point() / (position_type == POSITION_TYPE_BUY ? SymbolInfoDouble(Symbol(), SYMBOL_BID) : SymbolInfoDouble(Symbol(), SYMBOL_ASK))))));
        Edits[2] = new CEditableObject(proportions_manager, new ClampVolumeInit(position_reporter), 8, position_type, "VolumeInit", uint(-log10(Volumes.VolumeMin)));
        Edits[3] = new CEditableObject(proportions_manager, new ClampValue(notional_ratio, 1, DBL_MAX), 11, position_type, "NotionalRatio", NotionalRatioDigits);
        Edits[4] = new CEditableObject(proportions_manager, new ClampRestricted<ExtremumType>(trade_builder), 18, position_type, "RestrictedTrades", 0);

        for (uint i{0}; i < Edits.Size(); ++i) {
            MapEdit.Add(Edits[i].name, Edits[i]);
            ValueUp.Add(Edits[i].ValueUp.name, new CPair<ChangeButton<ParametersStandard>>(Edits[i], Edits[i].ValueUp));
            ValueDown.Add(Edits[i].ValueDown.name, new CPair<ChangeButton<ParametersShifted>>(Edits[i], Edits[i].ValueDown));
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

    void Draw() {
        Edits[0].Draw();
        Edits[1].Draw();
        Edits[2].Draw();
        Edits[3].Draw();
    }

    void Hide() {
        for (uint i{0}; i < Edits.Size(); ++i)
            Edits[i].Hide();
    }

    bool ProcessEdit(string const &sparam) const {
        CEditableObject *EditableObject;
        if (MapEdit.TryGetValue(sparam, EditableObject)) {
            EditableObject.editValue();
            return true;
        }
        return false;
    }

    bool ChangeEdit(string const &sparam) const {
        CPair<ChangeButton<ParametersStandard>> *PairUp;
        if (ValueUp.TryGetValue(sparam, PairUp)) {
            PairUp.ChangeValue();
            return true;
        }

        CPair<ChangeButton<ParametersShifted>> *PairDown;
        if (ValueDown.TryGetValue(sparam, PairDown)) {
            PairDown.ChangeValue();
            return true;
        }

        return false;
    }
};