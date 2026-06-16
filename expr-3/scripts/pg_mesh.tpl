template: pg_mesh_top {
    layer: METAL8 {
        direction: horizontal
        width: 5
        spacing: 30
        pitch: 42
        offset_start: boundary
        offset_type: edge
        trim_strap: true
    }
    layer: METAL7 {
        direction: vertical
        width: 5
        spacing: 30
        pitch: 42
        offset_start: boundary
        offset_type: edge
        trim_strap: true
    }
    advanced_rule: off {}
}
