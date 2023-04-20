void UpdateEditorWatchers(CGameCtnEditorFree@ editor) {
    if (S_CopyPickedItemRotation) CheckForPickedItem_CopyRotation();
    if (g_UseSnappedLoc) EnsureSnappedLoc();
    UpdatePickedItemProps();
    Jitter_CheckNewItems();
    CheckPickedForRepetitionHelper(editor);
}



void UpdateNewlyAddedItems(CGameCtnEditorFree@ editor) {
    auto pmt = cast<CSmEditorPluginMapType>(editor.PluginMapType);
    auto macroblock = pmt.GetMacroblockModelFromFilePath("Stadium\\Macroblocks\\LightSculpture\\Spring\\FlowerWhiteSmall.Macroblock.Gbx");
    trace('UpdateNewlyAddedItems macroblock is null: ' + (macroblock is null));
    auto placed = pmt.PlaceMacroblock_NoDestruction(macroblock, int3(0, 24, 0), CGameEditorPluginMap::ECardinalDirections::North);
    trace('UpdateNewlyAddedItems placed: ' + placed);
    bool removed = pmt.RemoveMacroblock(macroblock, int3(0, 24, 0), CGameEditorPluginMap::ECardinalDirections::North);
    trace('UpdateNewlyAddedItems removed: ' + removed);
}



CGameCtnAnchoredObject@ DuplicateAndAddItem(CGameCtnEditorFree@ editor, CGameCtnAnchoredObject@ origItem, bool updateItemsAfter = false) {
        auto item = CGameCtnAnchoredObject();
        auto itemTy = Reflection::GetType("CGameCtnAnchoredObject");
        auto itemModelMember = itemTy.GetMember("ItemModel");
        // trace('ItemModel offset: ' + itemModelMember.Offset);
        auto ni_ID = Dev::GetOffsetUint32(item, 0x164);

        auto lastItem = editor.Challenge.AnchoredObjects[editor.Challenge.AnchoredObjects.Length - 1];

        Dev_SetOffsetBytes(item, 0x0, Dev_GetOffsetBytes(origItem, 0x0, itemModelMember.Offset + 0x8));
        item.IsFlying = true;
        item.ItemModel.MwAddRef();
        editor.Challenge.AnchoredObjects.Add(item);

        auto li_ID = Dev::GetOffsetUint32(lastItem, 0x164);
        auto diff = ni_ID - li_ID;
        Dev::SetOffset(item, 0x164, ni_ID);
        Dev::SetOffset(item, 0x168, Dev::GetOffsetUint32(lastItem, 0x168) + diff);
        Dev::SetOffset(item, 0x16c, Dev::GetOffsetUint32(lastItem, 0x16c) + diff);

        if (updateItemsAfter) {
            UpdateNewlyAddedItems(editor);
        }
        return item;
}



void RefreshItemPosRot() {
    // very hacky method: basically cut the whole map and ctrl+z it.
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto editor = cast<CGameCtnEditorFree>(app.Editor);

    // save and restore item placement mode
    auto mode = GetItemPlacementMode();
    // don't do anything if we're not in an item mode
    if (mode == ItemMode::None) return;

    editor.SweepObjectsAndSave();
    editor.PluginMapType.Undo();
    SetItemPlacementMode(mode);
    /* alt impl -- much slower than sweep objects
    // editor.ButtonSelectionBoxSelectAllOnClick();
    // editor.PluginMapType.CopyPaste_Cut();
    // editor.PluginMapType.Undo();
    */
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
