void DrawMainWindowInner() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    if (editor is null) {
        UI::Text("Not in editor...");
        return;
    }
    auto curr = editor.CurrentItemModel;
    if (curr is null) {
        UI::Text("Select an item...");
        return;
    }
    UI::Text("Item: " + curr.Name);

    UI::BeginTabBar("placement tabs");
    if (UI::BeginTabItem("Placement")) {
        DrawPlacement(curr);
        UI::EndTabItem();
    }
    if (UI::BeginTabItem("Layouts")) {
        DrawLayouts(curr.DefaultPlacementParam_Content.PlacementClass);
        UI::EndTabItem();
    }
    UI::EndTabBar();
}


void DrawPlacement(CGameItemModel@ curr) {
    auto pp_content = curr.DefaultPlacementParam_Content;
    if (pp_content is null) {
        UI::Text("\\$fb4PlacementParam_Content is null!");
        return;
    }

    // main placement
    DrawMainPlacement(pp_content.PlacementClass);

    if (UI::CollapsingHeader("Advanced Placement")) {
        UI::Text("These have unknown or maybe less useful functionality. (TODO)");
        // todo
    }

}

void DrawMainPlacement(NPlugItemPlacement_SClass@ pc) {
    pc.AlwaysUp = UI::Checkbox("Always Up", pc.AlwaysUp);
    AddSimpleTooltip("When false, the item will be perpendicular to the surface.\nUseful for sloped blocks. (Default: true)");
    pc.AlignToInterior = UI::Checkbox("Align To Interior", pc.AlignToInterior);
    AddSimpleTooltip("When false, the item can be pre-rotated\n(before snapping) to get different alignments.\n(Default: true)");
    pc.AlignToWorldDir = UI::Checkbox("Align To World Dir", pc.AlignToWorldDir);
    AddSimpleTooltip("When true, items will always face this direction. (Default: false)");
    pc.WorldDir = UI::InputFloat3("World Dir", pc.WorldDir);
    AddSimpleTooltip("Vector of the direction to face. Y=Up. (Default: 0,0,1)");
}

void DrawLayouts(NPlugItemPlacement_SClass@ pc) {
    /**
     * ix=3 of pc.GroupCurPatchLayouts seems to be the active layout. all the rest seem the same
     */
    // UI::Text("Nb Layouts: " + pc.GroupCurPatchLayouts.Length);
    UI::Text("Nb Layouts: " + pc.PatchLayouts.Length + " (Not all will be available.)");
    if (pc.PatchLayouts.Length == 0) {
        UI::Text("Nothing to do");
        return;
    }
    auto activeIx = pc.GroupCurPatchLayouts.Length >= 4 ? pc.GroupCurPatchLayouts[3] : 0;
    UI::Text("Current Layout: ("+activeIx+")");
    AddSimpleTooltip("Note: this might not always be accurate. Please report bugs.");
    DrawLayoutOpts(pc.PatchLayouts[activeIx], activeIx, true);
    UI::Separator();
    for (uint i = 0; i < pc.PatchLayouts.Length; i++) {
        DrawLayoutOpts(pc.PatchLayouts[i], i);
    }
}

void DrawLayoutOpts(NPlugItemPlacement_SPatchLayout@ layout, uint i, bool skipHeader = false) {
    if (skipHeader || UI::CollapsingHeader("Layout " + i)) {
        UI::PushID(layout);

        UI::AlignTextToFramePadding();
        UI::Text("Fill Dir: " + tostring(layout.FillDir));
        UI::SameLine();
        if (UI::Button("Swap")) {
            layout.FillDir = layout.FillDir == EFillDir::U ? EFillDir::V : EFillDir::U;
        }

        layout.ItemCount = UI::SliderInt("Item Count", layout.ItemCount, 0, 20);
        AddSimpleTooltip("Ctrl-click to set higher values. (You might need to increase spacing, too)\n0 = as many as possible with the current spacing.");

        layout.ItemSpacing = UI::SliderFloat("Item Spacing", layout.ItemSpacing, 0., 16., "%.0f");

        if (UI::BeginCombo("Fill Align", tostring(layout.FillAlign))) {
            if (UI::Selectable(tostring(EAlign::Center), layout.FillAlign == EAlign::Center)) layout.FillAlign = EAlign::Center;
            if (UI::Selectable(tostring(EAlign::Begin), layout.FillAlign == EAlign::Begin)) layout.FillAlign = EAlign::Begin;
            if (UI::Selectable(tostring(EAlign::End), layout.FillAlign == EAlign::End)) layout.FillAlign = EAlign::End;
            UI::EndCombo();
        }

        layout.FillBorderOffset = UI::SliderFloat("Fill Border Offset", layout.FillBorderOffset, 0., 32.);
        AddSimpleTooltip("Space from beginning/end that gets skipped before starting the layout.");

        layout.Altitude = UI::SliderFloat("Altitude", layout.Altitude, -16., 16.);

        layout.NormedPos = UI::SliderFloat("Normed Pos", layout.NormedPos, 0., 1.);
        AddSimpleTooltip("Unknown purpose. Possibly sets the 'center' position of the item relative to its width.");

        layout.DistFromNormedPos = UI::SliderFloat("Dist from Normed Pos", layout.DistFromNormedPos, -32., 32.);
        AddSimpleTooltip("Offset layout (Can be used to make a narrow path using edge arrow signs, for example.)");

        UI::PopID();
    }
}
