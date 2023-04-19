bool g_UseSnappedLoc = false;

void DrawItemCursorProps() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    if (editor is null) return;
    S_CopyPickedItemRotation = UI::Checkbox("Copy Item Rotations from Picked Items (ctrl+hover)", S_CopyPickedItemRotation);
    // this only works for blocks and is to do with freeblock positioning i think
    // g_UseSnappedLoc = UI::Checkbox("Force Snapped Location", g_UseSnappedLoc);
    auto cursor = editor.Cursor;
    cursor.Pitch = UI::InputFloat("Pitch", cursor.Pitch, Math::PI / 24.);
    cursor.Roll = UI::InputFloat("Roll", cursor.Roll, Math::PI / 24.);

    if (UI::BeginCombo("Dir", tostring(cursor.Dir))) {
        for (uint i = 0; i < 4; i++) {
            auto d = CGameCursorBlock::ECardinalDirEnum(i);
            if (UI::Selectable(tostring(d), d == cursor.Dir)) {
                cursor.Dir = d;
            }
        }
        UI::EndCombo();
    }
    if (UI::BeginCombo("AdditionalDir", tostring(cursor.AdditionalDir))) {
        for (uint i = 0; i < 6; i++) {
            auto d = CGameCursorBlock::EAdditionalDirEnum(i);
            if (UI::Selectable(tostring(d), d == cursor.AdditionalDir)) {
                cursor.AdditionalDir = d;
            }
        }
        UI::EndCombo();
    }

    if (UI::Button("Reset")) {
        cursor.Pitch = 0;
        cursor.Roll = 0;
        cursor.AdditionalDir = CGameCursorBlock::EAdditionalDirEnum::P0deg;
        cursor.Dir = CGameCursorBlock::ECardinalDirEnum::North;
    }
    UI::BeginDisabled();
    UI::AlignTextToFramePadding();
    UI::Text("Todo:");
    UI::SameLine();
    if (UI::Button("Save Favorite")) {
        //
    }
    UI::SameLine();
    if (UI::Button("Load Favorite")) {
        //
    }
    UI::EndDisabled();

    // UI::Separator();
    // vec3 pivot = Dev::GetOffsetVec3()

    UI::Separator();

    UI::Text("Picked Item Properties:");


    UI::Text("Name: " + lastPickedItemName);
    UI::Text("Pos: " + lastPickedItemPos.ToString());
    UI::Text("P,R,Y: " + lastPickedItemRot.ToString());
}

string lastPickedItemName;
vec3 lastPickedItemPos = vec3();
EditorRotation@ lastPickedItemRot = EditorRotation(0, 0, 0);

void UpdatePickedItemProps() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    if (editor is null) return;
    if (editor.PickedObject is null) return;
    auto po = editor.PickedObject;
    lastPickedItemName = po.ItemModel.IdName;
    lastPickedItemPos = po.AbsolutePositionInMap;
    @lastPickedItemRot = EditorRotation(po.Pitch, po.Roll, po.Yaw);
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
    // multiply by 1.001 so we avoid rounding errors from yaw ranges -- actually not sure if we need it
    int yawStep = Math::Clamp(int(Math::Floor(yQuarter / Math::PI * 2. * 6. * 1.001) % 6), 0, 5);
    cursor.AdditionalDir = CGameCursorBlock::EAdditionalDirEnum(yawStep);
}

void EnsureSnappedLoc() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    if (editor is null) return;
    if (editor.Cursor is null) return;
    editor.Cursor.UseSnappedLoc = true;
}




class EditorRotation {
    vec3 pry;
    CGameCursorBlock::ECardinalDirEnum dir;
    CGameCursorBlock::EAdditionalDirEnum additionalDir;

    EditorRotation(float pitch, float roll, float yaw) {
        pry = vec3(pitch, roll, yaw);
        CalcDirFromPry();
    }

    EditorRotation(float pitch, float roll, CGameCursorBlock::ECardinalDirEnum dir, CGameCursorBlock::EAdditionalDirEnum additionalDir) {
        this.dir = dir;
        this.additionalDir = additionalDir;
        pry = vec3(pitch, roll, 0);
        CalcYawFromDir();
    }

    void CalcYawFromDir() {
        if (dir == CGameCursorBlock::ECardinalDirEnum::East)
            pry.z = Math::PI * 3. / 2.;
        else if (dir == CGameCursorBlock::ECardinalDirEnum::South)
            pry.z = Math::PI;
        else if (dir == CGameCursorBlock::ECardinalDirEnum::West)
            pry.z = Math::PI / 2.;
        else if (dir == CGameCursorBlock::ECardinalDirEnum::North)
            pry.z = 0;
        pry.z += float(int(additionalDir)) / 6. * Math::PI / 2.;
    }

    void CalcDirFromPry() {
        auto yaw = ((pry.z + Math::PI * 2.) % (Math::PI * 2.));
        dir = yaw < Math::PI
            ? yaw < Math::PI/2.
                ? CGameCursorBlock::ECardinalDirEnum::North
                : CGameCursorBlock::ECardinalDirEnum::West
            : yaw < Math::PI/2.*3.
                ? CGameCursorBlock::ECardinalDirEnum::South
                : CGameCursorBlock::ECardinalDirEnum::East
            ;
        auto yQuarter = yaw % (Math::PI / 2.);
        // multiply by 1.001 so we avoid rounding errors from yaw ranges -- actually not sure if we need it
        int yawStep = Math::Clamp(int(Math::Floor(yQuarter / Math::PI * 2. * 6. * 1.001) % 6), 0, 5);
        additionalDir = CGameCursorBlock::EAdditionalDirEnum(yawStep);
    }

    float get_Pitch() {
        return pry.x;
    }
    float get_Roll() {
        return pry.y;
    }
    float get_Yaw() {
        return pry.x;
    }
    CGameCursorBlock::ECardinalDirEnum get_Dir() {
        return dir;
    }
    CGameCursorBlock::EAdditionalDirEnum get_AdditionalDir() {
        return additionalDir;
    }
    const string ToString() const {
        return pry.ToString();
    }
}
