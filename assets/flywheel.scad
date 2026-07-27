// ===========================================================
//  Tennis ball machine — flywheel (hub + tire)
//  Vertical-stack topspin configuration
//
//  Each wheel = 1x hub (PETG) + 1x tire (TPU 95A)
//  You need TWO of each: top wheel and bottom wheel.
//
//  Open in OpenSCAD (free). Edit the parameters below,
//  press F5 to preview, F6 to render, then export STL.
// ===========================================================

// ---------- WHAT TO PRINT ----------
// "hub"  = rigid PETG part that bolts to the motor rotor (extruded style)
// "cup"  = shroud-style hub wrapping the rotor — same tire + same bolts
// "tire" = flexible TPU ring that grips the ball
// "assembly" = preview only, do not export
part = "cup";   // ["hub", "cup", "tire", "assembly"]


// ---------- CUP HUB (part = "cup") ----------
// Shroud alternative: the wheel wraps the ø50 rotor instead of standing
// on top of it. Tire seat and bolt pattern are IDENTICAL to the hub, so
// printed tires fit either and the two designs can be A/B tested on the
// same motor. Top-face vents MATCH the rotor's 5-window pattern; cup and
// rotor co-rotate, so window alignment is fixed at assembly — try all
// four bolt orientations and keep the best overlap (4-fold bolts vs
// 5-fold vents can sit up to 18° off; worst case still ~70% open).
motor_rotor_od = 50;    // MEASURED: rotor can diameter
skirt_clear    = 0.25;  // radial gap to the can (it co-rotates — this gap
                        //   is print tolerance, not rub protection)
skirt_depth    = 13;    // Can depth measured ~12.5 (rough): skirt stops
                        //   2.5 mm above the spinning-to-stationary seam.
                        //   Formula: skirt_depth = can_depth − 2 (tighten
                        //   the margin only after a precise can measure).
                        //   To go DEEPER than the seam later: confirm the
                        //   base OD is smaller than the can, and give A3
                        //   a wire groove under the rim.
vent_count     = 5;     // matches the rotor windows
vent_spoke     = 3.65;  // MEASURED: spoke width between rotor windows
vent_r_out     = 21;    // MEASURED: windows end 4 mm in from the ø50 wall
vent_r_in      = 10;    // MEASURE: radius where the rotor's centre disc
                        //   ends and its windows begin


// ---------- MOTOR MOUNT: 5010 PANCAKE, ROTOR-TOP BOLTS ----------
// JeeFly 5010 750KV. The rotor top carries 4x M3 threaded holes; the
// hub bolts straight on with M3x12 from the assortment. Values below
// come from the GoolRC 5010 family sheet — VERIFY the three marked
// numbers against the JeeFly listing drawing before printing.
rotor_bolt_circle = 12;   // VERIFY: rotor-top hole circle diameter
rotor_hole_count  = 4;
rotor_hole_dia    = 3.2;  // M3 clearance
rotor_stub_dia    = 5;    // MEASURED: a ø3 shaft stub protrudes at the rotor
rotor_stub_depth  = 6;    //   centre. ø5 x 6 pocket swallows it with margin.
                          //   Geometry sanity: pocket wall to screw-hole edge
                          //   = 1.9 mm; and the pocket lives in the hub's
                          //   inner 8 mm while the counterbores occupy the
                          //   outer 17 mm — they never meet in Z, so the
                          //   centre-zone crowding class is impossible here.
                          //   If the stub is TALLER than ~5 mm, flag it
                          //   BEFORE printing (relief strategy changes).
cbore_dia         = 6.0;  // clears an M3 socket head (ø5.5) + driver
cbore_depth       = 17;   // TUNED for M3x12: engages ~4 mm of rotor thread
                          // without poking past the rotor plate into the
                          // windings. If you change screw length:
                          // cbore_depth = wheel_width - (screw_len - 4)


// ---------- BALL + PINCH GEOMETRY ----------
ball_dia   = 67;   // regulation tennis ball
pinch_gap  = 60;   // surface-to-surface gap between the two tires
                   //   67 = no grip, 55 = very aggressive
                   //   60 gives 3.5 mm compression per side. Start here.

