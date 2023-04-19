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
    vec3 item_Pos = vec3();
    vec3 item_Rot = vec3();

    mat4 internalT = mat4::Identity();
    mat4 internalTInv = mat4::Identity();
    vec3 internal_Pos = vec3();
    vec3 internal_Rot = vec3();

    // a transformation to apply each iteration
    mat4 worldIteration = mat4::Identity();
    mat4 worldIterationInv = mat4::Identity();
    vec3 wi_Pos = vec3();
    vec3 wi_Rot = vec3();

    vec3 startPos = vec3();
    // vec3 startRot = vec3();
    // vec3 itemPos = vec3();
    vec3 basePos = vec3();

    mat4 toRefF = mat4::Identity();
    mat4 fromRefF = mat4::Identity();

    mat4 unItemFrame;

    void ResetMatricies() {
        item_Pos = vec3();
        item_Rot = vec3();
        itw_Pos = vec3();
        // itw_Rot = vec3();
        wi_Pos = vec3();
        wi_Rot = vec3();
        internal_Pos = vec3(32, -16, -32);
        internal_Rot = vec3();

        itemToWorld = mat4::Identity();
        worldIteration = mat4::Identity();
        itemOffset = mat4::Identity();
        internalT = mat4::Identity();
        context = mat4::Identity();
        uncontext = mat4::Identity();
        if (lastPicked is null) return;
        auto item = lastPicked.AsItem();
        if (item is null) return;
        // itw_Rot = ItemsEuler(item);
    }

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
            // internal_Pos = vec3(32, 0, 0);
        }
        internalT = EulerToMat(internal_Rot) * mat4::Translate(internal_Pos);
        itemOffset = EulerToMat(item_Rot) * mat4::Translate(item_Pos);
        itemToWorld = mat4::Translate(itw_Pos);
        worldIteration = EulerToMat(wi_Rot) * mat4::Translate(wi_Pos);
        itemOffsetInv = mat4::Inverse(itemOffset);
        itemToWorldInv = mat4::Inverse(itemToWorld);
        worldIterationInv = mat4::Inverse(worldIteration);
        internalTInv = mat4::Inverse(internalT);
        if (lastPicked is null || lastPicked.AsItem() is null) return;
        // auto item = lastPicked.AsItem();
        // startPos = item.AbsolutePositionInMap;

        // startPos = (itemToWorld * vec3()).xyz;
        startPos = (itemToWorld * itemOffset * vec3()).xyz;
        basePos = (itemToWorld * itemOffset * internalT * vec3()).xyz;
        // unItemFrame = mat4::Translate(startPos * -1) * mat4::Inverse(EulerToMat(startRot));
    }

    // mat4 ItemsRotation(CGameCtnAnchoredObject@ item) {
    //     // auto q = quat(vec3(1, 0, 0), item.Pitch) *
    //     // quat(vec3(0, 1, 0), item.Yaw) *
    //     // quat(vec3(0, 0, -1), item.Roll);
    //     // return mat4::Rotate(q.Angle(), q.Axis());
    //     return EulerToMat(ItemsEuler(item));
    // }

    vec3 ItemsEuler(CGameCtnAnchoredObject@ item) {
        return vec3(
            item.Pitch,
            item.Yaw,
            item.Roll
        );
    }

    uint _doneTrace = 0;

