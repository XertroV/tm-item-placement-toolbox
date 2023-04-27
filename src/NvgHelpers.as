

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
    vec3 dir =  (m * (vec3(0,0,1) * size)).xyz;
    nvgMoveToWorldPos(pos);
    nvgToWorldPos(up, cGreen);
    nvgMoveToWorldPos(pos);
    nvgToWorldPos(dir, cBlue);
    nvgMoveToWorldPos(pos);
    nvgToWorldPos(left, cRed);
    nvgMoveToWorldPos(beforePos);
}

void nvgDrawBlockBox(mat4 &in m, vec3 size) {
    vec3 prePos = nvgLastWorldPos;
    vec3 pos = (m * vec3()).xyz;
    nvgMoveToWorldPos(pos);
    nvgToWorldPos(pos);
    nvgToWorldPos((m * (size * vec3(1, 0, 0))).xyz);
    nvgToWorldPos((m * (size * vec3(1, 0, 1))).xyz);
    nvgToWorldPos((m * (size * vec3(0, 0, 1))).xyz);
    nvgToWorldPos(pos);
    nvgToWorldPos((m * (size * vec3(0, 1, 0))).xyz);
    nvgToWorldPos((m * (size * vec3(1, 1, 0))).xyz);
    nvgToWorldPos((m * (size * vec3(1, 1, 1))).xyz);
    nvgToWorldPos((m * (size * vec3(0, 1, 1))).xyz);
    nvgToWorldPos((m * (size * vec3(0, 1, 0))).xyz);
    nvgMoveToWorldPos((m * (size * vec3(1, 0, 0))).xyz);
    nvgToWorldPos((m * (size * vec3(1, 1, 0))).xyz);
    nvgMoveToWorldPos((m * (size * vec3(1, 0, 1))).xyz);
    nvgToWorldPos((m * (size * vec3(1, 1, 1))).xyz);
    nvgMoveToWorldPos((m * (size * vec3(0, 0, 1))).xyz);
    nvgToWorldPos((m * (size * vec3(0, 1, 1))).xyz);
    nvgMoveToWorldPos(prePos);
}
