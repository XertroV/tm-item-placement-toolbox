namespace UI {
    vec3 InputAngles3(const string &in label, vec3 angles) {
        return Math::ToRad(UI::InputFloat3(label, Math::ToDeg(angles)));
    }

    vec2 InputAngles2(const string &in label, vec2 angles) {
        return Math::ToRad(UI::InputFloat2(label, Math::ToDeg(angles)));
    }

    vec3 SliderAngles3(const string &in label, vec3 angles, float min = -180.0, float max = 180.0, const string &in format = "%.1f") {
        return Math::ToRad(UI::SliderFloat3(label, Math::ToDeg(angles), min, max, format));
    }

    vec2 SliderAngles2(const string &in label, vec2 angles, float min = -180.0, float max = 180.0, const string &in format = "%.1f") {
        return Math::ToRad(UI::SliderFloat2(label, Math::ToDeg(angles), min, max, format));
    }
}
