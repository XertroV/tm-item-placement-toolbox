bool g_UseSnappedLoc = false;

float m_PosStepSize = 0.1;
float m_RotStepSize = 0.02;

void DrawItemCursorProps() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    if (editor is null) return;
    S_CopyPickedItemRotation = UI::Checkbox("Copy Item Rotations from Picked Items (ctrl+hover)", S_CopyPickedItemRotation);
    // this only works for blocks and is to do with freeblock positioning i think
    // g_UseSnappedLoc = UI::Checkbox("Force Snapped Location", g_UseSnappedLoc);
    auto cursor = editor.Cursor;
    cursor.Pitch = UI::InputFloat("Pitch (Rad)", cursor.Pitch, Math::PI / 24.);
    cursor.Roll = UI::InputFloat("Roll (Rad)", cursor.Roll, Math::PI / 24.);

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

    UI::Separator();

    DrawPickedItemProperties();
    DrawPickedBlockPoints();
}


[Setting hidden]
bool S_DrawPickedBlockHelpers = false;


void DrawPickedBlockPoints() {
    if (lastPickedBlock is null) return;
    UI::Separator();
    UI::Text("P Block Pos: " + lastPickedBlockPos.ToString());
    UI::Text("P Block Rot: " + lastPickedBlockRot.ToString());
    S_DrawPickedBlockHelpers = UI::Checkbox("Draw picked block rotation helpers", S_DrawPickedBlockHelpers);
    if (S_DrawPickedBlockHelpers) {
        auto pos = lastPickedBlockPos;
        auto rot = lastPickedBlockRot;
        auto m = mat4::Translate(pos) * EulerToMat(rot);
        nvg::StrokeWidth(3);
        nvgMoveToWorldPos(pos);
        nvgDrawCoordHelpers(m);
        // nvgDrawCoordHelpers(m * mat4::Translate(vec3(16, 2, 16)));
    }
}


float cursorCoordHelpersSize = 10.;

void DrawPickedItemProperties() {
    UI::Text("Picked Item Properties:");

    if (lastPickedItem is null) {
        UI::Text("No item has been picked.");
        return;
    }

    auto item = lastPickedItem.AsItem();

    UI::Text("Name: " + item.ItemModel.IdName);
    UI::Text("Pos: " + item.AbsolutePositionInMap.ToString());
    UI::Text("P,Y,R (Rad): " + EditorRotation(item.Pitch, item.Roll, item.Yaw).PYRToString());


    UI::AlignTextToFramePadding();
    UI::Text("Edit Picked Item Properties (Helper dot shows position)");
    UI::TextWrapped("\\$f80Warning!\\$z This (probably) will not work for the most recently placed item, and you (probably) MUST save and load the map for the changes to persist.");

    item.AbsolutePositionInMap = UI::InputFloat3("Pos.##picked-item-pos", item.AbsolutePositionInMap);
    SetItemRotations(item, UI::InputAngles3("Rot (Deg)##picked-item-rot", GetItemRotations(item)));

    nvgCircleWorldPos(item.AbsolutePositionInMap);
    nvg::StrokeColor(vec4(0, 1, 1, 1));
    nvg::StrokeWidth(3);
    nvg::Stroke();

    cursorCoordHelpersSize = UI::InputFloat("Rot Helpers Size", cursorCoordHelpersSize);

    nvgToWorldPos(item.AbsolutePositionInMap);
    nvgDrawCoordHelpers(mat4::Translate(item.AbsolutePositionInMap) * EulerToMat(GetItemRotations(item)), cursorCoordHelpersSize);


    // todo: nudge doesn't work
#if DEV
#else
    return;
#endif


    UI::AlignTextToFramePadding();
    UI::Text("Nudge Picked Item:");

    vec3 itemPosMod = vec3();
    vec3 itemRotMod = vec3();

    m_PosStepSize = UI::InputFloat("Pos. Step Size", m_PosStepSize, 0.01);
    m_RotStepSize = UI::InputFloat("Rot. Step Size", m_RotStepSize, 0.01);

    UI::Text("Pos:");
    UI::SameLine();
    if (UI::Button("X+")) {
        itemPosMod = vec3(m_PosStepSize, 0, 0);
    }
    UI::SameLine();
    if (UI::Button("X-")) {
        itemPosMod = vec3(-m_PosStepSize, 0, 0);
    }
    UI::SameLine();
    if (UI::Button("Y+")) {
        itemPosMod = vec3(0, m_PosStepSize, 0);
    }
    UI::SameLine();
    if (UI::Button("Y-")) {
        itemPosMod = vec3(0, -m_PosStepSize, 0);
    }
    UI::SameLine();
    if (UI::Button("Z+")) {
        itemPosMod = vec3(0, 0, m_PosStepSize);
    }
    UI::SameLine();
    if (UI::Button("Z-")) {
        itemPosMod = vec3(0, 0, -m_PosStepSize);
    }

    UI::Text("Rot:");
    UI::SameLine();
    if (UI::Button("P+")) {
        itemRotMod = vec3(m_RotStepSize, 0, 0);
    }
    UI::SameLine();
    if (UI::Button("P-")) {
        itemRotMod = vec3(-m_RotStepSize, 0, 0);
    }
    UI::SameLine();
    if (UI::Button("Y+##yaw")) {
        itemRotMod = vec3(0, m_RotStepSize, 0);
    }
    UI::SameLine();
    if (UI::Button("Y-##yaw")) {
        itemRotMod = vec3(0, -m_RotStepSize, 0);
    }
    UI::SameLine();
    if (UI::Button("R+")) {
        itemRotMod = vec3(0, 0, m_RotStepSize);
    }
    UI::SameLine();
    if (UI::Button("R-")) {
        itemRotMod = vec3(0, 0, -m_RotStepSize);
    }

    if (itemPosMod.LengthSquared() > 0 || itemRotMod.LengthSquared() > 0) {
        item.AbsolutePositionInMap += itemPosMod;
        item.Pitch += itemRotMod.x;
        item.Yaw += itemRotMod.y;
        item.Roll += itemRotMod.z;
        startnew(RefreshItemPosRot);
    }
}




string lastPickedItemName;
vec3 lastPickedItemPos = vec3();
EditorRotation@ lastPickedItemRot = EditorRotation(0, 0, 0);
ReferencedNod@ lastPickedItem = null;

void UpdatePickedItemProps(CGameCtnEditorFree@ editor) {
    if (editor is null) {
        @lastPickedItem = null;
        return;
    }
    if (editor.PickedObject is null) return;
    auto po = editor.PickedObject;
    lastPickedItemName = po.ItemModel.IdName;
    lastPickedItemPos = po.AbsolutePositionInMap;
    @lastPickedItemRot = EditorRotation(po.Pitch, po.Roll, po.Yaw);
    @lastPickedItem = ReferencedNod(po);
}

string lastPickedBlockName;
vec3 lastPickedBlockPos = vec3();
vec3 lastPickedBlockRot = vec3();
ReferencedNod@ lastPickedBlock = null;

void UpdatePickedBlockProps(CGameCtnEditorFree@ editor) {
    if (editor is null) {
        @lastPickedBlock = null;
        return;
    }
    if (editor.PickedBlock is null) return;
    auto pb = editor.PickedBlock;
    lastPickedBlockName = pb.BlockInfo.Name;
    lastPickedBlockPos = GetBlockLocation(pb);
    lastPickedBlockRot = GetBlockRotation(pb);
    @lastPickedBlock = ReferencedNod(pb);
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
        return pry.z;
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
    const string PYRToString() const {
        return vec3(pry.x, pry.z, pry.y).ToString();
    }
}