// ---------- WHEEL SIZE ----------
wheel_od   = 80;   // outer diameter of the finished wheel (tire surface)
wheel_width = 25;  // how wide the wheel is
tire_thick = 8;    // radial thickness of the TPU tire


// ---------- FIT / TOLERANCE ----------
tire_squeeze = 0.50;  // tire ID is undersized by this so it stretches on
flange_thick = 2.5;   // side lips that stop the tire walking off
tread_serrations = 48; // axial V-grooves across the tread — edges bite the
                       //   felt in the drive direction. 0 = smooth tread.
serration_depth  = 0.6;

$fn = 120;


// ===========================================================
//  DERIVED — do not edit
// ===========================================================
hub_od      = wheel_od - 2*tire_thick;   // tire seats on this
flange_od   = hub_od + 4;                // must stay clear of the ball
chamfer_h   = (flange_od - hub_od)/2;    // 45° self-supporting transition
tire_id     = hub_od - tire_squeeze;
tire_width  = wheel_width - 2*flange_thick;
motor_pitch = wheel_od + pinch_gap;      // motor centre-to-centre spacing
ball_squash = (ball_dia - pinch_gap) / 2;

// cup derivations
disc_t          = wheel_width - skirt_depth;   // solid top section of the cup
vent_arc        = 360/vent_count
                  - (vent_spoke / ((vent_r_in + vent_r_out)/2)) * 180/PI;
cup_cbore_depth = disc_t - 8;                  // M3x12 -> ~4 mm engagement

echo(str("Hub OD .................. ", hub_od, " mm"));
echo(str("Tire ID (print this) .... ", tire_id, " mm"));
echo(str("Tire width .............. ", tire_width, " mm"));
echo(str("Ball compression/side ... ", ball_squash, " mm"));
echo(str("Cup: disc ", disc_t, " / skirt wall ",
         (hub_od - motor_rotor_od - 2*skirt_clear)/2, " / vent arc ",
         vent_arc, " deg"));
echo(str(">>> MOTOR CENTRE SPACING  ", motor_pitch, " mm  <<<"));;


// ===========================================================
//  SHARED OUTER BODY — tire seat, flanges, chamfers
//  (identical for hub and cup, so tires interchange)
// ===========================================================
module wheel_body() {
    cylinder(d = hub_od, h = wheel_width, center = true);
    // retaining flanges
    translate([0, 0,  (wheel_width - flange_thick)/2])
        cylinder(d = flange_od, h = flange_thick, center = true);
    translate([0, 0, -(wheel_width - flange_thick)/2])
        cylinder(d = flange_od, h = flange_thick, center = true);
    // 45° chamfer cones into both flanges (the bare 90° step sagged)
    translate([0, 0, wheel_width/2 - flange_thick - chamfer_h])
        cylinder(d1 = hub_od, d2 = flange_od, h = chamfer_h + 0.01);
    translate([0, 0, -wheel_width/2 + flange_thick - 0.01])
        cylinder(d1 = flange_od, d2 = hub_od, h = chamfer_h + 0.01);
}


// ===========================================================
//  HUB  — print in PETG
// ===========================================================
module hub() {
    difference() {
        wheel_body();

        // centre relief over the rotor's shaft stub / retaining clip.
        if (rotor_stub_dia > 0)
            translate([0, 0, -wheel_width/2 - 0.1])
                cylinder(d = rotor_stub_dia, h = rotor_stub_depth + 0.1);

        // 4x M3 into the rotor-top threads, counterbored from the outer
        // face so M3x12 socket screws from the assortment reach the rotor
        for (i = [0 : rotor_hole_count - 1])
            rotate([0, 0, i * 360/rotor_hole_count])
                translate([rotor_bolt_circle/2, 0, 0]) {
                    cylinder(d = rotor_hole_dia, h = wheel_width + 10, center = true);
                    translate([0, 0, wheel_width/2 - cbore_depth])
                        cylinder(d = cbore_dia, h = cbore_depth + 5);
                }

        // lightening pockets — reduces mass and print time.
        // Symmetric, so balance is preserved.
        for (i = [0 : 5])
            rotate([0, 0, i * 60])
                translate([hub_od/4 + 2, 0, 0])
                    cylinder(d = 9, h = wheel_width + 10, center = true);
    }
}


