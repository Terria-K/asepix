pub const Format = enum(u16) { Indexed = 8, Grayscale = 16, RGBA = 32 };

pub const CelType = enum(u16)
{
    RawImageData = 0,
    LinkedCel = 1,
    CompressedImage = 2,
    CompressedTilemap = 3
};

pub const LayerType = enum(u16)
{
    Normal = 0,
    Group = 1,
    Tilemap = 2
};

pub const BlendMode = enum(u16)
{
    Normal = 0,
    Multiply = 1,
    Screen = 2,
    Overlay = 3,
    Darken = 4,
    Lighten = 5,
    ColorDodge = 6,
    ColorBurn = 7,
    HardLight = 8,
    SoftLight = 9,
    Difference = 10,
    Exclusion = 11,
    Hue = 12,
    Saturation = 13,
    Color = 14,
    Luminiosity = 15,
    Addition = 16,
    Subtract = 17,
    Divide = 18
};

pub const ChunkType = enum(u16) { 
    OldPaletteChunk = 0x0004, 
    OldPaletteChunk2 = 0x0011, 
    LayerChunk = 0x2004, 
    CelChunk = 0x2005, 
    CelExtraChunk = 0x2006, 
    ColorProfileChunk = 0x2007, 
    ExternalFilesChunk = 0x2008, 
    MaskChunk = 0x2016, 
    PathChunk = 0x2017, 
    TagsChunk = 0x2018, 
    PaletteChunk = 0x2019, 
    UserDataChunk = 0x2020, 
    SliceChunk = 0x2022, 
    TilesetChunk = 0x2023 
};

pub const LoopDirection = enum(u8)
{
    Forward,
    Reverse,
    PingPong,
    PingPongReverse
};