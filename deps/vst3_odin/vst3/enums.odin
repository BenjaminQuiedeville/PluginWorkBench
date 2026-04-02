package vst3

import "core:c"

Speaker :: enum u64 {
    L      = 1 << 0,
    R      = 1 << 1,
    C      = 1 << 2,
    Lfe    = 1 << 3,
    Ls     = 1 << 4,
    Rs     = 1 << 5,
    Lc     = 1 << 6,
    Rc     = 1 << 7,
    S      = 1 << 8,
    Cs     = 1 << 8,
    Sl     = 1 << 9,
    Sr     = 1 << 10,
    Tc     = 1 << 11,
    Tfl    = 1 << 12,
    Tfc    = 1 << 13,
    Tfr    = 1 << 14,
    Trl    = 1 << 15,
    Trc    = 1 << 16,
    Trr    = 1 << 17,
    Lfe2   = 1 << 18,
    M      = 1 << 19,
    ACN0   = 1 << 20,
    ACN1   = 1 << 21,
    ACN2   = 1 << 22,
    ACN3   = 1 << 23,
    ACN4   = 1 << 38,
    ACN5   = 1 << 39,
    ACN6   = 1 << 40,
    ACN7   = 1 << 41,
    ACN8   = 1 << 42,
    ACN9   = 1 << 43,
    ACN10  = 1 << 44,
    ACN11  = 1 << 45,
    ACN12  = 1 << 46,
    ACN13  = 1 << 47,
    ACN14  = 1 << 48,
    ACN15  = 1 << 49,
    ACN16  = 1 << 50,
    ACN17  = 1 << 51,
    ACN18  = 1 << 52,
    ACN19  = 1 << 53,
    ACN20  = 1 << 54,
    ACN21  = 1 << 55,
    ACN22  = 1 << 56,
    ACN23  = 1 << 57,
    ACN24  = 1 << 58,
    Tsl    = 1 << 24,
    Tsr    = 1 << 25,
    Lcs    = 1 << 26,
    Rcs    = 1 << 27,
    Bfl    = 1 << 28,
    Bfc    = 1 << 29,
    Bfr    = 1 << 30,
    Pl     = 1 << 31,
    Pr     = 1 << 32,
    Bsl    = 1 << 33,
    Bsr    = 1 << 34,
    Brl    = 1 << 35,
    Brc    = 1 << 36,
    Brr    = 1 << 37,
    Lw     = 1 << 59,
    Rw     = 1 << 60,
}

