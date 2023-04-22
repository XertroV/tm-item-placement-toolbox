namespace Repeat {
    ReferencedNod@ lastPicked = null;
    ReferencedNod@ tmpItem = null;

    // from the initial item to a central point
    mat4 itemToWorld = mat4::Identity();
    mat4 itemToWorldInv = mat4::Identity();
    vec3 itw_Pos = vec3();
    // vec3 itw_Rot = vec3();

    mat4 itemOffset = mat4::Identity();
    mat4 itemOffsetInv = mat4::Identity();
    mat4 itemOffsetRot = mat4::Identity();
    mat4 itemOffsetRotInv = mat4::Identity();
    vec3 item_Pos = vec3();
    vec3 item_Rot = vec3();

    mat4 internalT = mat4::Identity();
    mat4 internalTInv = mat4::Identity();
    mat4 internalTRot = mat4::Identity();
    mat4 internalTRotInv = mat4::Identity();
    [Setting hidden]
    vec3 internal_Pos = vec3(32, -16, -32);
    [Setting hidden]
    vec3 internal_Rot = vec3();


    mat4 itemToIterBase = mat4::Identity();
    mat4 itemToIterBaseInv = mat4::Identity();
    mat4 itemToIterBaseRot = mat4::Identity();
    mat4 itemToIterBaseRotInv = mat4::Identity();
    [Setting hidden]
    vec3 iterBase_Pos = vec3(32, 0, -32);
    [Setting hidden]
    vec3 iterBase_Rot = vec3(0,0,0);


    // a transformation to apply each iteration
    mat4 worldIteration = mat4::Identity();
    mat4 worldIterationInv = mat4::Identity();
    mat4 wi_RotMat = mat4::Identity();
    mat4 wi_RotMatInv = mat4::Identity();
    [Setting hidden]
    vec3 wi_Pos = vec3(4, 0, 4);
    [Setting hidden]
    vec3 wi_Rot = vec3(0, .5, 0);
    [Setting hidden]
    vec3 wi_Scale = vec3(1.0);

    vec3 startPos = vec3();
    vec3 itemBase = vec3();
    vec3 itemBaseMod = vec3();
    vec3 basePos = vec3();

    [Setting hidden]
    int nbRepetitions = 10;

    void UpdateMatricies() {
        // itemOffset = mat4::Translate(item_Pos) * EulerToMat(item_Rot);
        auto item = lastPicked !is null ? lastPicked.AsItem() : null;
        if (item !is null) {
            // pivot position
            auto pivot = Dev::GetOffsetVec3(item, 0x74);
            if (item.ItemModel.DefaultPlacementParam_Content.PivotPositions.Length > 0) {
                pivot += item.ItemModel.DefaultPlacementParam_Content.PivotPositions[0];
            }
            itw_Pos = item.AbsolutePositionInMap;
            item_Rot = ItemsEuler(item);
            item_Pos = pivot;
        }

        itemToWorld = mat4::Translate(itw_Pos);
        itemOffsetRot = EulerToMat(item_Rot);
        itemOffset = itemOffsetRot * mat4::Translate(item_Pos);
        internalTRot = EulerToMat(internal_Rot);
        internalT = internalTRot * mat4::Translate(internal_Pos);
        itemToIterBaseRot = EulerToMat(iterBase_Rot);
        itemToIterBase = itemToIterBaseRot * mat4::Translate(iterBase_Pos);
        wi_RotMat = EulerToMat(wi_Rot);
        worldIteration = mat4::Scale(wi_Scale) * wi_RotMat * mat4::Translate(wi_Pos);
        itemToWorldInv = mat4::Inverse(itemToWorld);
        itemOffsetInv = mat4::Inverse(itemOffset);
        itemOffsetRotInv = mat4::Inverse(itemOffsetRot);
        internalTInv = mat4::Inverse(internalT);
        internalTRotInv = mat4::Inverse(internalTRot);
        itemToIterBaseInv = mat4::Inverse(itemToIterBase);
        itemToIterBaseRotInv = mat4::Inverse(itemToIterBaseRot);
        worldIterationInv = mat4::Inverse(worldIteration);
        wi_RotMatInv = mat4::Inverse(wi_RotMat);
        if (lastPicked is null || lastPicked.AsItem() is null) return;
        // auto item = lastPicked.AsItem();
        // startPos = item.AbsolutePositionInMap;

        // startPos = (itemToWorld * vec3()).xyz;
        startPos = (itemToWorld * vec3()).xyz;
        itemBase = (itemToWorld * itemOffset * vec3()).xyz;
        itemBaseMod = (itemToWorld * itemOffset * internalT * vec3()).xyz;
        basePos = (itemToWorld * itemOffset * internalT * itemToIterBase * vec3()).xyz;
        // unItemFrame = mat4::Translate(startPos * -1) * mat4::Inverse(EulerToMat(startRot));


    }

    vec3 ItemsEuler(CGameCtnAnchoredObject@ item) {
        return vec3(
            item.Pitch,
            item.Yaw,
            item.Roll
        );
    }

    // From Rxelux's `mat4x` lib, modified
    mat4 EulerToMat(vec3 euler) {
        // mat4 translation = mat4::Translate(position*-1);
        mat4 pitch = mat4::Rotate(-euler.x,vec3(1,0,0));
        mat4 yaw = mat4::Rotate(-euler.y,vec3(0,1,0));
        mat4 roll = mat4::Rotate(-euler.z,vec3(0,0,1));
        return mat4::Inverse(pitch*roll*yaw/* *translation */);
    }

    void RunItemCreation(CGameCtnEditorFree@ editor, CGameCtnAnchoredObject@ origItem) {
        auto lastItem = editor.Challenge.AnchoredObjects[editor.Challenge.AnchoredObjects.Length - 1];
        uint itemId = Dev::GetOffsetUint32(lastItem, 0x164);
        uint someOtherId = Dev::GetOffsetUint32(lastItem, 0x168);
        uint anotherId = Dev::GetOffsetUint32(lastItem, 0x16c);
        mat4 base = itemToWorld * itemOffset * internalT * itemToIterBase;
        mat4 baseRot = itemOffsetRot * internalTRot * itemToIterBaseRot;
        // mat4 baseRotInv = mat4::Inverse(internalTRot * itemToIterBaseRot);

        mat4 back1 = itemToIterBaseInv;
        mat4 back2 = back1 * internalTInv;
        mat4 back3 = back2 * itemOffsetInv;

        // array<vec3> positions = array<vec3>(nbRepetitions);
        // array<vec3> rotations = array<vec3>(nbRepetitions);

        for (uint i = 0; i < nbRepetitions; i++) {
            base = base * worldIteration;
            baseRot = baseRot * wi_RotMat;
            auto m = base * back3;

            vec3 pos3 = (m * vec3()).xyz;

            auto rotV = PitchYawRollFromRotationMatrix(baseRot * itemToIterBaseInv * internalTInv);
            // rotV = PitchYawRollFromRotationMatrix(m * mat4::Translate(pos3 * -1.));
            auto newItem = DuplicateAndAddItem(editor, origItem, false);
            newItem.AbsolutePositionInMap = pos3;
            newItem.Pitch = rotV.x;
            newItem.Yaw = rotV.y;
            newItem.Roll = rotV.z;

            // doenst work for more than like 10-12 items
            if (i % 10 == 0) {
                UpdateNewlyAddedItems(editor);
            }
        }
        UpdateNewlyAddedItems(editor);

        editor.PluginMapType.AutoSave();
    }


    void DrawRepeatTab(CGameCtnEditorFree@ editor) {
        UI::TextWrapped("Copy and repeat items with a modification applied.");
        UI::TextWrapped("Ctrl+hover an item to select it for repetition.");
        UI::TextWrapped("\\$f80Warning!\\$z This tool uses an experimental method of item creation. \\$8f0I believe it is safe, including using undo,\\$z however, there is a risk of a crash upon saving. That said, autosaves seem to save fine (albeit sometimes with a bugged thumbnail). Please exercise caution. \\$8f0Completely reloading the map will remove the possibility of a crash due to these items!");
        UI::TextWrapped("\\$f80Note:\\$z Shadow calculations might fail with a message about duplicate BlockIds -- if this happens, save and reload the map and it will be fixed.");
        CGameCtnAnchoredObject@ selected = null;
        if (lastPicked !is null) {
            @selected = lastPicked.AsItem();
        }
        UI::Text("Curr Item: " + (selected is null ? "None" : string(selected.ItemModel.IdName)));

        UI::Separator();

        UI::Text("Item to World Transformation");

        UI::BeginDisabled();
        itw_Pos = UI::InputFloat3("ITW Pos Offset", itw_Pos);
        UI::EndDisabled();

        UI::Separator();

        UI::Text("Initial Item Transformation (Gray)");

        UI::BeginDisabled();
        item_Pos = UI::SliderFloat3("Init. Pos Offset", item_Pos, -64, 64, "%.4f");
        item_Rot = UI::SliderAngles3("Init. Rot Offset (Deg)", item_Rot);
        UI::EndDisabled();

        UI::Separator();

        UI::Text("Internal Transformation (Cyan)");

        internal_Pos = UI::SliderFloat3("Internal Pos Offset", internal_Pos, -64, 64, "%.4f");
        internal_Rot = UI::SliderAngles3("Internal Rot Offset (Deg)", internal_Rot);

        UI::Separator();

        UI::Text("To Iteration Base (Green)");

        iterBase_Pos = UI::SliderFloat3("Iter. Base Pos Offset", iterBase_Pos, -64, 64, "%.4f");
        iterBase_Rot = UI::SliderAngles3("Iter. Base Rot Offset (Deg)", iterBase_Rot, -30, 30, "%.4f");

        UI::Separator();

        UI::Text("World-Iteration Transformation (Magenta)");

        wi_Pos = UI::SliderFloat3("Iter. Pos Offset", wi_Pos, -64, 64, "%.4f");
        wi_Rot = UI::SliderAngles3("Iter. Rot (Deg)", wi_Rot, -30, 30, "%.4f");
        wi_Scale = UI::InputFloat3("Iter. Scale", wi_Scale);

        UI::Separator();

        nbRepetitions = Math::Max(UI::InputInt("Repetitions", nbRepetitions), 0);

        UpdateMatricies();
        if (lastPicked !is null) {
            DrawHelpers();
        }

        UI::Separator();

        UI::BeginDisabled(lastPicked is null);
        if (UI::Button("Create " + nbRepetitions + " new items")) {
            RunItemCreation(editor, lastPicked.AsItem());
        }
        UI::EndDisabled();
    }

    void drawRotCircles(vec3 pos, vec3 rotBase, vec4 col) {
        for (int i = -1; i < 22; i++) {
            nvgCircleWorldPos((EulerToMat(rotBase * 0.314 * float(i)) * startPos).xyz, col);
        }
    };

    void DrawHelpers() {
        auto item = lastPicked.AsItem();
        if (item is null) return;
        nvg::Reset();

        nvgCircleWorldPos(startPos);
        nvgCircleWorldPos(itemBase, vec4(1, 0, 1, 1));
        nvgCircleWorldPos(itemBaseMod, vec4(1, 0, 0, 1));
        nvgCircleWorldPos(basePos, vec4(0,1,0,1));
        // drawRotCircles(startPos, vec3(1, 0, 0), vec4(1, 0, 0, 1));
        // drawRotCircles(startPos, vec3(0, 1, 0), vec4(0, 1, 0, 1));
        // drawRotCircles(startPos, vec3(0, 0, 1), vec4(0, 0, 1, 1));

        nvg::BeginPath();

        nvgWorldPosReset();
        nvg::StrokeWidth(3.);

        nvgToWorldPos(startPos, vec4(0));
        // actual position of the item
        nvgToWorldPos(itemBase, cGray);
        // 'position' of the item for repetition purposes
        nvgToWorldPos(itemBaseMod, cCyan);
        // start of main iteration
        nvgToWorldPos(basePos, cGreen);

        // a place to draw some coord helpers
        mat4 initItemTf = itemToWorld * itemOffset;
        // the base of our iteration
        mat4 base = initItemTf * internalT * itemToIterBase;

        nvgDrawCoordHelpers(initItemTf);

        mat4 back1 = itemToIterBaseInv;
        mat4 back2 = back1 * internalTInv;
        mat4 back3 = back2 * itemOffsetInv;

        for (uint i = 0; i < nbRepetitions; i++) {
            base = base * worldIteration;
            vec3 pos0 = (base * vec3()).xyz;
            vec3 pos1 = (base * back1 * vec3()).xyz;
            vec3 pos2 = (base * back2 * vec3()).xyz;
            vec3 pos3 = (base * back3 * vec3()).xyz;

            nvgToWorldPos(pos0, cMagenta);
            nvgToWorldPos(pos1, cGreen);

            nvgToWorldPos(pos2, cCyan);
            nvgDrawCoordHelpers(base * back2);

            nvgToWorldPos(pos3, cGray);
            nvgMoveToWorldPos(pos0);
        }
        nvg::StrokeColor(vec4(1));
        nvg::StrokeWidth(3.);
        nvg::Stroke();
        nvg::ClosePath();
    }
}


