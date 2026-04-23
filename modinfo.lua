name = "JiaoHouse"
description = "A starter indoor building mod for DST: build a door, enter an interior zone, place decorative furniture."
author = "xy"
version = "0.1.0"

forumthread = ""
api_version = 10
dst_compatible = true
all_clients_require_mod = true
client_only_mod = false

icon_atlas = ""
icon = ""

server_filter_tags = {
    "building",
    "interior",
}

configuration_options = {
    {
        name = "interior_size",
        label = "Interior Size",
        options = {
            { description = "8x8", data = 8 },
            { description = "10x10", data = 10 },
            { description = "12x12", data = 12 },
        },
        default = 10,
    },
    {
        name = "grid_size",
        label = "Furniture Grid Size",
        options = {
            { description = "1.0", data = 1.0 },
            { description = "0.5", data = 0.5 },
        },
        default = 1.0,
    },
}
