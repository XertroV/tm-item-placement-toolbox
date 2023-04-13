void UpdateEditorWatchers() {
    if (S_CopyPickedItemRotation) CheckForPickedItem_CopyRotation();
    if (g_UseSnappedLoc) EnsureSnappedLoc();
}







void RefreshItemPosRot() {
    // very hacky method: cut the whole map and ctrl+z it.
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto editor = cast<CGameCtnEditorFree>(app.Editor);
    // save and restore item placement mode
    auto mode = GetItemPlacementMode();
    // don't do anything if we're not in an item mode
    if (mode == ItemMode::None) return;
    /* alt impl -- much slower than sweep objects
    // editor.ButtonSelectionBoxSelectAllOnClick();
    // editor.PluginMapType.CopyPaste_Cut();
    // editor.PluginMapType.Undo();
    */
    editor.SweepObjectsAndSave();
    editor.PluginMapType.Undo();
    SetItemPlacementMode(mode);
}


enum ItemMode {
    None = 0,
    Normal = 1,
    FreeGround = 2,
    Free = 3
}

ItemMode GetItemPlacementMode() {
    try {
        auto root = cast<CGameCtnEditorFree>(GetApp().Editor).EditorInterface.InterfaceRoot;
        auto main = cast<CControlFrame>(root.Childs[0]);
        auto bottomLeft = cast<CControlFrame>(main.Childs[15]);
        auto itemSubMode = cast<CControlFrame>(bottomLeft.Childs[1]);
        auto btns = cast<CControlFrame>(itemSubMode.Childs[2]);
        // ButtonSubModeNormalItem
        if (cast<CControlButton>(btns.Childs[0]).IsSelected) return ItemMode::Normal;
        // ButtonSubModeFreeGroundItem
        if (cast<CControlButton>(btns.Childs[1]).IsSelected) return ItemMode::FreeGround;
        // ButtonSubModeFreeItem
        if (cast<CControlButton>(btns.Childs[2]).IsSelected) return ItemMode::Free;
    } catch {
        trace("Exception getting item placement mode: " + getExceptionInfo());
    }
    return ItemMode::None;
}

void SetItemPlacementMode(ItemMode mode) {
    try {
        auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
        if (mode == ItemMode::Normal)
            editor.ButtonNormalItemModeOnClick();
        if (mode == ItemMode::FreeGround)
            editor.ButtonFreeGroundItemModeOnClick();
        if (mode == ItemMode::Free)
            editor.ButtonFreeItemModeOnClick();
    } catch {
        warn("exception setting item placement mode: " + getExceptionInfo());
    }
}
