string lastItemName;
bool itemChanged = false;
CGameItemModel@ currentItem = null;

void DrawMainWindowInner() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    if (editor is null) {
        UI::Text("Not in editor...");
        return;
    }
    @currentItem = editor.CurrentItemModel;
    if (currentItem is null) {
        UI::Text("Select an item...");
        if (lastItemName.Length > 0) {
            lastItemName = "";
            OnItemChanged();
        }
        return;
    }
    if (lastItemName != string(currentItem.Name)) {
        lastItemName = currentItem.Name;
        OnItemChanged();
    }
    UI::Text("Item: " + currentItem.Name);

    UI::BeginTabBar("placement tabs");
    if (UI::BeginTabItem("Placement")) {
        DrawPlacement(currentItem);
        UI::EndTabItem();
    }
    if (UI::BeginTabItem("Layouts")) {
        DrawLayouts(currentItem.DefaultPlacementParam_Content.PlacementClass);
        UI::EndTabItem();
    }

    if (UI::BeginTabItem("Custom Item Layouts")) {
        DrawCustomItemLayouts();
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

    DrawMagnetOptions();

    UI::Separator();
    UI::AlignTextToFramePadding();
    UI::Text("General Placement Params");
    pp_content.GridSnap_HStep = UI::InputFloat("GridSnap_HStep", pp_content.GridSnap_HStep, 0.01);
    AddSimpleTooltip("Decrease to make item placement more precise in the XZ plane. \\$s\\$fb0Item Mode Only!\\$z\nDefault: 1.0 (usually).");
    pp_content.GridSnap_VStep = UI::InputFloat("GridSnap_VStep", pp_content.GridSnap_VStep, 0.01);
    AddSimpleTooltip("Unknown or untested.\n Default?: 0.0 (some items may differ)");
    pp_content.GridSnap_HOffset = UI::InputFloat("GridSnap_HOffset", pp_content.GridSnap_HOffset, 0.01);
    AddSimpleTooltip("Unknown or untested.\n Default?: 0.0 (some items may differ)");
    pp_content.GridSnap_VOffset = UI::InputFloat("GridSnap_VOffset", pp_content.GridSnap_VOffset, 0.01);
    AddSimpleTooltip("Unknown or untested.\n Default?: 0.0 (some items may differ)");
    pp_content.PivotSnap_Distance = UI::InputFloat("PivotSnap_Distance", pp_content.PivotSnap_Distance, 0.01);
    AddSimpleTooltip("Unknown or untested.\n Defaults?: -1.0, 0.0 (some items may differ)");

    // todo: more

    UI::Text("\\$888Note: still more properties can be added.");
}