// ===========================================================
//  CUP  — shroud-style hub, print in PETG, TOP FACE DOWN
//  (skirt opening prints upward; counterbore floors are the
//  only bridges and they're ø6 — trivial)
// ===========================================================
module cup() {
    difference() {
        wheel_body();

        // skirt bore: wraps the rotor can from the inner face up
        translate([0, 0, -wheel_width/2 - 0.1])
            cylinder(d = motor_rotor_od + 2*skirt_clear, h = skirt_depth + 0.1);

        // stub relief in the ceiling (the face that lands on the rotor)
        translate([0, 0, -wheel_width/2 + skirt_depth - 0.1])
            cylinder(d = rotor_stub_dia, h = rotor_stub_depth + 0.1);

        // vents through the whole disc, matching the rotor's windows.
        // All centre features (bolts r6, cbores to r9, stub r2.5) live
        // inside vent_r_in, so no rotation can create a collision.
        for (i = [0 : vent_count - 1])
            rotate([0, 0, i*360/vent_count - vent_arc/2])
                translate([0, 0, -wheel_width/2 + skirt_depth - 0.1])
                    rotate_extrude(angle = vent_arc)
                        translate([vent_r_in, 0])
                            square([vent_r_out - vent_r_in, disc_t + 0.2]);

        // rotor bolts + shallow counterbores from the outer face
        for (i = [0 : rotor_hole_count - 1])
            rotate([0, 0, i * 360/rotor_hole_count])
                translate([rotor_bolt_circle/2, 0, 0]) {
                    translate([0, 0, -wheel_width/2 + skirt_depth - 0.1])
                        cylinder(d = rotor_hole_dia, h = disc_t + 0.2);
                    translate([0, 0, wheel_width/2 - cup_cbore_depth])
                        cylinder(d = cbore_dia, h = cup_cbore_depth + 5);
                }
    }
}


// ===========================================================
//  TIRE  — print in TPU 95A
// ===========================================================
module tire() {
    difference() {
        cylinder(d = wheel_od, h = tire_width, center = true);
        cylinder(d = tire_id,  h = tire_width + 2, center = true);

        // 45° ID chamfers mirroring the hub's flange ramps, so the tire
        // nests with the SAME 0.5 mm squeeze on the flats AND the ramps.
        // Also keys the tire laterally against walking off sideways.
        translate([0, 0, tire_width/2 - chamfer_h])
            cylinder(d1 = tire_id, d2 = tire_id + 2*chamfer_h, h = chamfer_h + 0.01);
        translate([0, 0, -tire_width/2 - 0.01])
            cylinder(d1 = tire_id + 2*chamfer_h, d2 = tire_id, h = chamfer_h + 0.01);

        // shallow circumferential grooves for grip on the felt
        for (z = [-tire_width/4, tire_width/4])
            translate([0, 0, z])
                rotate_extrude()
                    translate([wheel_od/2, 0])
                        circle(d = 2.5);

        // axial serrations: diamond prisms cut across the tread. Their
        // edges run parallel to the axis = perpendicular to rotation,
        // biting the felt in the drive direction. Symmetric -> balanced.
        if (tread_serrations > 0)
            for (i = [0 : tread_serrations - 1])
                rotate([0, 0, i * 360/tread_serrations])
                    translate([wheel_od/2 + 1.2*sqrt(2)/2 - serration_depth, 0, 0])
                        rotate([0, 0, 45])
                            cube([1.2, 1.2, tire_width + 2], center = true);
    }
}


// ===========================================================
//  OUTPUT
// ===========================================================
if (part == "hub")  hub();
if (part == "cup")  cup();
if (part == "tire") tire();

if (part == "assembly") {
    // top wheel
    translate([0, 0,  motor_pitch/2]) rotate([90, 0, 0]) { hub(); %tire(); }
    // bottom wheel
    translate([0, 0, -motor_pitch/2]) rotate([90, 0, 0]) { hub(); %tire(); }
    // the ball, in the pinch
    %sphere(d = ball_dia);
}