mat4 EulerToMat(vec3 euler) {
    // mat4 translation = mat4::Translate(position*-1);
    mat4 pitch = mat4::Rotate(-euler.x,vec3(1,0,0));
    mat4 yaw = mat4::Rotate(-euler.y,vec3(0,1,0));
    mat4 roll = mat4::Rotate(-euler.z,vec3(0,0,1));
    return mat4::Inverse(pitch*roll*yaw/* *translation*/);
}

    mat4 EulerToMatQ(vec3 euler) {
        float fVar1 = Math::Sin(euler.y * 0.5);
        float fVar2 = Math::Cos(euler.y * 0.5);
        float fVar3 = Math::Sin(euler.z * 0.5);
        float fVar4 = Math::Cos(euler.z * 0.5);
        float fVar5 = Math::Sin(euler.x * 0.5);
        float fVar6 = Math::Cos(euler.x * 0.5);
        float W = fVar3 * fVar1 * fVar5 - fVar4 * fVar2 * fVar6;
        // float X = (float)((uint)(fVar3 * fVar1 * fVar6) ^ 0x80000000) - fVar4 * fVar2 * fVar5;
        // float Y = (float)((uint)(fVar3 * fVar2 * fVar5) ^ 0x80000000) - fVar4 * fVar1 * fVar6;
        float X = -1. * (fVar3 * fVar1 * fVar6) - fVar4 * fVar2 * fVar5;
        float Y = -1. * (fVar3 * fVar2 * fVar5) - fVar4 * fVar1 * fVar6;
        float Z = fVar4 * fVar1 * fVar5 - fVar3 * fVar2 * fVar6;
        auto q = quat(X, Y, Z, W);
        return mat4::Rotate(q.Angle(), q.Axis());

        // vec4 mX = vec4();
        // vec4 mY = vec4();
        // vec4 mZ = vec4();

        // float _2Z = Z + Z;
        // float _2Y = Y + Y;
        // float fVar8 = W * (X + X);
        // float fVar7 = 1.0 - X * (X + X);
        // mZ.x = X * _2Z - W * _2Y;
        // mX.z = X * _2Z + W * _2Y;
        // mX.x = (1.0 - Y * _2Y) - Z * _2Z;
        // mY.z = Y * _2Z - fVar8;
        // mZ.y = Y * _2Z + fVar8;
        // mY.x = X * _2Y + W * _2Z;
        // mX.y = X * _2Y - W * _2Z;
        // mY.y = fVar7 - fVar2 * _2Z;
        // mZ.z = fVar7 - Y * _2Y;
        // return mat4(mX, mY, mZ, vec4(0,0,0,1));
        // if (_doneTrace < 20) {
        //     _doneTrace++;
        //     trace(q.ToString());
        // }
        // trace('angle: ' + q.Angle());
        // trace('axis: ' + q.Axis().ToString());
        // // throw(mat4::Rotate(q.Angle(), q.Axis()).ToString());
        // throw('');


        // return mat4::Identity()
        // * mat4::Rotate(euler.y, vec3(0, 1, 0))
        // * mat4::Rotate(euler.x, vec3(1, 0, 0))
        // * mat4::Rotate(euler.z, vec3(0, 0, 1))
        // ;

        // * mat4::Rotate(euler.z, vec3(0, 0, 1))
        // * mat4::Rotate(euler.y, vec3(0, 1, 0))
        // * mat4::Rotate(euler.x, vec3(1, 0, 0))
        // auto q =
        // quat(vec3(0, 0, 1), euler.z) *
        // quat(vec3(0, -1, 0), euler.y) *
        // quat(vec3(-1, 0, 0), euler.x);
        // auto q = quat(euler);
        // return mat4::Rotate(q.Angle(), q.Axis());
    }

    vec3 PYRToEuler(vec3 pyr) {
        throw('nope');
        auto phi = Math::Atan2(Math::Sin(pyr.z) * Math::Cos(pyr.x) * Math::Cos(pyr.y) + Math::Sin(pyr.x) * Math::Sin(pyr.y), Math::Cos(pyr.z) * Math::Cos(pyr.y));
        auto theta = Math::Atan2(Math::Sin(pyr.x) * Math::Cos(pyr.y), Math::Cos(pyr.x));
        auto psi = Math::Atan2(Math::Sin(pyr.y) * Math::Cos(pyr.x) * Math::Cos(pyr.z) + Math::Sin(pyr.x) * Math::Sin(pyr.z), Math::Cos(pyr.y) * Math::Cos(pyr.x));
        return vec3(phi, theta, psi);
        // def euler_angles(pitch, yaw, roll):
        //     # Calculate the Euler angles using the Z-Y-X rotation order
        //     phi = math.atan2(math.sin(roll) * math.cos(pitch) * math.cos(yaw) + math.sin(pitch) * math.sin(yaw),
        //                     math.cos(roll) * math.cos(pitch))
        //     theta = math.atan2(math.sin(pitch) * math.cos(yaw),
        //                     math.cos(pitch))
        //     psi = math.atan2(math.sin(yaw) * math.cos(pitch) * math.cos(roll) + math.sin(pitch) * math.sin(roll),
        //                     math.cos(yaw) * math.cos(pitch))
    }

    int nbRepetitions = 20;

    void DrawRepeatTab() {
        UI::TextWrapped("Copy and repeat items with a modification applied.");
        UI::TextWrapped("Ctrl+hover an item to select it for repetition.");
        CGameCtnAnchoredObject@ selected = null;
        if (lastPicked !is null) {
            @selected = lastPicked.AsItem();
        }
        UI::Text("Curr Item: " + (selected is null ? "None" : string(selected.ItemModel.IdName)));

        nbRepetitions = Math::Max(UI::InputInt("Repetitions", nbRepetitions), 0);

        UI::Separator();

        UI::Text("Internal Transformation (Cyan)");

        internal_Pos = UI::SliderFloat3("Internal Pos Offset", internal_Pos, -64, 64, "%.2f");
        internal_Rot = UI::SliderFloat3("Internal Rot Offset", internal_Rot, -Math::PI, Math::PI, "%.2f");

        UI::Text("Initial Item Transformation (White)");

        // item_Pos = UI::SliderFloat3("Init. Pos Offset", item_Pos, -64, 64, "%.2f");
        UI::BeginDisabled();
        item_Rot = UI::SliderFloat3("Init. Rot Offset", item_Rot, -Math::PI, Math::PI, "%.2f");
        UI::EndDisabled();

        UI::Separator();

        UI::Text("Item to World Transformation (Yellow)");

        itw_Pos = UI::InputFloat3("ITW Pos Offset", itw_Pos);
        // itw_Rot = UI::InputFloat3("ITW Rot Offset", itw_Rot);

        UI::Separator();

        UI::Text("World-Iteration Transformation (Magenta)");

        wi_Pos = UI::InputFloat3("Iter. Pos Offset", wi_Pos);
        wi_Rot = UI::InputFloat3("Iter. Rot Offset", wi_Rot);

        UpdateMatricies();
        if (lastPicked !is null) {
            DrawHelpers();
        }

        auto app = GetApp();
        auto editor = cast<CGameCtnEditorFree>(app.Editor);
        auto map = editor.Challenge;
        @tmpItem = lastPicked;
        for (uint i = 0; i < map.AnchoredObjects.Length; i++) {
            auto item = map.AnchoredObjects[i];
            @lastPicked = ReferencedNod(item);
            UpdateMatricies();
            DrawHelpers();
        }
        @lastPicked = tmpItem;
        UpdateMatricies();

        UI::Separator();

        UI::Text("Start: " + startPos.ToString());
        UI::Text("Base: " + basePos.ToString());
    }

    void drawRotCircles(vec3 pos, vec3 rotBase, vec4 col) {
        for (int i = -1; i < 22; i++) {
            nvgCircleWorldPos((EulerToMat(rotBase * 0.314 * float(i)) * startPos).xyz, col);
        }
        // nvgCircleWorldPos((EulerToMat(vec3(0, 0, -.6)) * startPos).xyz, vec4(1, 0, 0, 1));
        // nvgCircleWorldPos((EulerToMat(vec3(0, .3, 0)) * startPos).xyz, vec4(0, 1, 0, 1));
        // nvgCircleWorldPos((EulerToMat(vec3(0, .6, 0)) * startPos).xyz, vec4(0, 1, 0, 1));
        // nvgCircleWorldPos((EulerToMat(vec3(.3, 0, 0)) * startPos).xyz, vec4(0, 0, 1, 1));
        // nvgCircleWorldPos((EulerToMat(vec3(.6, 0, 0)) * startPos).xyz, vec4(0, 0, 1, 1));
    };

    void DrawHelpers() {
        auto item = lastPicked.AsItem();
        if (item is null) return;
        nvg::Reset();

        nvgCircleWorldPos(startPos);
        nvgCircleWorldPos(basePos, vec4(0,1,0,1));
        // drawRotCircles(startPos, vec3(1, 0, 0), vec4(1, 0, 0, 1));
        // drawRotCircles(startPos, vec3(0, 1, 0), vec4(0, 1, 0, 1));
        // drawRotCircles(startPos, vec3(0, 0, 1), vec4(0, 0, 1, 1));

        nvg::BeginPath();

        // nvg::StrokeColor(vec4(0,0,0,1));
        nvgWorldPosReset();
        auto pos = item.AbsolutePositionInMap;
        nvgToWorldPos(startPos);
        nvgToWorldPos(basePos);
        // nvgToWorldPos(itemPos);
        // nvgToWorldPos(basePos);
        // mat4 iter = fromRefF * worldIteration * toRefF;
        // // draw initial things
        // // then draw iteration
        // mat4 base = mat4::Translate(pos) * mat4::Rotate(EulerToMat())
        //     * itemOffset * itemToWorld;
        // for (uint i = 0; i < nbRepetitions; i++) {
        //     // base = base * iter;
        //     base = iter * base;
        //     auto item = nbRepetitions[i];
        //     nvgToWorldPos(startPos);

        // }
        nvg::StrokeColor(vec4(1));
        nvg::StrokeWidth(3.);
        nvg::Stroke();
        nvg::ClosePath();
    }
}

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

bool nvgWorldPosLastVisible = false;
void nvgWorldPosReset() {
    nvgWorldPosLastVisible = false;
}

void nvgToWorldPos(vec3 pos) {
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


// todo: draw repeat helper






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
