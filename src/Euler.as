vec3 EulerFromRotationMatrix(mat4 m, const string &in order) {
    float m11 = m.xx, m12 = m.xy, m13 = m.xz,
          m21 = m.yx, m22 = m.yy, m23 = m.yz,
          m31 = m.zx, m32 = m.zy, m33 = m.zz
    ;
    vec3 e = vec3();
    if (order == 'XYZ') {
        e.y = Math::Asin( Math::Clamp( m13, -1.0, 1.0 ) );
        if ( Math::Abs( m13 ) < 0.9999999 ) {
            e.x = Math::Atan2( - m23, m33 );
            e.z = Math::Atan2( - m12, m11 );
        } else {
            e.x = Math::Atan2( m32, m22 );
            e.z = 0;
        }
    } else if (order == 'YXZ') {

        e.x = Math::Asin( - Math::Clamp( m23, -1.0, 1.0 ) );

        if ( Math::Abs( m23 ) < 0.9999999 ) {

            e.y = Math::Atan2( m13, m33 );
            e.z = Math::Atan2( m21, m22 );

        } else {

            e.y = Math::Atan2( - m31, m11 );
            e.z = 0;

        }


    } else if (order == 'ZXY') {

        e.x = Math::Asin( Math::Clamp( m32, -1.0, 1.0 ) );

        if ( Math::Abs( m32 ) < 0.9999999 ) {

            e.y = Math::Atan2( - m31, m33 );
            e.z = Math::Atan2( - m12, m22 );

        } else {

            e.y = 0;
            e.z = Math::Atan2( m21, m11 );

        }


    } else if (order == 'ZYX') {

        e.y = Math::Asin( - Math::Clamp( m31, -1.0, 1.0 ) );

        if ( Math::Abs( m31 ) < 0.9999999 ) {

            e.x = Math::Atan2( m32, m33 );
            e.z = Math::Atan2( m21, m11 );

        } else {

            e.x = 0;
            e.z = Math::Atan2( - m12, m22 );

        }

    } else if (order == 'YZX') {

        e.z = Math::Asin( Math::Clamp( m21, -1.0, 1.0 ) );

        if ( Math::Abs( m21 ) < 0.9999999 ) {

            e.x = Math::Atan2( - m23, m22 );
            e.y = Math::Atan2( - m31, m11 );

        } else {

            e.x = 0;
            e.y = Math::Atan2( m13, m33 );

        }


    } else if (order == 'XZY') {

        e.z = Math::Asin( - Math::Clamp( m12, -1.0, 1.0 ) );

        if ( Math::Abs( m12 ) < 0.9999999 ) {

            e.x = Math::Atan2( m32, m22 );
            e.y = Math::Atan2( m13, m11 );

        } else {

            e.x = Math::Atan2( - m23, m33 );
            e.y = 0;

        }

    } else {
        throw('Unknown ordering');
    }
    return e;
}


bool testRun = _RunEulerTests();

bool _RunEulerTests() {
    startnew(RunEulerTests);
    return true;
}

void RunEulerTests() {
    string[] orders = {'XYZ','YXZ','ZXY','ZYX','YZX','XZY'};
    for (float sign = 1.0; sign >= -1.0; sign -= 2.0) {
        for (uint r = 0; r < orders.Length; r++) {
            for (uint o = 0; o < orders.Length; o++) {
                int successes = 0;
                int trials = 1000;
                for (uint i = 0; i < trials; i++) {
                    auto inVec = vec3(
                        Math::Rand(-Math::PI*2, Math::PI*2),
                        Math::Rand(-Math::PI*2, Math::PI*2),
                        Math::Rand(-Math::PI*2, Math::PI*2)
                    );
                    // set to a simple base case -- we should get at least 1 success for all of them
                    if (i == 0) inVec = vec3();

                    auto inMat = Repeat::EulerToMat(inVec);
                    auto outVec = EulerFromRotationMatrix(inMat, orders[o]);
                    outVec = ReorderVec(outVec, orders[r]) * sign;
                    auto outMat = Repeat::EulerToMat(outVec);
                    // the vectors won't match necessarily b/c there are multiple ways that they can be equiv
                    // so test by turning it back into a rotation matrix and applying to (1,1,1);
                    if (RotMatriciesMatch(inMat, outMat)) {
                        successes++;
                    }
                }
                string color = successes == trials ? "\\$8f0" : "\\$z";
                print(color + 'Order ' + orders[o] + ' (output reordered to: '+orders[r]+'; sign:'+sign+') Successes: ' + successes + ' / ' + trials);
                yield();
            }
        }
    }
}


vec3 ReorderVec(vec3 e, const string &in reorder) {
    if (reorder == 'XYZ') {
        return vec3(e.x, e.y, e.z);
    } else if (reorder == 'YXZ') {
        return vec3(e.y, e.x, e.z);
    } else if (reorder == 'ZXY') {
        return vec3(e.z, e.x, e.y);
    } else if (reorder == 'ZYX') {
        return vec3(e.z, e.y, e.x);
    } else if (reorder == 'YZX') {
        return vec3(e.y, e.z, e.x);
    } else if (reorder == 'XZY') {
        return vec3(e.x, e.z, e.y);
    }
    throw('unknown reorder');
    return e;
}


bool RotMatriciesMatch(mat4 a, mat4 b) {
    auto va = (a * vec3(1, 1, -1)).xyz;
    auto vb = (b * vec3(1, 1, -1)).xyz;
    if ((va - vb).LengthSquared() < 1e-1) {
        return true;
    }
    return false;
}
