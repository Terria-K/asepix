pub const LayerFlags = packed struct(u16) {
    visible: bool = false,
    editable: bool = false,
    lock_movement: bool = false,
    background: bool = false,
    prefer_linked_cells: bool = false,
    display_collapsed: bool = false,
    reference_layer: bool = false,

    _: u9 = 0
};