const vec4 cMagenta = vec4(1, 0, 1, 1);
const vec4 cCyan =  vec4(0, 1, 1, 1);
const vec4 cGreen = vec4(0, 1, 0, 1);
const vec4 cBlue =  vec4(0, 0, 1, 1);
const vec4 cRed =   vec4(1, 0, 0, 1);
const vec4 cGray =  vec4(.5);
const vec4 cWhite = vec4(1);


void nvgCircleWorldPos(vec3 pos, vec4 col = vec4(1, .5, 0, 1)) {
    auto uv = Camera::ToScreen(pos);
    if (uv.z < 0) {
        nvg::BeginPath();
        nvg::FillColor(col);
        nvg::Circle(uv.xy, 5);
        nvg::Fill();
        nvg::ClosePath();
    }
}

// void nvgCircleWorldPos(vec3 pos, vec4 col, vec4 strokeCol) {
//     auto uv = Camera::ToScreen(pos);
//     if (uv.z < 0) {
//         nvg::BeginPath();
//         nvg::FillColor(col);
//         nvg::Circle(uv.xy, 8);
//         nvg::Fill();
//         nvg::ClosePath();
        // nvg::StrokeColor(strokeCol);
        // nvg::StrokeWidth(3);
        // nvg::Stroke();
//     }
// }

