// ===========================================================
//  Test bench tray — v3 (layout v5: the power-bay design)
//
//  Bottom-left : battery bay, snug rails, lead exits right
//  Above it    : switch pocket, parallel, both leads -> bay
//  Bottom-right: POWER BAY — open floor, XT60 plug/unplug
//  Bay top rim : DOCK for the modular junction hub
//                (junction-hub.scad screws on, M3x6, either
//                orientation — its tab pattern is 180°-symmetric)
//  Above hub   : two horizontal ESC berths, velcro straps;
//                XT60 ends drop into the hub's OUT comb,
//                phase leads exit the RIGHT edge
//  Mid corridor: fuse + UBEC (zip anchors)
//  Left column : expansion board (portrait) + DRV shield, screwed
//
//  Plate is 245 x 228 — the real hub footprint (60x50 + aprons)
//  needed more depth than the first sketch guessed.
// ===========================================================

plate_x = 242;  plate_y = 225;  plate_t = 3;   // trimmed 3 mm each way so
                                                // part + brim clears the
                                                // Bambu front-left exclusion
                                                // zone; all edge features
                                                // derive and follow

// ---------- expansion board (measured 55.88 x 20.32), PORTRAIT ----
xb_hole_dx = 20.32;        // across (x) in portrait
xb_hole_dy = 55.88;        // along (y) in portrait
xb_center  = [45, 162];    // raised so the board sits 13 mm clear of the
                           // DRV shield below — finger + wiring access
xb_post_od = 8;  xb_bore = 4.0;  post_h = 6;   // ø4.0 bore = M3 heat-set insert

echo(str("expansion-to-shield gap: ",
         (xb_center[1] - 38) - (drv_center[1] + 20.5), " mm"));

// ---------- DRV8825 shield (measured 35 x 35) ----------
drv_pitch  = 35;
drv_center = [32.5, 90.5];
drv_post_od = 8;  drv_bore = 4.0;               // insert here too

// ---------- battery bay (Zeee 139 x 47, snug) ----------
bay_o = [10, 10];
bay_w = 141;  bay_h = 49;
wall_t = 3;  wall_h = 26;  lip_h = 10;   // battery-tray.scad numbers:
notch_w = 14;  notch_sill = 6;           // rails 26, open-end lip 10,
                                          // lead notch 14 wide at the
                                          // switch-side corner, sill +6
strap_l = 22;  strap_w = 3.5;

// ---------- switch pocket (measured 68 x 46, walls 10) ----------
sw_l = 68;  sw_w = 46;  sw_h = 18;
sw_wall_h = 10;
sw_clear = 0.5;
sw_o = [76, 70];           // centred between the DRV shield and the hub:
                           // 20 mm clear at EACH XT60 end (was 11 on the
                           // hub side), and dropped to 8 mm off the bay
                           // rail. Mating still happens in the power bay —
                           // the ends just need clean egress room.

echo(str("switch XT60 clearance L/R: ",
         (sw_o[0] - wall_t) - (drv_center[0] + 20.5), " / ",
         hub_pos[0] - (sw_o[0] + sw_l + 2*sw_clear + wall_t), " mm"));

// ---------- POWER BAY (open floor — engraved outline) ----------
pb = [160, 6, 78, 68];     // x, y, w, h — keep clear

// ---------- junction hub dock (mirrors junction-hub.scad) ----------
// COUPLED to the hub's nut dimensions:
//   hub_l = nut_l + nut_clear + 23   (dressing rooms + walls)
//   hub_w = 2*(nut_w + nut_clear) + 8
// MEASURED nuts (29.7 x 18.17, clear 0.4) give 53.1 x 45.1.
hub_pos = [168, 88];       // hub BODY origin on the tray
hub_l = 53.1;  hub_w = 45.1; // body; aprons add 13 each comb side
hub_hole_a = [hub_pos[0] - 3,        hub_pos[1] + hub_w - 6];
hub_hole_b = [hub_pos[0] + hub_l + 3, hub_pos[1] + 6];
hub_bore = 2.6;            // M3x6: through 3 mm tab + 3 mm plate, flush

// ---------- ESC berths (24 x 90, HORIZONTAL, stacked) ----------
esc_x = 146;  esc_l = 90;  esc_w = 24;
esc1_y = 156;  esc2_y = 186;

// ---------- fuse + UBEC (mid corridor, zip anchors) ----------
fuse_o = [92, 130];  fuse_sz = [36, 18];
ubec_o = [92, 162];  ubec_sz = [38, 18];

corner_hole = 3.4;
$fn = 36;

module posts(center, dx, dy, od, bore) {
    for (sx = [-1, 1]) for (sy = [-1, 1])
        translate([center[0] + sx*dx/2, center[1] + sy*dy/2, 0])
            difference() {
                cylinder(d = od, h = plate_t + post_h);
                // insert pocket: press M3 heat-set flush with the iron
                translate([0, 0, plate_t + post_h - 7])
                    cylinder(d = bore, h = 8);
            }
}

module zip_pair_y(o, sz) {   // slots above and below a footprint
    cx = o[0] + sz[0]/2 - 5;
    translate([cx, o[1] - 6, -1])          cube([10, 3.2, plate_t + 2]);
    translate([cx, o[1] + sz[1] + 3, -1])  cube([10, 3.2, plate_t + 2]);
}

