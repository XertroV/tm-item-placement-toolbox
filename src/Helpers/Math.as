namespace Math {
    vec2 ToDeg(vec2 rads) {
        return vec2(ToDeg(rads.x), ToDeg(rads.y));
    }

    vec3 ToDeg(vec3 rads) {
        return vec3(ToDeg(rads.x), ToDeg(rads.y), ToDeg(rads.z));
    }

    vec2 ToRad(vec2 degs) {
        return vec2(ToRad(degs.x), ToRad(degs.y));
    }

    vec3 ToRad(vec3 degs) {
        return vec3(ToRad(degs.x), ToRad(degs.y), ToRad(degs.z));
    }
}