SpeakerArrangement :: enum u64 {
    Empty = 0,
    MonoSpeaker = 1 << 19,
    StereoSpeaker = 1 << 0 | 1 << 1,
    StereoWide =  1 << 59 |  1 << 60,
    StereoSurround = 1 << 4 | 1 << 5,
    StereoCenter = 1 << 6 | 1 << 7,
    StereoSide = 1 << 9 | 1 << 10,
    StereoCLfe = 1 << 2 | 1 << 3,
    StereoTF = 1 << 12 | 1 << 14,
    StereoTS =  1 << 24 |  1 << 25,
    StereoTR = 1 << 15 | 1 << 17,
    StereoBF =  1 << 28 |  1 << 30,
    CineFront = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 6 | 1 << 7,
    k30Cine = 1 << 0 | 1 << 1 | 1 << 2,
    k31Cine = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3,
    k30Music = 1 << 0 | 1 << 1 | 1 << 8,
    k31Music = 1 << 0 | 1 << 1 | 1 << 8 | 1 << 3,
    k40Cine = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 8,
    k41Cine = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 8 | 1 << 3,
    k40Music = 1 << 0 | 1 << 1 | 1 << 4 | 1 << 5,
    k41Music = 1 << 0 | 1 << 1 | 1 << 4 | 1 << 5 | 1 << 3,
    k50 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5,
    k51 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 3,
    k60Cine = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 8,
    k61Cine = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 8 | 1 << 3,
    k60Music = 1 << 0 | 1 << 1 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10,
    k61Music = 1 << 0 | 1 << 1 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 | 1 << 3,
    k70Cine = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7,
    k71Cine = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 3,
    k71CineFullFront = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 3,
    k70Music = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10,
    k71Music = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 | 1 << 3,
    k71CineFullRear = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 |  1 << 26 |  1 << 27,
    k71CineSideFill = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 | 1 << 3,
    k71Proximity = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 |  1 << 31 |  1 << 32,
    k80Cine = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8,
    k81Cine = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8 | 1 << 3,
    k80Music = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 8 | 1 << 9 | 1 << 10,
    k81Music = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 8 | 1 << 9 | 1 << 10 | 1 << 3,
    k90Cine = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 9 | 1 << 10,
    k91Cine = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 9 | 1 << 10 | 1 << 3,
    k100Cine = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8 | 1 << 9 | 1 << 10,
    k101Cine = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8 | 1 << 9 | 1 << 10 | 1 << 3,
    kAmbi1stOrderACN =  1 << 20 |  1 << 21 |  1 << 22 |  1 << 23,
    kAmbi2cdOrderACN =  1 << 20 |  1 << 21 |  1 << 22 |  1 << 23 |  1 << 38 |  1 << 39 |  1 << 40 |  1 << 41 |  1 << 42,
    kAmbi3rdOrderACN =  1 << 20 |  1 << 21 |  1 << 22 |  1 << 23 |  1 << 38 |  1 << 39 |  1 << 40 |  1 << 41 |  1 << 42 |  1 << 43 |  1 << 44 |  1 << 45 |  1 << 46 |  1 << 47 |  1 << 48 |  1 << 49,
    kAmbi4thOrderACN =  1 << 20 |  1 << 21 |  1 << 22 |  1 << 23 |  1 << 38 |  1 << 39 |  1 << 40 |  1 << 41 |  1 << 42 |  1 << 43 |  1 << 44 |  1 << 45 |  1 << 46 |  1 << 47 |  1 << 48 |  1 << 49 |  1 << 50 |  1 << 51 |  1 << 52 |  1 << 53 |  1 << 54 |  1 << 55 |  1 << 56 |  1 << 57 |  1 << 58,
    kAmbi5thOrderACN = 0x000FFFFFFFFF,
    kAmbi6thOrderACN = 0x0001FFFFFFFFFFFF,
    kAmbi7thOrderACN = 0xFFFFFFFFFFFFFFFF,
    k80Cube = 1 << 0 | 1 << 1 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17,
    k40_4 = 1 << 0 | 1 << 1 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17,
    k71CineTopCenter = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 8 | 1 << 11,
    k71CineCenterHigh = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 8 | 1 << 13,
    k70CineFrontHigh = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14,
    k70MPEG3D = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14,
    k50_2 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14,
    k71CineFrontHigh = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14 | 1 << 3,
    k71MPEG3D = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14 | 1 << 3,
    k51_2 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14 | 1 << 3,
    k70CineSideHigh = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 |  1 << 24 |  1 << 25,
    k50_2_TS = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 |  1 << 24 |  1 << 25,
    k71CineSideHigh = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 |  1 << 24 |  1 << 25 | 1 << 3,
    k51_2_TS = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 |  1 << 24 |  1 << 25 | 1 << 3,
    k81MPEG3D = 1 << 0 | 1 << 1 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 13 | 1 << 14 |  1 << 29,
    k41_4_1 = 1 << 0 | 1 << 1 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 13 | 1 << 14 |  1 << 29,
    k90 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17,
    k50_4 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17,
    k91 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 | 1 << 3,
    k51_4 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 | 1 << 3,
    k50_4_1 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 29,
    k51_4_1 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 29 | 1 << 3,
    k70_2 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 |  1 << 24 |  1 << 25,
    k71_2 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 |  1 << 24 |  1 << 25 | 1 << 3,
    k91Atmos = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 |  1 << 24 |  1 << 25 | 1 << 3,
    k70_2_TF = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14,
    k71_2_TF = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 3,
    k70_3 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 16,
    k72_3 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 16 | 1 << 3 | 1 << 18,
    k70_4 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17,
    k71_4 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 | 1 << 3,
    k111MPEG3D = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 | 1 << 3,
    k70_6 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 24 |  1 << 25,
    k71_6 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 24 |  1 << 25 | 1 << 3,
    k90_4 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17,
    k91_4 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 | 1 << 3,
    k90_6 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 24 |  1 << 25,
    k91_6 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 24 |  1 << 25 | 1 << 3,
    k90_4_W = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 |  1 << 59 |  1 << 60 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17,
    k91_4_W = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 |  1 << 59 |  1 << 60 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 | 1 << 3,
    k90_6_W = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 |  1 << 59 |  1 << 60 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 24 |  1 << 25,
    k91_6_W = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 |  1 << 59 |  1 << 60 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 24 |  1 << 25 | 1 << 3,
    k100 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 11 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17,
    k50_5 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 11 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17,
    k101 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 11 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 | 1 << 3,
    k101MPEG3D = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 11 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 | 1 << 3,
    k51_5 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 11 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 | 1 << 3,
    k102 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 17 | 1 << 18,
    k52_5 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 17 | 1 << 18,
    k110 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 17,
    k50_6 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 17,
    k111 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 17 | 1 << 3,
    k51_6 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 17 | 1 << 3,
    k122 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 17 | 1 << 18,
    k72_5 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 17 | 1 << 18,
    k130 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 17,
    k131 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 17 | 1 << 3,
    k140 = 1 << 0 | 1 << 1 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 28 |  1 << 30 |  1 << 35 |  1 << 37,
    k60_4_4 = 1 << 0 | 1 << 1 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 28 |  1 << 30 |  1 << 35 |  1 << 37,
    k220 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8 | 1 << 9 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17 |  1 << 24 |  1 << 25 |  1 << 28 |  1 << 29 |  1 << 30,
    k100_9_3 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8 | 1 << 9 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17 |  1 << 24 |  1 << 25 |  1 << 28 |  1 << 29 |  1 << 30,
    k222 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8 | 1 << 9 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17 | 1 << 18 |  1 << 24 |  1 << 25 |  1 << 28 |  1 << 29 |  1 << 30,
    k102_9_3 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8 | 1 << 9 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17 | 1 << 18 |  1 << 24 |  1 << 25 |  1 << 28 |  1 << 29 |  1 << 30,
    k50_5_3 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 28 |  1 << 29 |  1 << 30,
    k51_5_3 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 28 |  1 << 29 |  1 << 30 | 1 << 3,
    k50_2_2 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 |  1 << 24 |  1 << 25 |  1 << 28 |  1 << 30,
    k50_4_2 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 28 |  1 << 30,
    k70_4_2 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 28 |  1 << 30,
    k50_5_Sony = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 17,
    k40_2_2 = 1 << 2 | 1 << 9 | 1 << 10 | 1 << 8 |  1 << 24 |  1 << 25 |  1 << 33 |  1 << 34,
    k40_4_2 = 1 << 0 | 1 << 1 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 28 |  1 << 30,
    k50_3_2 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 13 | 1 << 14 |  1 << 28 |  1 << 30,
    k30_5_2 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 28 |  1 << 30,
    k40_4_4 = 1 << 0 | 1 << 1 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 28 |  1 << 30 |  1 << 35 |  1 << 37,
    k50_4_4 = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 12 | 1 << 14 | 1 << 15 | 1 << 17 |  1 << 28 |  1 << 30 |  1 << 35 |  1 << 37,
}

