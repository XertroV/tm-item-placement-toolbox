bool g_SetBlockLocationOnDissociation = true;

uint lastNbSelected = 0;

void Draw_Effect_Dissociate() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);

    g_SetBlockLocationOnDissociation = UI::Checkbox("Set `item.BlockUnitCoord` upon dissociation", g_SetBlockLocationOnDissociation);
    AddSimpleTooltip("When true: Items will be selectable / copyable. If resting on a normal (non-ghost, non-free block), they will still be deleted along with that block.\nWhen false: Items will not be selectable / copyable, and will never be deleted when the anchored block is deleted.");

    UI::Separator();

    UI::AlignTextToFramePadding();
    UI::Text("Global Dissociation");

    UI::TextWrapped("This will dissociate items from blocks. e.g., if you place road signs along a block, and then delete the block, the road signs are also deleted because of the association. This will dissociate items from blocks, so each thing needs to be deleted individually (in the preceding case). This also removes the association with macroblocks (or so it appears, at least).");
    if (UI::Button("Dissociate Items from Blocks")) {
        RunDissociation();
    }
    UI::Separator();
    UI::AlignTextToFramePadding();
    UI::TextWrapped("Selected Dissociation");
    UI::TextWrapped("This will dissociate all items that are associated with blocks that are currently selected using the Copy tool.");

    auto nbSelected = Dev::GetOffsetUint32(editor, 0xB58);
    UI::AlignTextToFramePadding();
    UI::TextWrapped("Currently Selected Regions: " + nbSelected);

    if (nbSelected != lastNbSelected) {
        lastNbSelected = nbSelected;
        ResetSelectedCache();
    }

    UI::AlignTextToFramePadding();
    UI::Text("Selected Items / Blocks: " + selectedItems.Length + " / " + selectedBlocks.Length);
    UI::SameLine();
    if (UI::Button("Update##nbSelectedItemsBlocks")) {
        UpdateNbSelectedItemsAndBlocks(editor);
    }

    if (UI::Button("Dissociate Items from Selected Blocks")) {
        RunDissociationOnSelected(editor);
    }
}


void ResetSelectedCache() {
    selectedCoords.DeleteAll();
    selectedItems.RemoveRange(0, selectedItems.Length);
    selectedBlocks.RemoveRange(0, selectedBlocks.Length);
}


dictionary selectedCoords;
array<CGameCtnAnchoredObject@> selectedItems;
array<CGameCtnBlock@> selectedBlocks;

void UpdateNbSelectedItemsAndBlocks(CGameCtnEditorFree@ editor) {
    ResetSelectedCache();
    // cache selected block coords
    auto nbSelected = Dev::GetOffsetUint32(editor, 0xB58);
    auto selectedBuf = Dev::GetOffsetNod(editor, 0xB50);
    nat3 coord = nat3(0);
    for (uint i = 0; i < nbSelected; i++) {
        coord.x = Dev::GetOffsetUint32(selectedBuf, i * 0xC);
        coord.y = Dev::GetOffsetUint32(selectedBuf, i * 0xC + 0x4);
        coord.z = Dev::GetOffsetUint32(selectedBuf, i * 0xC + 0x8);
        selectedCoords[coord.ToString()] = true;
    }
    // find items with those coords
    auto map = editor.Challenge;
    for (uint i = 0; i < map.AnchoredObjects.Length; i++) {
        auto item = map.AnchoredObjects[i];
        auto linkedListEntry = Dev::GetOffsetNod(item, 0x90);
        if (linkedListEntry is null && selectedCoords.Exists(item.BlockUnitCoord.ToString())) {
            selectedItems.InsertLast(item);
        } else if (linkedListEntry !is null) {
            auto block = cast<CGameCtnBlock>(Dev::GetOffsetNod(linkedListEntry, 0x0));
            if (block !is null && selectedCoords.Exists(block.Coord.ToString())) {
                selectedItems.InsertLast(item);
            }
        }
    }
    // blocks
    for (uint i = 0; i < map.Blocks.Length; i++) {
        auto block = map.Blocks[i];
        if (block !is null && selectedCoords.Exists(block.Coord.ToString())) {
            selectedBlocks.InsertLast(block);
        }
    }
}



/**
 * The linked list data structure is like {
 *      ptr: prev
 *      ptr: block
 *      some stuff
 *      0x20 in length
 *      ptr to this struct is to 0x8 -- directly to block ptr
 * }
 */

void RunDissociation() {
    try {
        auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
        auto map = editor.Challenge;
        uint dissociatedCount = 0;
        for (uint i = 0; i < map.AnchoredObjects.Length; i++) {
            auto item = map.AnchoredObjects[i];
            if (DissociateItem(item)) {
                dissociatedCount++;
            }
        }
        Notify("Items dissociated: " + dissociatedCount);
    } catch {
        NotifyWarning("Exception during RunDissociation: " + getExceptionInfo());
    }
}

void RunDissociationOnSelected(CGameCtnEditorFree@ editor) {
    UpdateNbSelectedItemsAndBlocks(editor);
    // find items with those coords
    uint dissociatedCount = 0;
    for (uint i = 0; i < selectedItems.Length; i++) {
        auto item = selectedItems[i];
        if (DissociateItem(item)) {
            dissociatedCount++;
        }
    }
    Notify("Dissociated Items: " + dissociatedCount);
}

bool DissociateItem(CGameCtnAnchoredObject@ item) {
    auto linkedListEntry = Dev::GetOffsetNod(item, 0x90);
    if (linkedListEntry is null) return false;
    Dev::SetOffset(item, 0x90, uint64(0));
    auto block = cast<CGameCtnBlock>(Dev::GetOffsetNod(linkedListEntry, 0x0));
    if (block !is null && g_SetBlockLocationOnDissociation) {
        item.BlockUnitCoord = block.Coord;
    }
    return true;
}


/**
 * CGameCtnAnchoredObject
 *
 * 0xC0: uint16 color: 0 for none, then 1-5
 */