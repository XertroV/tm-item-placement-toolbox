bool g_UseSnappedLoc = false;

void DrawItemCursorProps() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    if (editor is null) return;
    S_CopyPickedItemRotation = UI::Checkbox("Copy Item Rotations from Picked Items (ctrl+hover)", S_CopyPickedItemRotation);
    // this only works for blocks and is to do with freeblock positioning i think
    // g_UseSnappedLoc = UI::Checkbox("Force Snapped Location", g_UseSnappedLoc);
    auto cursor = editor.Cursor;
    cursor.Pitch = UI::InputFloat("Pitch", cursor.Pitch, Math::PI / 12.);
    cursor.Roll = UI::InputFloat("Roll", cursor.Roll, Math::PI / 12.);
    if (UI::Button("Reset")) {
        cursor.Pitch = 0;
        cursor.Roll = 0;
    }
    UI::SameLine();
    if (UI::Button("Save Favorite")) {
        //
    }
    UI::SameLine();
    if (UI::Button("Load Favorite")) {
        //
    }
}

// East + 75deg is nearly north.
void CheckForPickedItem_CopyRotation() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    if (editor is null) return;
    if (editor.PickedObject is null) return;
    if (editor.Cursor is null) return;

    auto po = editor.PickedObject;
    auto cursor = editor.Cursor;
    cursor.Pitch = po.Pitch;
    cursor.Roll = po.Roll;
    // subtract math::PI/2. here (instead of ::PI) to align to north/east/etc
    auto yaw = ((po.Yaw + Math::PI * 2.) % (Math::PI * 2.));
    cursor.Dir = yaw < Math::PI
        ? yaw < Math::PI/2.
            ? CGameCursorBlock::ECardinalDirEnum::North
            : CGameCursorBlock::ECardinalDirEnum::West
        : yaw < Math::PI/2.*3.
            ? CGameCursorBlock::ECardinalDirEnum::South
            : CGameCursorBlock::ECardinalDirEnum::East
        ;
    auto yQuarter = yaw % (Math::PI / 2.);
    int yawStep = Math::Clamp(int(Math::Floor(yQuarter / Math::PI * 2. * 6. * 1.001) % 6), 0, 5);
    cursor.AdditionalDir = CGameCursorBlock::EAdditionalDirEnum(yawStep);
}

void EnsureSnappedLoc() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    if (editor is null) return;
    if (editor.Cursor is null) return;
    editor.Cursor.UseSnappedLoc = true;
}
