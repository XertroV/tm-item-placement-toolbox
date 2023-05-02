bool e_JitterActive = false;
bool e_DissociateNew = false;

int NbEffectsActive() {
    int ret = 0;
    if (e_JitterActive) ret++;
    if (e_DissociateNew) ret++;
    return ret;
}


void DrawItemEffects(CGameCtnEditorFree@ editor) {
    UI::Text("Apply effects to newly placed items");
    UI::BeginTabBar("effects");
    if (UI::BeginTabItem("Filter Items", UI::TabItemFlags::Trailing)) {
        Draw_FilterItems();
        UI::EndTabItem();
    }
    if (UI::BeginTabItem("Active Effects ("+NbEffectsActive()+")###active-eff", UI::TabItemFlags::Trailing)) {
        if (e_JitterActive) UI::Text("Jitter");
        if (e_DissociateNew) UI::Text("Dissociate New");
        UI::EndTabItem();
    }
    if (UI::BeginTabItem("Jitter")) {
        Draw_Effect_Jitter();
        UI::EndTabItem();
    }
    if (UI::BeginTabItem("Dissociate")) {
        Draw_Effect_Dissociate();
        UI::EndTabItem();
    }
    if (UI::BeginTabItem("Set BlockCoord")) {
        Draw_Effect_SetBlockCoord();
        UI::EndTabItem();
    }
    // disable this for now until better tested and refreshing working
    // if (UI::BeginTabItem("Copy Skin/Color")) {
    //     Draw_Effect_CopySkinColor(editor);
    //     UI::EndTabItem();
    // }
    UI::EndTabBar();
}



void Draw_FilterItems() {
    UI::Text("Todo, LMK if you want this.\n(Feedback helps prioritization)");
}




bool jitterPos = true;
vec3 jitterPosAmt = vec3(8, 1, 8);
vec3 jitterPosOffset = vec3(0, 0, 0);
bool jitterPosSin = false;

bool jitterRot = true;
vec3 jitterRotAmt = vec3(Math::PI);

void Draw_Effect_Jitter() {
    UI::Text("Jitter applies a random offset to position and/or rotation.");
    UI::TextWrapped("\\$f80Note!\\$z Refreshing items will not work for the most recently placed item! You must place an extra item, delete it, and then it will work as expected. You can also save and reload the map instead of using the refresh items button -- same restrictions apply.");
    UI::TextWrapped("\\$f80Note!\\$z Too much ctrl+z can undo the jitter (and a re-do is then required if jitter isn't active at the time of the undo).");
    if (UI::Button(e_JitterActive ? "Deactivate##jitter" : "Activate##jitter")) {
        ToggleJitter();
    }
    UI::SameLine();
    if (UI::Button("Refresh Items")) {
        startnew(RefreshItemPosRot);
    }
    UI::Separator();
    jitterPos = UI::Checkbox("Apply Position Jitter", jitterPos);
    AddSimpleTooltip("Apply a randomization to placed items' locations");
    jitterPosOffset = UI::InputFloat3("Position Offset", jitterPosOffset);
    AddSimpleTooltip("Offset applied to position before jitter.");
    jitterPosAmt = UI::InputFloat3("Position Radius Jitter", jitterPosAmt); // , vec3(8, 1, 8)
    AddSimpleTooltip("Position will have a random amount added to it, up to +/- the amount specified.");
    // jitterPosSin = UI::Checkbox("Position Jitter - Sine Wave", jitterPosSin);
    // AddSimpleTooltip("Sine wave profile will be applied. More items will be clustered around the center.\n(Theta offset = 90, so technically cosine but yeah.)");
    UI::Separator();
    jitterRot = UI::Checkbox("Apply Rotation Jitter", jitterRot);
    AddSimpleTooltip("Apply a randomization to placed items' rotations");
    jitterRotAmt = UI::InputAngles3("Rotation Jitter (Deg)", jitterRotAmt, vec3(Math::PI));
    AddSimpleTooltip("Rotation will have a random amount added to it, up to +/- the amount specified in radians.\nDefault limits: -3.141 to 3.141 (which is -180 deg to 180 deg)");
}

void ToggleJitter() {
    e_JitterActive = !e_JitterActive;
    // if (e_JitterActive) {
    //     startnew(JitterWatcher);
    // }
}

uint nbItems = 0;
void Jitter_CheckNewItems() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    if (editor is null) {
        e_JitterActive = false;
        return;
    }
    if (!e_JitterActive) {
        nbItems = editor.Challenge.AnchoredObjects.Length;
        return;
    }

    if (nbItems != editor.Challenge.AnchoredObjects.Length) {
        auto prevNb = nbItems;
        nbItems = editor.Challenge.AnchoredObjects.Length;
        // should exit early if prevNb > nbItems -- i.e., an item was deleted;
        for (uint i = prevNb; i < editor.Challenge.AnchoredObjects.Length; i++) {
            auto item = editor.Challenge.AnchoredObjects[i];
            ApplyJitter(item);
        }
        RefreshBlocksAndItems(editor);
    }
}

void ApplyJitter(ref@ _r) {
    CGameCtnAnchoredObject@ item = cast<CGameCtnAnchoredObject>(_r);
    print('jittering: ' + item.ItemModel.IdName);
    if (jitterPos) {
        auto _jitter = jitterPosAmt * vec3(Math::Rand(-1.0, 1.0), Math::Rand(-1.0, 1.0), Math::Rand(-1.0, 1.0));
        item.AbsolutePositionInMap += jitterPosOffset + _jitter;
        trace(_jitter.ToString());
    }
    if (jitterRot) {
        auto rotMod = jitterRotAmt * vec3(Math::Rand(-1.0, 1.0), Math::Rand(-1.0, 1.0), Math::Rand(-1.0, 1.0));
        item.Pitch += rotMod.x;
        item.Yaw += rotMod.y;
        item.Roll += rotMod.z;
        trace(rotMod.ToString());
    }
}
