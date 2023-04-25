void UpdateEditorWatchers(CGameCtnEditorFree@ editor) {
    if (S_CopyPickedItemRotation) CheckForPickedItem_CopyRotation();
    if (g_UseSnappedLoc) EnsureSnappedLoc();
    UpdatePickedItemProps(editor);
    CheckPickedForRepetitionHelper(editor);
    Jitter_CheckNewItems();
}



void UpdateNewlyAddedItems(CGameCtnEditorFree@ editor, bool withRefresh_disabled = false) {
    auto pmt = cast<CSmEditorPluginMapType>(editor.PluginMapType);
    auto macroblock = pmt.GetMacroblockModelFromFilePath("Stadium\\Macroblocks\\LightSculpture\\Spring\\FlowerWhiteSmall.Macroblock.Gbx");
    trace('UpdateNewlyAddedItems macroblock is null: ' + (macroblock is null));
    auto placed = pmt.PlaceMacroblock_NoDestruction(macroblock, int3(0, 24, 0), CGameEditorPluginMap::ECardinalDirections::North);
    trace('UpdateNewlyAddedItems placed: ' + placed);

    if (placed && withRefresh_disabled) {
        // does not seem to do anything useful atm
        // RefreshItemPosRot();
    }

    bool removed = pmt.RemoveMacroblock(macroblock, int3(0, 24, 0), CGameEditorPluginMap::ECardinalDirections::North);
    trace('UpdateNewlyAddedItems removed: ' + removed);
}


// when there are duplicate blockIds this is may not save and occasionally results in crash-on-saves (but not autosaves)
//
CGameCtnAnchoredObject@ DuplicateAndAddItem(CGameCtnEditorFree@ editor, CGameCtnAnchoredObject@ origItem, bool updateItemsAfter = false) {
        auto item = CGameCtnAnchoredObject();
        auto itemTy = Reflection::GetType("CGameCtnAnchoredObject");
        auto itemModelMember = itemTy.GetMember("ItemModel");
        // trace('ItemModel offset: ' + itemModelMember.Offset);
        auto nodIdOffset = itemModelMember.Offset + 0xC;
        // if (nodIdOffset != 0x164) throw('0x164');
        auto blockIdOffset = itemModelMember.Offset + 0x14;
        // if (blockIdOffset != 0x16C) throw('0x16C');

        // new item nod id
        auto ni_ID = Dev::GetOffsetUint32(item, nodIdOffset);

        // copy most of the bytes from the prior item -- excludes last 0x10 bytes: [nod id, some other id, block id]
        Dev_SetOffsetBytes(item, 0x0, Dev_GetOffsetBytes(origItem, 0x0, itemModelMember.Offset + 0x8));
        // this is required to be set for picking to work correctly -- typically they're in the range of like 7k, but setting this to the new items ID doesn't seem to be a problem -- this is probs the block id, b/c we don't get any duplicate complaints when setting this value.
        Dev::SetOffset(item, blockIdOffset, ni_ID);

        // mark flying and add a reference, then add to list of items
        item.IsFlying = true;
        item.ItemModel.MwAddRef();
        editor.Challenge.AnchoredObjects.Add(item);

        // this is some other ID, but gets set when you click 'save' and IDK what it does or matters for
        // Dev::SetOffset(item, 0x168, Dev::GetOffsetUint32(lastItem, 0x168) + diff);

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
    // yield();
    /* alt impl -- much slower than sweep objects
    editor.ButtonSelectionBoxSelectAllOnClick();
    editor.PluginMapType.CopyPaste_Cut();
    editor.PluginMapType.Undo();
    */
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


vec3 GetItemRotations(CGameCtnAnchoredObject@ item) {
    return vec3(
        item.Pitch,
        item.Yaw,
        item.Roll
    );
}

void SetItemRotations(CGameCtnAnchoredObject@ item, vec3 angles) {
    item.Pitch = angles.x;
    item.Yaw = angles.y;
    item.Roll = angles.z;
}

vec3 GetItemPivot(CGameCtnAnchoredObject@ item) {
    auto pivotOffset = GetOffset("CGameCtnAnchoredObject", "Scale") - 0xC;
    auto pivotOffset2 = GetOffset("CGameCtnAnchoredObject", "AbsolutePositionInMap") + 0x30;
    if (pivotOffset != pivotOffset2) {
        NotifyWarning("Item.Pivot memory offset changed. Unsafe to use.");
        throw("Item.Pivot memory offset changed. Unsafe to use.");
    }
    return Dev::GetOffsetVec3(item, pivotOffset);
}
