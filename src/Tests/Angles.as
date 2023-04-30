#if DEV

bool testRun = _RunAnglesTests();

bool _RunAnglesTests() {
    startnew(RunAnglesTests);
    return true;
}

void RunAnglesTests() {
    int successes = 0;
    int trials = 1000;
    for (uint i = 0; i < trials; i++) {
        auto yaw = Math::Rand(-Math::PI, Math::PI);
        auto dir = YawToCardinalDirection(yaw);
        auto yaw2 = CardinalDirectionToYaw(dir);
        auto dir2 = YawToCardinalDirection(yaw2);
        if (dir == dir2) {
            successes++;
        } else {
            print('y:' + yaw + ", " + yaw2);
            print('d:' + dir + ", " + dir2);
        }
    }
    string color = successes == trials ? "\\$8f0" : "\\$z";
    print(color + ' Yaw2Cardinal Successes: ' + successes + ' / ' + trials);
    // yield();
}

#endif
