// ===========================================================
//  SPIN STAND — minimal motor pedestal for flywheel testing.
//  Print TWO. Not a launch fixture: no gap, no ball — just a
//  safe, stable place for a motor + cup wheel to spin and live
//  during development.
//
//  Motor axis VERTICAL (wheel horizontal): most stable posture,
//  symmetric vibration, low CG. Motor bolts from BELOW with
//  M3x10 + washers — heads hide in the clearance the TPU feet
//  create (dock-kit pucks push into the corner holes; corners
//  also take screws if you'd rather bolt it to a board).
//
//  The cup wheel spins 2.5 mm above the deck — keep it clean —
//  and the phase wires lie in the recessed channel until past
//  the wheel's shadow, where the bullets have full height.
//
//  PRINT: PETG, 0.28 draft, 2-3 walls, 15%, no supports,
//  ~50 min each.  First spins: low throttle, hand or clamp on
//  the plate until you trust it.
// ===========================================================

sz = 100;  t = 6;
motor_dx = 16;  motor_dy = 19;    // MEASURED 5010 base cross
center_hole = 13;
groove_w = 8;  groove_d = 3.5;    // wire channel
corner_hole = 3.4;                // TPU feet or screw-down
$fn = 48;

difference() {
    // rounded plate
    hull() for (x = [-1, 1]) for (y = [-1, 1])
        translate([x*(sz/2 - 8), y*(sz/2 - 8), 0])
            cylinder(r = 8, h = t);

    // motor cross (screws up from below) + centre clearance
    for (p = [[-motor_dx/2, 0], [motor_dx/2, 0],
              [0, -motor_dy/2], [0, motor_dy/2]])
        translate([p[0], p[1], -1]) cylinder(d = 3.2, h = t + 2);
    translate([0, 0, -1]) cylinder(d = center_hole, h = t + 2);

    // wire channel: from the base edge out past the wheel shadow
    translate([16, -groove_w/2, t - groove_d])
        cube([sz/2 - 16 + 1, groove_w, groove_d + 1]);

    // corner holes
    for (x = [-1, 1]) for (y = [-1, 1])
        translate([x*(sz/2 - 8), y*(sz/2 - 8), -1])
            cylinder(d = corner_hole, h = t + 2);
}

// ghosts: motor + cup wheel (band starts 2.5 above the deck)
%translate([0, 0, t]) cylinder(d = 50, h = 12.5);
%translate([0, 0, t + 2.5]) cylinder(d = 64, h = 25);
%color("darkorange", 0.5) translate([0, 0, t + 5])
    difference() { cylinder(d = 80, h = 20);
                   translate([0,0,-1]) cylinder(d = 64, h = 22); }
