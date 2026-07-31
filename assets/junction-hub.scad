// ===========================================================
//  Junction hub — printed housing for the bench's J+ / J-
//  distribution node.
//
//  TWO CHAMBERS = two polarities. Left room: the J+ lever nut
//  and every red conductor. Right room: J- and every black.
//  The divider makes a +/- short impossible even if a wire
//  slips. Chambers hold the CONNECTORS; the comb slots hold
//  the WIRES — one doorway per conductor:
//
//    LOAD window (apron: E1 E2 UB VM): all eight load wires exit
//              here, both colors — blacks cross the open top to
//              the back nut. FEED window (apron: FEED): the feed
//              pair enters and U-turns to port 5.
//    CHAMBERS ARE POLARITY, WINDOWS ARE DIRECTION. Each nut runs
//    1 feed in + 4 loads out — that IS a distribution node.
//
//  Open top: wires drop into their slots from above, and the
//  node stays meter-able and re-leverable on the bench.
// ===========================================================

// ---------- LEVER NUT (MEASURED — the units in hand) ----------
nut_l = 29.7;    // measured 5-port span   (datasheet said 30.0)
nut_w = 18.17;   // measured wire-axis depth (datasheet 18.8)
nut_h = 8.1;     // measured height          (datasheet 8.6)
nut_clear = 0.4; // pocket clearance so printed cradles accept them
               // NOTE: all 5 ports open on ONE face — seat each nut with its
               // entry face toward the OUT comb; the single IN wire U-turns
               // through a dressing room to its port. Strip wires 11 mm.
               // (Measured port walls 1.22 end / 0.76 mid: the nut's own
               // 5.6 mm pitch spaces the wires — no comb required.)

// ---------- STRUCTURE ----------
wall     = 2.5;
divider  = 3;
floor_t  = 3;
dress    = 9;      // wire dressing room beyond each cradle end
apron    = 13;     // deck extensions carrying the zip anchors
tab_hole = 3.4;

in_w  = 2*(nut_w + nut_clear) + divider;
in_l  = nut_l + nut_clear + 2*dress;
out_w = in_w + 2*wall;
out_l = in_l + 2*wall;
comb_h = floor_t + nut_h + 4;

$fn = 36;

// one open window per wall, as wide as the nut face. A sill beam
// stays below it for stiffness; wires drop in over it.
module wall_window(y0) {
    translate([wall + dress - 1, y0 - 1, floor_t + 2])
        cube([nut_l + nut_clear + 2, wall + 2, comb_h]);
}

module hub() {
    difference() {
        cube([out_l, out_w, comb_h]);
        translate([wall, wall, floor_t])
            cube([in_l, in_w, comb_h]);
        wall_window(0);              // OUT chamber window
        wall_window(out_w - wall);   // IN chamber window

        // polarity engraved in each chamber floor, at the dressing-room
        // end so it stays visible with the nuts installed. The rooms are
        // + and -, NOT "in" and "out" — both rooms carry in AND out wires.
        translate([wall + 4.5, wall + nut_w/2, floor_t - 0.6])
            linear_extrude(1)
                text("+", size = 7, halign = "center", valign = "center");
        translate([wall + 4.5, wall + nut_w + divider + nut_w/2, floor_t - 0.6])
            linear_extrude(1)
                text("-", size = 7, halign = "center", valign = "center");
    }

    // divider between polarity chambers — rises past the nut tops
    translate([wall, wall + nut_w, floor_t])
        cube([in_l, divider, nut_h + 2]);

    // locating ribs: bracket the nuts lengthwise
    for (x = [wall + dress - 2, wall + dress + nut_l + nut_clear])
        translate([x, wall, floor_t])
            cube([2, in_w, 3]);

    // aprons with zip anchors + engraved labels
    for (side = [0, 1])
        translate([out_l/2 - 30, side == 0 ? -apron : out_w, 0])
            difference() {
                cube([60, apron, floor_t]);
                for (sx = [8, 44])
                    translate([sx, apron/2 - 5, -1])
                        cube([3.2, 10, floor_t + 2]);
                translate([30, apron/2, floor_t - 0.6])
                    linear_extrude(1)
                        text(side == 0 ? "E1 E2 UB VM" : "FEED", size = 4.5,
                             halign = "center", valign = "center");
            }

    // mount tabs, diagonal corners — the DOCK pattern. It is
    // 180°-symmetric, so the hub screws onto any matching pair of
    // ø2.6 bores in either orientation (M3x6: tab + 3 mm plate,
    // flush underneath). The bench tray carries this pattern now;
    // the enclosure floor inherits it later.
    for (p = [[-8, out_w - 10], [out_l - 2, 2]])
        translate([p[0], p[1], 0])
            difference() {
                cube([10, 8, floor_t]);
                translate([5, 4, -1]) cylinder(d = tab_hole, h = floor_t + 2);
            }
}

hub();

// ghosts: the two lever nuts in their chambers
%translate([wall + dress, wall, floor_t]) cube([nut_l, nut_w, nut_h]);
%translate([wall + dress, wall + nut_w + nut_clear + divider, floor_t]) cube([nut_l, nut_w, nut_h]);
