
// Note: this is disabled in the UI atm pending further dev and hopefully refreshing


void Draw_Effect_CopySkinColor(CGameCtnEditorFree@ editor) {
    if (lastPickedItem is null) {
        UI::Text("Pick an item to copy from");
        return;
    }
    auto picked = lastPickedItem.AsItem();
    if (picked is null) {
        UI::Text("Error: picked item not null but cast to item is null.");
        return;
    }
    UI::Text("Copy From Picked: " + picked.ItemModel.IdName);
    UI::Text("Picked position: " + picked.AbsolutePositionInMap.ToString());
    UI::Separator();
    if (UI::Button("Copy skin to all " + picked.ItemModel.IdName)) {
        CopySkinToAll(editor, picked);
    }
    UI::Separator();
    if (UI::Button("Copy skin to selected " + picked.ItemModel.IdName)) {
        CopySkinToSelected(editor, picked);
    }
}


void CopySkinToAll(CGameCtnEditorFree@ editor, CGameCtnAnchoredObject@ origItem) {
    auto name = origItem.ItemModel.IdName;
    auto skin = _GetItemSkin(origItem);
    if (skin is null) {
        NotifyWarning("null skin, aborting.");
        return;
    }
    for (uint i = 0; i < editor.Challenge.AnchoredObjects.Length; i++) {
        auto item = editor.Challenge.AnchoredObjects[i];
        if (item.ItemModel.IdName == name) {
            auto currSkin = _GetItemSkin(item);
            trace('releasing skin');
            if (currSkin !is null)
                currSkin.MwRelease();
            trace('adding skin ref');
            if (skin !is null)
                skin.MwAddRef();
            trace('setting skin');
            _SetItemSkin(item, skin);
            trace('set skin done');
        }
    }
}

void CopySkinToSelected(CGameCtnEditorFree@ editor, CGameCtnAnchoredObject@ item) {
    // UpdateNbSelectedItemsAndBlocks;
    // todo
}




CSystemPackDesc@ _GetItemSkin(CGameCtnAnchoredObject@ item) {
    if (item is null) return null;
    auto skinOffset = GetOffset("CGameCtnAnchoredObject", "Scale") + 0x18;
    return cast<CSystemPackDesc>(Dev::GetOffsetNod(item, skinOffset));
}

void _SetItemSkin(CGameCtnAnchoredObject@ item, CSystemPackDesc@ skin) {
    if (item is null) return;
    auto skinOffset = GetOffset("CGameCtnAnchoredObject", "Scale") + 0x18;
    Dev::SetOffset(item, skinOffset, skin);
    // 0x158 + 0x18 = 0x170
    auto skinCounterOffset = GetOffset("CGameCtnAnchoredObject", "ItemModel") + 0x18;
    // a counter that ++'s every time a skin is changed
    Dev::SetOffset(item, skinCounterOffset, Dev::GetOffsetUint32(item, skinCounterOffset) + 1);
}
