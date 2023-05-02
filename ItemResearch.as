/**

400 bytes total = 0x190

0x74: vec3: pivot position
0x84: 0x1 & isFlying, 0x2 & isAutoPiloted
0x85: uint8 IVariant

0xC0: mapElemColor
0xC1: animPhaseOffset
0xC2: mapElemLmQuality

0xD4?
0xEC? 0x18, 0xE2, 0x4a

0x120: is location initialized




0x170: number of times skin has changed -- possible update method? nope, incrementing doesn't seem to update items

0x98: ptr to skin (it is ref counted)



 */
;


/**
 blocks

    0x84: 4 bytes, includes variant index and mobil index

    00 00 BlockInfoVarIndex?

    xxxx xxxx VVVV MMMM ---- ---- ---- ----

    22
    block info var index
    iseditableinpuzzleorsimpleeditor

    22

    f -> isGround = true

    2nd 2 -> mobile variant index = 8

    byte order flipped, difference is
    # orig: 10410040, not isEdiable in puzzle or simple editor
    >>> bin(0x40004110)
    '0b1000000000000000100000100010000'
    # orig: 10412040, isEditbaleInPuzzleOrSimpleEditor
    >>> bin(0x40204110)
    '0b1000000001000000100000100010000'


 */
 ;
