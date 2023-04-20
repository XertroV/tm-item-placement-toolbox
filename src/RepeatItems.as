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
        itemToIterBaseRot = mat4::Identity();
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

    // vec3 MatToEuler(mat4 m) {
    //     // return quat(m).Euler();
    //     return ToQuat(m).Euler() * vec3(-1, 1, 1);
    // }

    // // from Rxelux's `mat4x` lib
    // quat ToQuat(const mat4 &in m){
	// 	float x,y,z,w;
	// 	float trace = m.xx + m.yy + m.zz;
	// 	if( trace > 0 ) {
	// 		float s = 0.5f / Math::Sqrt(trace+ 1.0f);
	// 		w = 0.25f / s;
	// 		x = ( m.yz - m.zy ) * s;
	// 		y = ( m.zx - m.xz ) * s;
	// 		z = ( m.xy - m.yx ) * s;
	// 	} else {
	// 		if ( m.xx > m.yy && m.xx > m.zz ) {
	// 			float s = 2.0f * Math::Sqrt( 1.0f + m.xx - m.yy - m.zz);
	// 			w = (m.yz - m.zy ) / s;
	// 			x = 0.25f * s;
	// 			y = (m.yx + m.xy ) / s;
	// 			z = (m.zx + m.xz ) / s;
	// 		} else if (m.yy > m.zz) {
	// 			float s = 2.0f * Math::Sqrt( 1.0f + m.yy - m.xx - m.zz);
	// 			w = (m.zx - m.xz ) / s;
	// 			x = (m.yx + m.xy ) / s;
	// 			y = 0.25f * s;
	// 			z = (m.zy + m.yz ) / s;
	// 		} else {
	// 			float s = 2.0f * Math::Sqrt( 1.0f + m.zz - m.xx - m.yy );
	// 			w = (m.xy - m.yx ) / s;
	// 			x = (m.zx + m.xz ) / s;
	// 			y = (m.zy + m.yz ) / s;
	// 			z = 0.25f * s;
	// 		}
	// 	}
	// 	return quat(x,y,z,w).Normalized();
	// }


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

        array<vec3> positions = array<vec3>(nbRepetitions);
        array<vec3> rotations = array<vec3>(nbRepetitions);

        for (uint i = 0; i < nbRepetitions; i++) {
            base = base * worldIteration;
            baseRot = baseRot * wi_RotMat;
            auto m = base * back3;
            // auto rotM = mat4::Inverse(itemToIterBaseRotInv * baseRot);
            // auto rotM = mat4::Inverse(baseRot);
            mat4 rotM;

            vec3 pos3 = (m * vec3()).xyz;
            // auto m2 = mat4::Inverse(EulerToMat(ItemsEuler(origItem))) * mat4::Inverse(m) * mat4::Scale(vec3(1, 1, 1));
            // auto m2 = rotM;

            // rotM = mat4::Inverse(mat4::Translate(pos3 * -1.) * m);
            // rotM = mat4::Inverse(mat4::Translate(pos3 * -1.) * m);
            rotM = baseRot;
            // rotM = rotM * mat4::Inverse(baseRot);
            if ((rotM * vec3()).xyz.LengthSquared() > 0) {
                throw('rotM not at 0');
            }

            float pitch = -Math::Atan2(rotM.zy, rotM.yy) + origItem.Pitch,
                  roll = -Math::Asin(-rotM.xy) + origItem.Roll,
                  yaw = -Math::Atan2(rotM.xz, rotM.xx) + origItem.Yaw;

            auto origE = ItemsEuler(origItem) * vec3(1, 1, 1);
            auto rotV = EulerFromRotationMatrix(rotM, 'XZY') * -1;
            pitch = rotV.x;
            yaw = rotV.y;
            roll = rotV.z;

            // auto nextRot = item_Rot + wi_Rot * (i + 1);
            // pitch = nextRot.x;
            // yaw = nextRot.y;
            // roll = nextRot.z;

            // if (m2.yx == 1. || m2.yx == -1.) {
            //     yaw = Math::Atan2(m2.xz, m2.zz);
            // } else {
            //     yaw = Math::Atan2(-m2.zx, m2.xx);
            //     roll = Math::Atan2(-m2.yz, m2.yy);
            // }





            /*
            float sinPitch = -m2.yz;
            float cosPitch = Math::Sqrt(1.0 - sinPitch ** 2);

            if (cosPitch != 0.0) {
                yaw = Math::Atan2(m2.zx, m2.zz);
                pitch = Math::Atan2(sinPitch, cosPitch);
                roll = Math::Atan2(-m2.yx, m2.yy);
                trace('cosPitch != 0');
            } else {
                pitch = (sinPitch > 0. ? 1. : -1.) * 0.5f * Math::PI;
                yaw = Math::Atan2(m2.zx, m2.xx);
                roll = 0.0;
            }
            */


            // float sy = vec2(m2.xx, m2.yx).Length();
            // bool singular = 1e-6 > sy;
            // if (singular) {
            //     pitch = Math::Atan2(m2.zy, m2.zz);
            //     yaw = Math::Atan2(-m2.zx, sy);
            //     roll = Math::Atan2(m2.yx, m2.xx);
            // } else {
            //     pitch = Math::Atan2(-m2.yz, m2.yy);
            //     yaw = Math::Atan2(-m2.zx, sy);
            //     roll = 0;
            // }



            // positions.InsertLast(pos3);
            // rotations.InsertLast(MatToEuler(m));
            auto newItem = DuplicateAndAddItem(editor, origItem, false);
            newItem.AbsolutePositionInMap = pos3;
            newItem.Pitch = pitch;
            newItem.Yaw = yaw;
            newItem.Roll = roll;
            // newItem.Yaw = pyr.y;
            // newItem.Roll = pyr.z;

            // doenst work for more than like 10-12 items
            if (i % 10 == 0) {
                UpdateNewlyAddedItems(editor);
            }
        }
        UpdateNewlyAddedItems(editor);
    }


    void DrawRepeatTab() {
        UI::TextWrapped("Copy and repeat items with a modification applied.");
        UI::TextWrapped("Ctrl+hover an item to select it for repetition.");
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
        item_Pos = UI::SliderFloat3("Init. Pos Offset", item_Pos, -64, 64, "%.2f");
        item_Rot = UI::SliderFloat3("Init. Rot Offset", item_Rot, -Math::PI, Math::PI, "%.2f");
        UI::EndDisabled();

        UI::Separator();

        UI::Text("Internal Transformation (Cyan)");

        internal_Pos = UI::SliderFloat3("Internal Pos Offset", internal_Pos, -64, 64, "%.2f");
        internal_Rot = UI::SliderFloat3("Internal Rot Offset", internal_Rot, -Math::PI, Math::PI, "%.2f");

        UI::Separator();

        UI::Text("To Iteration Base (Green)");

        iterBase_Pos = UI::SliderFloat3("Iter. Base Pos Offset", iterBase_Pos, -64, 64, "%.2f");
        // internal_Rot = UI::SliderFloat3("Internal Rot Offset", internal_Rot, -Math::PI, Math::PI, "%.2f");

        UI::Separator();

        UI::Text("World-Iteration Transformation (Magenta)");

        wi_Pos = UI::InputFloat3("Iter. Pos Offset", wi_Pos);
        wi_Rot = UI::InputFloat3("Iter. Rot", wi_Rot);
        wi_Scale = UI::InputFloat3("Iter. Scale", wi_Scale);

        UI::Separator();

        nbRepetitions = Math::Max(UI::InputInt("Repetitions", nbRepetitions), 0);

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
            // UpdateMatricies();
            // DrawHelpers();
        }
        @lastPicked = tmpItem;
        UpdateMatricies();

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
            // todo: draw helpers at pos2
            nvgToWorldPos(pos3, cGray);
            nvgMoveToWorldPos(pos0);

            nvgDrawCoordHelpers(base * back2);
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

void nvgDrawCoordHelpers(mat4 &in m) {
    vec3 beforePos = nvgLastWorldPos;
    vec3 pos =  (m * vec3()).xyz;
    vec3 up =   (m * (vec3(0,1,0) * 10)).xyz;
    vec3 left = (m * (vec3(1,0,0) * 10)).xyz;
    vec3 dir =  (m * (vec3(0,0,-1) * 10)).xyz;
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