bool nvgWorldPosLastVisible = false;
vec3 nvgLastWorldPos = vec3();

void nvgWorldPosReset() {
    nvgWorldPosLastVisible = false;
}

void nvgToWorldPos(vec3 &in pos, vec4 &in col = vec4(1)) {
    nvgLastWorldPos = pos;
    auto uv = Camera::ToScreen(pos);
    if (uv.z > 0) {
        nvgWorldPosLastVisible = false;
        return;
    }
    if (nvgWorldPosLastVisible)
        nvg::LineTo(uv.xy);
    else
        nvg::MoveTo(uv.xy);
    nvgWorldPosLastVisible = true;
    nvg::StrokeColor(col);
    nvg::Stroke();
    nvg::ClosePath();
    nvg::BeginPath();
    nvg::MoveTo(uv.xy);
}

void nvgMoveToWorldPos(vec3 pos) {
    nvgLastWorldPos = pos;
    auto uv = Camera::ToScreen(pos);
    if (uv.z > 0) {
        nvgWorldPosLastVisible = false;
        return;
    }
    nvg::MoveTo(uv.xy);
    nvgWorldPosLastVisible = true;
}

void nvgDrawCoordHelpers(mat4 &in m, float size = 10.) {
    vec3 beforePos = nvgLastWorldPos;
    vec3 pos =  (m * vec3()).xyz;
    vec3 up =   (m * (vec3(0,1,0) * size)).xyz;
    vec3 left = (m * (vec3(1,0,0) * size)).xyz;
    vec3 dir =  (m * (vec3(0,0,-1) * size)).xyz;
    nvgMoveToWorldPos(pos);
    nvgToWorldPos(up, cGreen);
    nvgMoveToWorldPos(pos);
    nvgToWorldPos(dir, cBlue);
    nvgMoveToWorldPos(pos);
    nvgToWorldPos(left, cRed);
    nvgMoveToWorldPos(beforePos);
}


void CheckPickedForRepetitionHelper(CGameCtnEditorFree@ editor) {
    if (editor is null) {
        @Repeat::lastPicked = null;
        return;
    }

    if (editor.PickedObject !is null) {
        @Repeat::lastPicked = ReferencedNod(editor.PickedObject);
    }
}




class ReferencedNod {
    CMwNod@ nod;

    ReferencedNod(CMwNod@ _nod) {
        @nod = _nod;
        nod.MwAddRef();
    }

    ~ReferencedNod() {
        nod.MwRelease();
        @nod = null;
    }

    CGameCtnAnchoredObject@ AsItem() {
        return cast<CGameCtnAnchoredObject>(this.nod);
    }
}