void DrawMagnetOptions() {
    if (UI::CollapsingHeader("Item to Item Snaping")) {
        auto ef = cast<CGameCtnEditorFree>(GetApp().Editor).ExperimentalFeatures;
        ef.MagnetSnapDistance = UI::SliderFloat("Item Snap Dist.", ef.MagnetSnapDistance, 0., 64.);
        AddSimpleTooltip("Default: 1.25");
        ef.ShowMagnetsInItemCursor = UI::Checkbox("Show Item Magnet Points", ef.ShowMagnetsInItemCursor);
        AddSimpleTooltip("Similar to block connection indicators for items that snap together.");
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

int activeIx = -1;

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
    string LayoutsStr;
    bool shouldSetActiveIx = activeIx < 0;
    if (shouldSetActiveIx)
        activeIx = 0;
    if (pc.GroupCurPatchLayouts.Length > 0) {
        if (shouldSetActiveIx)
            activeIx = pc.GroupCurPatchLayouts[0];
        bool hasSet = false;
        for (uint i = 0; i < pc.GroupCurPatchLayouts.Length; i++) {
            if (shouldSetActiveIx && pc.GroupCurPatchLayouts[i] != 0 && !hasSet) {
                // activeIx = pc.GroupCurPatchLayouts[i];
                activeIx = i;
                hasSet = true;
            }
            LayoutsStr += (i > 0 ? "," : "") + pc.GroupCurPatchLayouts[i];
        }
    }
    UI::Text("Current Layout: ("+activeIx+"); GCPLs: " + LayoutsStr);
    AddSimpleTooltip("When you cycle through layouts (right click) one of\nthese numbers will change. This tells you the layout index.");
    activeIx = Math::Clamp(UI::InputInt("Active Layout Index", activeIx, 1), 0, pc.PatchLayouts.Length);
    AddSimpleTooltip("Note: Set this manually -- the active layout\nis often the only non-zero number in GCPLs");
    DrawLayoutOpts(pc.PatchLayouts[activeIx], activeIx, true);
    UI::Separator();
    UI::AlignTextToFramePadding();
    UI::Text("All Layouts: \\$888Some of these are likely inaccessible.");
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

void OnItemChanged() {
    activeIx = -1;
    ResetTmpPlacement();
}

void ResetTmpPlacement() {
    if (TmpPlacementParam !is null && TmpItemPlacementReplaced !is null) {
        @TmpItemPlacementReplaced.DefaultPlacementParam_Content = TmpPlacementParam;
        TmpPlacementParam.MwRelease();
        TmpItemPlacementReplaced.MwRelease();
    }
    @TmpPlacementParam = null;
    @TmpItemPlacementReplaced = null;
}

CGameItemPlacementParam@ TmpPlacementParam = null;
CGameItemModel@ TmpItemPlacementReplaced = null;

string[] SampleGameItemNames = {"Flag8m", "Screen2x1Small", "RoadSign", "Lamp", "LightTubeSmall8m", "TunnelSupportArch8m", "ObstaclePillar2m", "CypressTall", "CactusMedium", "CactusVerySmall"};

bool appliedCustomItemLayout = false;

void DrawCustomItemLayouts() {
    UI::TextWrapped("Custom items can be used with layouts by temporary replacing the custom item's layout with one from a Nadeo object (e.g., flags, or signs). However, you cannot save the map until the custom item's original layout is restored. Test this in a new map first to get a feel for it since it might be a little dangerous.");
    UI::TextWrapped("\\$fa0Note! The item's original placement options/layouts will be set back to normal automatically when the current item changes.");
    UI::TextWrapped("\\$fa0Warning! \\$zGame crashes may occur (though they shouldn't) -- after you are done using this tool, I suggest you save the map and reload it.");
    if (currentItem is null) {
        UI::Text("Choose an item.");
    } else if (TmpPlacementParam is null) {
        UI::AlignTextToFramePadding();
        UI::Text("Replace layout of " + currentItem.Name);
        for (uint i = 0; i < SampleGameItemNames.Length; i++) {
            if (UI::Button("With layout from " + SampleGameItemNames[i])) {
                SetCustomPlacementParams(SampleGameItemNames[i]);
            }
        }
    } else {
        UI::TextWrapped("Edit the layout in the layout tab and try placing the item on the edge of blocks, etc.");
        if (UI::Button("Restore original layouts")) {
            ResetTmpPlacement();
            appliedCustomItemLayout = true;
        }
        UI::TextWrapped("\\$fa0 Warning! You MUST click this before changing items or your game will crash!");
    }

}

void SetCustomPlacementParams(const string &in nadeoItemName) {
    if (TmpPlacementParam !is null) {
        NotifyWarning("Tried to overwrite a tmp placement params! Refusing to do this.");
        return;
    }
    auto item = FindItemByName(nadeoItemName);
    if (item !is null) {
        @TmpPlacementParam = currentItem.DefaultPlacementParam_Content;
        @TmpItemPlacementReplaced = currentItem;
        TmpItemPlacementReplaced.MwAddRef();
        TmpPlacementParam.MwAddRef();
        @currentItem.DefaultPlacementParam_Content = item.DefaultPlacementParam_Content;
        // to inspect refcounts and things -- and yeah, if we don't add a ref and release it later then the placement params go null and we get a crash.
        // ExploreNod(TmpPlacementParam);
        // ExploreNod(TmpItemPlacementReplaced);
    } else {
        NotifyWarning("Could not find item: " + nadeoItemName);
    }
}

// do not yeild
CGameItemModel@ FindItemByName(const string &in name) {
    auto itemsCatalog = GetApp().GlobalCatalog.Chapters[3];
    for (int i = itemsCatalog.Articles.Length - 1; i > 1; i--) {
        auto item = itemsCatalog.Articles[i];
        if (item.Name == name) {
            if (item.LoadedNod is null) {
                item.Preload();
            }
            return cast<CGameItemModel>(item.LoadedNod);
        }
    }
    return null;
}