module tray() {
    difference() {
        hull()
            for (x = [4, plate_x-4]) for (y = [4, plate_y-4])
                translate([x, y, 0]) cylinder(r = 4, h = plate_t);

        // corner holes (dock-kit TPU feet or screws)
        for (x = [7, plate_x-7]) for (y = [7, plate_y-7])
            translate([x, y, -1]) cylinder(d = corner_hole, h = plate_t + 2);

        // battery straps
        for (sx = [bay_o[0] + 42, bay_o[0] + 100])
            for (sy = [bay_o[1] - 8, bay_o[1] + bay_h + 4.5])
                translate([sx - strap_l/2, sy, -1])
                    cube([strap_l, strap_w, plate_t + 2]);

        // switch zip crossing
        for (sx = [sw_o[0] - 7, sw_o[0] + sw_l + 2*sw_clear + 4])
            translate([sx, sw_o[1] + sw_w/2 - 5, -1])
                cube([3.2, 10, plate_t + 2]);

        // POWER BAY: engraved boundary groove + label
        translate([pb[0], pb[1], plate_t - 0.4]) difference() {
            cube([pb[2], pb[3], 1]);
            translate([1.2, 1.2, -1]) cube([pb[2]-2.4, pb[3]-2.4, 3]);
        }
        translate([pb[0] + pb[2]/2, pb[1] + pb[3]/2, plate_t - 0.4])
            linear_extrude(1)
                text("POWER BAY", size = 6, halign = "center", valign = "center");

        // junction hub dock bores
        for (p = [hub_hole_a, hub_hole_b])
            translate([p[0], p[1], -1]) cylinder(d = hub_bore, h = plate_t + 2);

        // ESC velcro straps: three rows (middle row shared)
        for (ry = [esc1_y - 4.5, esc1_y + esc_w + 2, esc2_y + esc_w + 2])
            for (sx = [esc_x + 22, esc_x + 68])
                translate([sx - 11, ry, -1])
                    cube([22, 3.5, plate_t + 2]);

        // fuse + UBEC zip anchors
        zip_pair_y(fuse_o, fuse_sz);
        zip_pair_y(ubec_o, ubec_sz);

        // harness anchors along the top edge (servo + stepper bundles)
        for (x = [70, 100, 130])
            translate([x, plate_y - 12, -1])
                cube([10, 3, plate_t + 2]);
    }

    // battery bay — ported verbatim from battery-tray.scad:
    // rails 26 tall, OPEN left end with a 10 lip (pack lifts over),
    // FIXED right end wall with the lead notch at the SWITCH-SIDE
    // corner: 14 wide, sill +6 — XT60 + balance exit there and turn
    // toward the switch pocket. No opening in the middle.
    translate([bay_o[0] - wall_t, bay_o[1] - wall_t, 0])
        cube([bay_w + 2*wall_t, wall_t, plate_t + wall_h]);
    translate([bay_o[0] - wall_t, bay_o[1] + bay_h, 0])
        cube([bay_w + 2*wall_t, wall_t, plate_t + wall_h]);
    translate([bay_o[0] - wall_t, bay_o[1] - wall_t, 0])
        cube([wall_t, bay_h + 2*wall_t, plate_t + lip_h]);
    difference() {
        translate([bay_o[0] + bay_w, bay_o[1] - wall_t, 0])
            cube([wall_t + 1, bay_h + 2*wall_t, plate_t + wall_h]);
        translate([bay_o[0] + bay_w - 1, bay_o[1] + bay_h - notch_w,
                   plate_t + notch_sill])
            cube([wall_t + 3, notch_w, wall_h]);
    }

    // switch pocket
    translate([sw_o[0] - wall_t, sw_o[1], 0])
        cube([wall_t, sw_w + 2*sw_clear + wall_t, plate_t + sw_wall_h]);
    translate([sw_o[0] + sw_l + 2*sw_clear, sw_o[1], 0])
        cube([wall_t, sw_w + 2*sw_clear + wall_t, plate_t + sw_wall_h]);
    translate([sw_o[0] - wall_t, sw_o[1] + sw_w + 2*sw_clear, 0])
        cube([sw_l + 2*sw_clear + 2*wall_t, wall_t, plate_t + sw_wall_h]);

    posts(xb_center, xb_hole_dx, xb_hole_dy, xb_post_od, xb_bore);
    posts(drv_center, drv_pitch, drv_pitch, drv_post_od, drv_bore);
}

tray();

// ---------- ghosts ----------
%translate([bay_o[0] + 1, bay_o[1] + 1, plate_t]) cube([139, 47, 50]);
%translate([sw_o[0] + 1, sw_o[1] + 1, plate_t]) cube([sw_l - 2, sw_w - 2, sw_h]);
%translate([hub_pos[0], hub_pos[1], plate_t]) cube([hub_l, hub_w, 18]);      // hub body
%translate([hub_pos[0], hub_pos[1] - 13, plate_t]) cube([hub_l, 13, 3]);     // IN apron
%translate([hub_pos[0], hub_pos[1] + hub_w, plate_t]) cube([hub_l, 13, 3]);  // OUT apron
%translate([esc_x, esc1_y, plate_t]) cube([esc_l, esc_w, 12]);
%translate([esc_x, esc2_y, plate_t]) cube([esc_l, esc_w, 12]);
%translate([xb_center[0]-33, xb_center[1]-38, plate_t+post_h]) cube([66, 76, 12]);
%translate([drv_center[0]-20.5, drv_center[1]-20.5, plate_t+post_h]) cube([41, 41, 15]);
%translate([fuse_o[0], fuse_o[1], plate_t]) cube([fuse_sz[0], fuse_sz[1], 12]);
%translate([ubec_o[0], ubec_o[1], plate_t]) cube([ubec_sz[0], ubec_sz[1], 12]);