UnitID :: enum i32 {
    RootUnit = 0,
    NoParentUnit = -1,
}

IStreamSeekMode :: enum i32 {
    IBSeekSet = 0,
    IBSeekCur,
    IBSeekEnd
}

NoteExpressionTypeID :: enum u32 {
    VolumeTypeID = 0,
    PanTypeID,
    TuningTypeID,
    VibratoTypeID,
    ExpressionTypeID,
    BrightnessTypeID,
    TextTypeID,
    PhonemeTypeID,
    CustomStart = 100000,
    CustomEnd = 200000,
    InvalidTypeID = 0xFFFFFFFF
}

NoteExpressionTypeFlag :: enum {
    IsBipolar = 1 << 0,
    IsOneShot = 1 << 1,
    IsAbsolute = 1 << 2,
    AssociatedParameterIDValid = 1 << 3
}

KeyswitchTypeID :: enum u32 {
    NoteOnKeyswitchTypeID = 0,
    OnTheFlyKeyswitchTypeID,
    OnReleaseKeyswitchTypeID,
    KeyRangeTypeID
}

FactoryFlags :: enum {
    NoFlags = 0,
    ClassesDiscardable = 1 << 0,
    LicenseCheck = 1 << 1,
    ComponentNonDiscardable = 1 << 3,
    Unicode = 1 << 4
}

PhysicalUITypeID :: enum u32 {
    PUIXMovement = 0,
    PUIYMovement,
    PUIPressure,
    PUITypeCount,
    InvalidPUITypeID = 0xFFFFFFFF
}

