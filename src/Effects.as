bool e_JitterActive = false;
bool e_DissociateNew = false;

int NbEffectsActive() {
    int ret = 0;
    if (e_JitterActive) ret++;
    if (e_DissociateNew) ret++;
    return ret;
}


void DrawItemEffects() {
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
        RefreshItemPosRot();
    }
    UI::Separator();
    jitterPos = UI::Checkbox("Apply Position Jitter", jitterPos);
    AddSimpleTooltip("Apply a randomization to placed items' locations");
    jitterPosOffset = UI::InputFloat3("Position Offset", jitterPosOffset);
    AddSimpleTooltip("Offset applied to position before jitter.");
    jitterPosAmt = UI::InputFloat3("Position Radius Jitter", jitterPosAmt);
    AddSimpleTooltip("Position will have a random amount added to it, up to +/- the amount specified.");
    // jitterPosSin = UI::Checkbox("Position Jitter - Sine Wave", jitterPosSin);
    // AddSimpleTooltip("Sine wave profile will be applied. More items will be clustered around the center.\n(Theta offset = 90, so technically cosine but yeah.)");
    UI::Separator();
    jitterRot = UI::Checkbox("Apply Rotation Jitter", jitterRot);
    AddSimpleTooltip("Apply a randomization to placed items' rotations");
    jitterRotAmt = UI::InputFloat3("Rotation Jitter", jitterRotAmt);
    AddSimpleTooltip("Rotation will have a random amount added to it, up to +/- the amount specified in radians.\nDefault limits: -3.141 to 3.141 (which is -180 deg to 180 deg)");
}

void ToggleJitter() {
    e_JitterActive = !e_JitterActive;
    if (e_JitterActive) {
        startnew(JitterWatcher);
    }
}

void JitterWatcher() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    auto nbItems = editor.Challenge.AnchoredObjects.Length;
    while (e_JitterActive) {
        yield();
        @editor = cast<CGameCtnEditorFree>(GetApp().Editor);
        if (editor is null) break;
        if (nbItems != editor.Challenge.AnchoredObjects.Length) {
            // bool newItems = editor.Challenge.AnchoredObjects.Length > nbItems;
            auto prevNb = nbItems;
            nbItems = editor.Challenge.AnchoredObjects.Length;
            // should exit early if prevNb > nbItems -- i.e., an item was deleted;
            for (uint i = prevNb; i < editor.Challenge.AnchoredObjects.Length; i++) {
                auto item = editor.Challenge.AnchoredObjects[i];
                ApplyJitter(item);
                if (i % 1000 == 0) yield();
            }
        }
    }
    e_JitterActive = false;
}

// void ApplyJitter(CGameCtnAnchoredObject@ item) {
void ApplyJitter(ref@ _r) {
    CGameCtnAnchoredObject@ item = cast<CGameCtnAnchoredObject>(_r);
    print('jittering: ' + item.ItemModel.Name);
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
    // item.IsLocationInitialised = false;
    // sleep(1000);
    // item.IsLocationInitialised = true;

}
