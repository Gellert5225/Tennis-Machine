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
// "hub"  = rigid PETG part that bolts to the motor
// "tire" = flexible TPU ring that grips the ball
// "assembly" = preview only, do not export
part = "hub";   // ["hub", "tire", "assembly"]


// ---------- MEASURE THESE ON YOUR MOTOR ----------
// SunnySky X2212. Put calipers on it — do not trust defaults.
shaft_dia        = 3.17;  // MEASURE: motor shaft diameter
bell_bolt_circle = 19;    // MEASURE: diameter of the bolt circle on the motor bell
bell_hole_count  = 4;     // MEASURE: how many mounting holes
bell_hole_dia    = 3.2;   // M3 clearance
bell_boss_dia    = 12;    // MEASURE: diameter of the raised boss on the bell, if any
bell_boss_depth  = 2;     // recess so the hub sits flat


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
shaft_fit    = 0.10;  // added to shaft bore. Increase if too tight.
tire_squeeze = 0.50;  // tire ID is undersized by this so it stretches on
flange_thick = 2.5;   // side lips that stop the tire walking off
setscrew_dia = 3.2;   // M3 grub screws, 2 of them at 90 degrees

$fn = 120;


// ===========================================================openscad.org
//  DERIVED — do not edit
// ===========================================================
hub_od      = wheel_od - 2*tire_thick;   // tire seats on this
flange_od   = hub_od + 4;                // must stay clear of the ball
tire_id     = hub_od - tire_squeeze;
tire_width  = wheel_width - 2*flange_thick;
motor_pitch = wheel_od + pinch_gap;      // motor centre-to-centre spacing
ball_squash = (ball_dia - pinch_gap) / 2;

echo(str("Hub OD .................. ", hub_od, " mm"));
echo(str("Tire ID (print this) .... ", tire_id, " mm"));
echo(str("Tire width .............. ", tire_width, " mm"));
echo(str("Ball compression/side ... ", ball_squash, " mm"));
echo(str(">>> MOTOR CENTRE SPACING  ", motor_pitch, " mm  <<<"));


// ===========================================================
//  HUB  — print in PETG
// ===========================================================
module hub() {
    difference() {
        union() {
            cylinder(d = hub_od, h = wheel_width, center = true);
            // retaining flanges
            translate([0, 0,  (wheel_width - flange_thick)/2])
                cylinder(d = flange_od, h = flange_thick, center = true);
            translate([0, 0, -(wheel_width - flange_thick)/2])
                cylinder(d = flange_od, h = flange_thick, center = true);
        }

        // shaft bore
        cylinder(d = shaft_dia + shaft_fit, h = wheel_width + 10, center = true);

        // recess for the motor bell boss
        translate([0, 0, -wheel_width/2 - 0.1])
            cylinder(d = bell_boss_dia, h = bell_boss_depth + 0.1);

        // motor bell mounting holes
        for (i = [0 : bell_hole_count - 1])
            rotate([0, 0, i * 360/bell_hole_count])
                translate([bell_bolt_circle/2, 0, 0])
                    cylinder(d = bell_hole_dia, h = wheel_width + 10, center = true);

        // two radial grub screws onto the shaft
        for (a = [0, 90])
            rotate([0, 0, a])
                rotate([0, 90, 0])
                    cylinder(d = setscrew_dia, h = hub_od);

        // lightening pockets — reduces mass and print time.
        // Symmetric, so balance is preserved.
        for (i = [0 : 5])
            rotate([0, 0, i * 60])
                translate([hub_od/4 + 2, 0, 0])
                    cylinder(d = 9, h = wheel_width + 10, center = true);
    }
}


// ===========================================================
//  TIRE  — print in TPU 95A
// ===========================================================
module tire() {
    difference() {
        cylinder(d = wheel_od, h = tire_width, center = true);
        cylinder(d = tire_id,  h = tire_width + 2, center = true);

        // shallow circumferential grooves for grip on the felt
        for (z = [-tire_width/4, tire_width/4])
            translate([0, 0, z])
                rotate_extrude()
                    translate([wheel_od/2, 0])
                        circle(d = 2.5);
    }
}


// ===========================================================
//  OUTPUT
// ===========================================================
if (part == "hub")  hub();
if (part == "tire") tire();

if (part == "assembly") {
    // top wheel
    translate([0, 0,  motor_pitch/2]) rotate([90, 0, 0]) { hub(); %tire(); }
    // bottom wheel
    translate([0, 0, -motor_pitch/2]) rotate([90, 0, 0]) { hub(); %tire(); }
    // the ball, in the pinch
    %sphere(d = ball_dia);
}