Cardinality :: enum i32 {
    ManyInstances = 0x7FFFFFFF
}

when ODIN_OS == .Linux || ODIN_OS == .Darwin {
    Result ::  enum i32 {
        NoInterface = -1,
        Ok = 0,
        True = 0,
        False = 1,
        InvalidArgument = 2,
        NotImplemented = 3,
        InternalError = 4,
        NotInitialized = 5,
        OutOfMemory = 6,
    }
} else when ODIN_OS == .Windows {
    // We annoyingly have to mess around with the values
    // here to emulate the C overflow...
    Result ::  enum i32 {
        NoInterface = i32(0x80004002 - i64(max(i32))),
        Ok = 0x00000000,
        True = 0x00000000,
        False = 0x00000001,
        InvalidArgument = i32(0x80070057 - i64(max(i32))),
        NotImplemented = i32(0x80004001 - i64(max(i32))),
        InternalError = i32(0x80004005 - i64(max(i32))),
        NotInitialized = i32(0x8000FFFF - i64(max(i32))),
        OutOfMemory = i32(0x8007000E - i64(max(i32))),
    }
} else {
    #panic("Unsupported platform")
}

MediaType :: enum i32 {
    Audio = 0,
    Event,
} 

BusDirection :: enum i32 {
    Input = 0,
    Output
} 

BusType :: enum i32 {
    Main = 0,
    Aux
} 

BusFlags :: enum u32 {
    DefaultActive = 1 << 0,
    IsControlVoltage = 1 << 1
} 

IoMode :: enum i32 {
    Simple = 0,
    Advanced,
    OfflineProcessing
}

ParameterFlags :: enum i32 {
    NoFlags = 0,
    CanAutomate = 1 << 0,
    IsReadOnly = 1 << 1,
    IsWrapAround = 1 << 2,
    IsList = 1 << 3,
    IsHidden = 1 << 4,
    IsProgramChange = 1 << 15,
    IsBypass = 1 << 16
}

RestartFlags :: enum {
    ReloadComponent = 1 << 0,
    IoChanged = 1 << 1,
    ParamValuesChanged = 1 << 2,
    LatencyChanged = 1 << 3,
    ParamTitlesChanged = 1 << 4,
    MidiCCAssignmentChanged = 1 << 5,
    NoteExpressionChanged = 1 << 6,
    IoTitlesChanged = 1 << 7,
    PrefetchableSupportChanged = 1 << 8,
    RoutingInfoChanged = 1 << 9,
    KeyswitchChanged = 1 << 10,
    ParamIDMappingChanged = 1 << 11
} 

ProgressType :: enum {
    AsyncStateRestoration = 0,
    UIBackgroundTask
}

KnobMode :: enum i32 {
    CircularMode = 0,
    RelativCircularMode,
    LinearMode
} 

FrameRateFlags :: enum {
    PullDownRate = 1 << 0,
    DropRate = 1 << 1
} 

Mask :: enum {
    ChordMask = 0x0FFF,
    ReservedMask = 0xF000
}

StatesAndFlags :: enum
{
    Playing = 1 << 1,
    CycleActive = 1 << 2,
    Recording = 1 << 3,
    SystemTimeValid = 1 << 8,
    ContTimeValid = 1 << 17,
    ProjectTimeMusicValid = 1 << 9,
    BarPositionValid = 1 << 11,
    CycleValid = 1 << 12,
    TempoValid = 1 << 10,
    TimeSigValid = 1 << 13,
    ChordValid = 1 << 18,
    SmpteValid = 1 << 14,
    ClockValid = 1 << 15
}

NoteIDUserRange :: enum {
    LowerBound = -10000,
    UpperBound = -1000
} 

DataTypes :: enum {
    MidiSysEx = 0
}

EventFlag :: enum u16 {
    IsLive = 1 << 0,
    UserReserved1 = 1 << 14,
    UserReserved2 = 1 << 15
}

EventType :: enum u16 {
    NoteOnEvent = 0,
    NoteOffEvent = 1,
    DataEvent = 2,
    PolyPressureEvent = 3,
    NoteExpressionValueEvent = 4,
    NoteExpressionTextEvent = 5,
    ChordEvent = 6,
    ScaleEvent = 7,
    LegacyMIDICCOutEvent = 65535
}

