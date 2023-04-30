bool g_UseSnappedLoc = false;

float m_PosStepSize = 0.1;
float m_RotStepSize = 0.02;

void DrawItemCursorProps() {
    auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
    if (editor is null) return;
    S_CopyPickedItemRotation = UI::Checkbox("Copy Item Rotations from Picked Items (ctrl+hover)", S_CopyPickedItemRotation);
    UI::Text("Cursor:");
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
}


void DrawEditItemTab(CGameCtnEditorFree@ editor) {
    DrawPickedItemProperties(editor);
}

void DrawEditBlockTab(CGameCtnEditorFree@ editor) {
    DrawPickedBlockPoints(editor);
}


[Setting hidden]
bool S_DrawPickedBlockHelpers = true;
[Setting hidden]
bool S_DrawPickedBlockBox = true;

bool m_BlockChanged = false;

void DrawPickedBlockPoints(CGameCtnEditorFree@ editor) {
    UI::Text("Picked Block Properties:");

    if (lastPickedBlock is null) {
        UI::Text("No picked block. ctrl+hover to pick a block.");
        return;
    }
    auto block = lastPickedBlock.AsBlock();

    // if (IsBlockFree(block)) {
    //     UI::InputFloat3("Pos", )
    // }
    UI::Text("Block Coord: " + lastPickedBlockCoord.ToString());
    UI::Text("Block Pos: " + lastPickedBlockPos.ToString());
    UI::Text("Block Rot: " + lastPickedBlockRot.ToString());
    S_DrawPickedBlockHelpers = UI::Checkbox("Draw picked block rotation helpers", S_DrawPickedBlockHelpers);
    S_DrawPickedBlockBox = UI::Checkbox("Draw picked block box", S_DrawPickedBlockBox);
    auto pos = lastPickedBlockPos;
    auto rot = lastPickedBlockRot;
    auto m = mat4::Translate(pos) * EulerToMat(rot);
    if (S_DrawPickedBlockBox) {
        nvgDrawBlockBox(m, lastPickedBlockSize);
        nvgDrawBlockBox(m, vec3(32, 8, 32));
    }
    if (S_DrawPickedBlockHelpers) {
        nvg::StrokeWidth(3);
        nvgMoveToWorldPos(pos);
        nvgDrawCoordHelpers(m);
        // nvgDrawCoordHelpers(m * mat4::Translate(vec3(16, 2, 16)));
    }

    vec3 prePos = GetBlockLocation(block);
    vec3 preRot = GetBlockRotation(block);

    if (IsBlockFree(block)) {
        SetBlockLocation(block, UI::InputFloat3("Pos.##picked-block-pos", GetBlockLocation(block)));
        SetBlockRotation(block, UI::InputAngles3("Rot (Deg)##picked-block-rot", GetBlockRotation(block)));
    } else {
        block.CoordX = UI::InputInt("CoordX", block.CoordX);
        block.CoordY = UI::InputInt("CoordY", block.CoordY);
        block.CoordZ = UI::InputInt("CoordZ", block.CoordZ);
        if (UI::BeginCombo("BlockDir", tostring(block.BlockDir))) {
            for (uint i = 0; i < 4; i++) {
                if (UI::Selectable(tostring(CGameCtnBlock::ECardinalDirections(i)), uint(block.BlockDir) == i)) {
                    block.BlockDir = CGameCtnBlock::ECardinalDirections(i);
                }
            }
            UI::EndCombo();
        }
    }

    m_BlockChanged = m_BlockChanged
        || !Math::Vec3Eq(prePos, GetBlockLocation(block))
        || !Math::Vec3Eq(preRot, GetBlockRotation(block));

    UI::BeginDisabled(!m_BlockChanged);
    if (UI::Button("Refresh All##blocks")) {
        trace('refreshing blocks; changed:');
        @lastPickedBlock = null;
        @block = null;
        RefreshBlocksAndItems(editor);
        trace('refresh done');
        if (m_BlockChanged) {
            @lastPickedBlock = ReferencedNod(editor.Challenge.Blocks[editor.Challenge.Blocks.Length - 1]);
            UpdatePickedBlockCachedValues();
            trace('updated last picked block');
            @block = lastPickedBlock.AsBlock();
        } else {
            trace('block not changed');
        }
    }
    UI::EndDisabled();

    if (block is null) return;

    if (IsBlockFree(block)) {
        DrawNudgeFor(block);
    } else {
        UI::Text("Cannot nudge non-free blocks.");
    }
}


float cursorCoordHelpersSize = 10.;