IContextMenuItemFlags :: enum {
    IsSeparator = 1 << 0,
    IsDisabled = 1 << 1,
    IsChecked = 1 << 2,
    IsGroupStart = 1 << 3 | 1 << 1,
    IsGroupEnd = 1 << 4 | 1 << 0 
} 

ControllerNumber :: enum i16 {
    CtrlBankSelectMSB = 0,
    CtrlModWheel = 1,
    CtrlBreath = 2,
    CtrlFoot = 4,
    CtrlPortaTime = 5,
    CtrlDataEntryMSB = 6,
    CtrlVolume = 7,
    CtrlBalance = 8,
    CtrlPan = 10,
    CtrlExpression = 11,
    CtrlEffect1 = 12,
    CtrlEffect2 = 13,
    CtrlGPC1 = 16,
    CtrlGPC2 = 17,
    CtrlGPC3 = 18,
    CtrlGPC4 = 19,
    CtrlBankSelectLSB = 32,
    CtrlDataEntryLSB = 38,
    CtrlSustainOnOff = 64,
    CtrlPortaOnOff = 65,
    CtrlSustenutoOnOff = 66,
    CtrlSoftPedalOnOff = 67,
    CtrlLegatoFootSwOnOff = 68,
    CtrlHold2OnOff = 69,
    CtrlSoundVariation = 70,
    CtrlFilterCutoff = 71,
    CtrlReleaseTime = 72,
    CtrlAttackTime = 73,
    CtrlFilterResonance = 74,
    CtrlDecayTime = 75,
    CtrlVibratoRate = 76,
    CtrlVibratoDepth = 77,
    CtrlVibratoDelay = 78,
    CtrlSoundCtrler10 = 79,
    CtrlGPC5 = 80,
    CtrlGPC6 = 81,
    CtrlGPC7 = 82,
    CtrlGPC8 = 83,
    CtrlPortaControl = 84,
    CtrlEff1Depth = 91,
    CtrlEff2Depth = 92,
    CtrlEff3Depth = 93,
    CtrlEff4Depth = 94,
    CtrlEff5Depth = 95,
    CtrlDataIncrement = 96,
    CtrlDataDecrement = 97,
    CtrlNRPNSelectLSB = 98,
    CtrlNRPNSelectMSB = 99,
    CtrlRPNSelectLSB = 100,
    CtrlRPNSelectMSB = 101,
    CtrlAllSoundsOff = 120,
    CtrlResetAllCtrlers = 121,
    CtrlLocalCtrlOnOff = 122,
    CtrlAllNotesOff = 123,
    CtrlOmniModeOff = 124,
    CtrlOmniModeOn = 125,
    CtrlPolyModeOnOff = 126,
    CtrlPolyModeOn = 127,
    AfterTouch = 128,
    PitchBend = 129,
    CountCtrlNumber,
    CtrlProgramChange = 130,
    CtrlPolyPressure = 131,
    CtrlQuarterFrame = 132
} 

ChannelPluginLocation :: enum {
    PreVolumeFader = 0,
    PostVolumeFader,
    UsedAsPanner
} 

PrefetchableSupport :: enum u32 {
    IsNeverPrefetchable = 0,
    IsYetPrefetchable,
    IsNotYetPrefetchable,
    NumPrefetchableSupport
} 

AutomationStates :: enum {
    NoAutomation = 0,
    ReadState = 1 << 0,
    WriteState = 1 << 1,
    ReadWriteState = 1 << 0 | 1 << 1 
}

ComponentFlags :: enum u32 {
    Distributable = 1 << 0,
    SimpleModeSupported = 1 << 1
}

SymbolicSampleSize :: enum i32 {
    Sample32,
    Sample64
}

ProcessMode :: enum i32 {
    Realtime,
    Prefetch,
    Offline
}

IProcessContextRequirements_Flags :: enum {
    NeedSystemTime = 1 << 0,
    NeedContinousTimeSamples = 1 << 1,
    NeedProjectTimeMusic = 1 << 2,
    NeedBarPositionMusic = 1 << 3,
    NeedCycleMusic = 1 << 4,
    NeedSamplesToNextClock = 1 << 5,
    NeedTempo = 1 << 6,
    NeedTimeSignature = 1 << 7,
    NeedChord = 1 << 8,
    NeedFrameRate = 1 << 9,
    NeedTransportState = 1 << 10
}