void DrawPickedItemProperties(CGameCtnEditorFree@ editor) {
    UI::Text("Picked Item Properties:");

    if (lastPickedItem is null) {
        UI::Text("No item has been picked. ctrl+hover to pick an item.");
        return;
    }

    auto item = lastPickedItem.AsItem();

    UI::Text("Name: " + item.ItemModel.IdName);
    UI::Text("Pos: " + item.AbsolutePositionInMap.ToString());
    UI::Text("P,Y,R (Rad): " + EditorRotation(item.Pitch, item.Roll, item.Yaw).PYRToString());


    UI::AlignTextToFramePadding();
    UI::Text("Edit Picked Item Properties (Helper dot shows position)");
    // UI::TextWrapped("\\$f80Warning!\\$z This (probably) will not work for the most recently placed item, and you (probably) MUST save and load the map for the changes to persist.");

    item.AbsolutePositionInMap = UI::InputFloat3("Pos.##picked-item-pos", item.AbsolutePositionInMap);
    SetItemRotations(item, UI::InputAngles3("Rot (Deg)##picked-item-rot", GetItemRotations(item)));

    if (UI::Button("Refresh All##items")) {
        auto nbRefs = Reflection::GetRefCount(item);
        RefreshBlocksAndItems(editor);
        if (nbRefs != Reflection::GetRefCount(item)) {
            @lastPickedItem = ReferencedNod(editor.Challenge.AnchoredObjects[editor.Challenge.AnchoredObjects.Length - 1]);
            UpdatePickedItemCachedValues();
            @item = lastPickedItem.AsItem();
        }
    }

    nvgCircleWorldPos(item.AbsolutePositionInMap);
    nvg::StrokeColor(vec4(0, 1, 1, 1));
    nvg::StrokeWidth(3);
    nvg::Stroke();

    cursorCoordHelpersSize = UI::InputFloat("Rot Helpers Size", cursorCoordHelpersSize);

    nvgToWorldPos(item.AbsolutePositionInMap);
    nvgDrawCoordHelpers(mat4::Translate(item.AbsolutePositionInMap) * EulerToMat(GetItemRotations(item)), cursorCoordHelpersSize);

    UI::AlignTextToFramePadding();
    UI::Text("Nudge Picked Item:");

    DrawNudgeFor(item);

    UI::Separator();
    UI::TextWrapped("Relative Position Calculator (useful for static respawns)");
    m_Calc_AbsPosition = UI::InputFloat3("Absolute Position", m_Calc_AbsPosition);
    UI::SameLine();
    if (UI::Button("Reset###clac-abs-position")) {
        m_Calc_AbsPosition = vec3();
    }
    auto m = GetItemMatrix(item);
    vec3 relPos = (mat4::Inverse(m) * m_Calc_AbsPosition).xyz;
    UI::Text("Relative Position: " + relPos.ToString());
    if (UI::IsItemClicked()) {
        SetClipboard(relPos.ToString());
    }
}


vec3 m_Calc_AbsPosition = vec3();


// draw last as can invalidate item/block reference
void DrawNudgeFor(CMwNod@ nod) {
    auto item = cast<CGameCtnAnchoredObject>(nod);
    auto block = cast<CGameCtnBlock>(nod);

    vec3 itemPosMod = vec3();
    vec3 itemRotMod = vec3();

    m_PosStepSize = UI::InputFloat("Pos. Step Size", m_PosStepSize, 0.01);
    m_RotStepSize = Math::ToRad(UI::InputFloat("Rot. Step Size (D)", Math::ToDeg(m_RotStepSize), 0.1));

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
        if (item !is null) {
            item.AbsolutePositionInMap += itemPosMod;
            item.Pitch += itemRotMod.x;
            item.Yaw += itemRotMod.y;
            item.Roll += itemRotMod.z;
        } else if (block !is null) {
            // todo
            if (IsBlockFree(block)) {
                SetBlockLocation(block, GetBlockLocation(block) + itemPosMod);
                SetBlockRotation(block, GetBlockRotation(block) + itemRotMod);
            } else {
                warn('nudge non-free block');
            }
        } else {
            warn("Unhandled nod type to nudge!!!");
            if (nod !is null) {
                warn("Type: " + Reflection::TypeOf(nod).Name);
            }
        }
        // update and fix picked item (will be replaced)
        auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
        RefreshBlocksAndItems(editor);

        if (item !is null) {
            // the updated item will be the last item in the array and has a new pointer
            // items that weren't updated keep the same pointer
            @lastPickedItem = ReferencedNod(editor.Challenge.AnchoredObjects[editor.Challenge.AnchoredObjects.Length - 1]);
            UpdatePickedItemCachedValues();
        } else if (block !is null) {
            @lastPickedBlock = ReferencedNod(editor.Challenge.Blocks[editor.Challenge.Blocks.Length - 1]);
            UpdatePickedBlockCachedValues();
        }
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
    @lastPickedItem = ReferencedNod(po);
    UpdatePickedItemCachedValues();
}

void UpdatePickedItemCachedValues() {
    auto po = lastPickedItem.AsItem();
    lastPickedItemName = po.ItemModel.IdName;
    lastPickedItemPos = po.AbsolutePositionInMap;
    @lastPickedItemRot = EditorRotation(po.Pitch, po.Roll, po.Yaw);
}

string lastPickedBlockName;
nat3 lastPickedBlockCoord = nat3();
vec3 lastPickedBlockPos = vec3();
vec3 lastPickedBlockRot = vec3();
vec3 lastPickedBlockSize = vec3();
ReferencedNod@ lastPickedBlock = null;

void UpdatePickedBlockProps(CGameCtnEditorFree@ editor) {
    if (editor is null) {
        @lastPickedBlock = null;
        return;
    }
    if (editor.PickedBlock is null) return;
    auto pb = editor.PickedBlock;
    @lastPickedBlock = ReferencedNod(pb);
    UpdatePickedBlockCachedValues();
}

void UpdatePickedBlockCachedValues() {
    auto pb = lastPickedBlock.AsBlock();
    lastPickedBlockName = pb.BlockInfo.Name;
    lastPickedBlockCoord = pb.Coord;
    lastPickedBlockPos = GetBlockLocation(pb);
    lastPickedBlockRot = GetBlockRotation(pb);
    lastPickedBlockSize = GetBlockSize(pb);
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
