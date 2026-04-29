#!/usr/bin/env python3
"""
Generate faithful SVG ports of the app's illustrated berry cluster.

Source: Blueberries/Views/IllustratedBerryClusterView.swift (the cluster used
on HomeView's hero). This is the richer, radial-gradient illustration with
green leaves and a dark-navy palette — NOT the flat kawaii `BerryClusterView`
used in the walkthrough.

Outputs:
    web/public/berry-smile.svg
    web/public/berry-happy.svg
    web/public/berry-wink.svg
    web/public/berry-cluster.svg

Re-run when IllustratedBerryClusterView.swift changes so the website stays in
lockstep with the app.
"""
from __future__ import annotations

import math
import pathlib

# ---- Palette (from IllustratedBerryClusterView.swift BerryPalette) --------

def rgb_hex(r: float, g: float, b: float) -> str:
    return "#{:02X}{:02X}{:02X}".format(
        round(r * 255), round(g * 255), round(b * 255)
    )

BODY_DARK  = rgb_hex(0.19, 0.29, 0.51)  # #314A83
BODY_MID   = rgb_hex(0.31, 0.42, 0.63)  # #4F6AA2
BODY_BASE  = rgb_hex(0.38, 0.51, 0.72)  # #6181B8
BODY_LIGHT = rgb_hex(0.60, 0.74, 0.89)  # #99BCE1

EYE        = rgb_hex(0.22, 0.15, 0.29)  # #38274B
CHEEK      = rgb_hex(0.82, 0.51, 0.50)  # #D18482
MOUTH_DARK = rgb_hex(0.37, 0.14, 0.26)  # #602441
MOUTH_RED  = rgb_hex(0.93, 0.44, 0.42)  # #EF716B

LEAF_LIGHT = rgb_hex(0.67, 0.82, 0.40)  # #ABD167
LEAF_MID   = rgb_hex(0.50, 0.66, 0.28)  # #80A847
LEAF_DARK  = rgb_hex(0.33, 0.49, 0.20)  # #547D33


# ---- Helpers --------------------------------------------------------------

def f(v: float) -> str:
    """Format a number for SVG — strip trailing zeros but keep precision."""
    return ("{:.3f}".format(v)).rstrip("0").rstrip(".")


# Each call-site gets a unique radial-gradient id; otherwise clones share one
# stale `<defs>` entry.
_grad_counter = [0]


def _next_grad_id(prefix: str) -> str:
    _grad_counter[0] += 1
    return f"{prefix}-{_grad_counter[0]}"


# ---- Berry body ----------------------------------------------------------

def body_gradient_def(grad_id: str, cx: float, cy: float, radius: float) -> str:
    """RadialGradient matching the Swift `RadialGradient(..., startRadius: 0, endRadius: size*0.62)`.
    SwiftUI distributes three unanchored colours at 0%, 50%, 100%.
    """
    return (
        f'<radialGradient id="{grad_id}" cx="{f(cx)}" cy="{f(cy)}" r="{f(radius)}" '
        f'gradientUnits="userSpaceOnUse">'
        f'<stop offset="0%" stop-color="{BODY_LIGHT}"/>'
        f'<stop offset="50%" stop-color="{BODY_BASE}"/>'
        f'<stop offset="100%" stop-color="{BODY_MID}"/>'
        '</radialGradient>'
    )


def calyx_path(cx: float, cy: float, width: float, height: float) -> str:
    """10-vertex star — 5 outer points, 5 inner valleys, compressed vertically."""
    r_outer = min(width, height) / 2
    r_inner = r_outer * 0.45
    y_scale = 0.8
    pts = []
    for i in range(10):
        r = r_outer if i % 2 == 0 else r_inner
        angle = (i * math.pi / 5) - math.pi / 2
        x = cx + math.cos(angle) * r
        y = cy + math.sin(angle) * r * y_scale
        pts.append((x, y))
    d = "M" + " L".join(f"{f(p[0])},{f(p[1])}" for p in pts) + " Z"
    return f'<path d="{d}" fill="{BODY_DARK}"/>'


# ---- Face ----------------------------------------------------------------

def eye_element(cx: float, cy: float, size: float) -> list[str]:
    """Open eye = dark ellipse + white offset shine."""
    eye_rx = size * 0.425
    eye_ry = size / 2
    shine_rx = size * 0.175
    shine_ry = size * 0.19
    shine_dx = -size * 0.12
    shine_dy = -size * 0.18
    return [
        f'<ellipse cx="{f(cx)}" cy="{f(cy)}" rx="{f(eye_rx)}" ry="{f(eye_ry)}" fill="{EYE}"/>',
        f'<ellipse cx="{f(cx + shine_dx)}" cy="{f(cy + shine_dy)}" rx="{f(shine_rx)}" ry="{f(shine_ry)}" fill="white"/>',
    ]


def closed_eye_arc(cx: float, cy: float, width: float, height: float, stroke_w: float) -> str:
    """Upside-down U — both endpoints on the baseline, curve bulges upward."""
    min_x = cx - width / 2
    max_x = cx + width / 2
    min_y = cy - height / 2
    max_y = cy + height / 2
    ctrl_y = min_y - height * 0.2
    d = f"M{f(min_x)},{f(max_y)} Q{f(cx)},{f(ctrl_y)} {f(max_x)},{f(max_y)}"
    return (
        f'<path d="{d}" fill="none" stroke="{EYE}" '
        f'stroke-width="{f(stroke_w)}" stroke-linecap="round"/>'
    )


def smile_arc(cx: float, cy: float, width: float, height: float, stroke_w: float) -> str:
    """The wink berry's closed-mouth curve.

    Swift's SmileArc draws `move(0, minY)` → `quadCurve(width, minY)` with
    control `(midX, maxY + h*0.2)`. In a CoreGraphics/top-left-origin frame
    that puts the endpoints at the top of the frame and the control below it
    (downward bulge). The frame is then `.offset(y: size*0.22)` so it sits
    below the face.
    """
    min_x = cx - width / 2
    max_x = cx + width / 2
    top_y = cy - height / 2
    ctrl_y = cy + height / 2 + height * 0.2
    d = f"M{f(min_x)},{f(top_y)} Q{f(cx)},{f(ctrl_y)} {f(max_x)},{f(top_y)}"
    return (
        f'<path d="{d}" fill="none" stroke="{MOUTH_DARK}" '
        f'stroke-width="{f(stroke_w)}" stroke-linecap="round"/>'
    )


def mouth_open(cx: float, cy: float, width: float, height: float, fill: str) -> str:
    """MouthOpen shape. Swift draws:
        move(0,0) → quadCurve(w,0) ctrl(mid, maxY*1.6)    # bottom bulges down
        quadCurve(0,0) ctrl(mid, maxY*0.25)                # top dips gently
    The frame's origin (0,0) sits at the top corners of the mouth in Swift
    (CoreGraphics top-down), so in our global-coord SVG we position it so the
    top edge is at cy - height/2.
    """
    min_x = cx - width / 2
    max_x = cx + width / 2
    top_y = cy - height / 2
    bottom_ctrl_y = top_y + height * 1.6
    top_ctrl_y = top_y + height * 0.25
    d = (f"M{f(min_x)},{f(top_y)} "
         f"Q{f(cx)},{f(bottom_ctrl_y)} {f(max_x)},{f(top_y)} "
         f"Q{f(cx)},{f(top_ctrl_y)} {f(min_x)},{f(top_y)} Z")
    return f'<path d="{d}" fill="{fill}"/>'


# ---- Single berry ---------------------------------------------------------

def berry(expression: str, cx: float, cy: float, size: float, *, defs: list[str]) -> list[str]:
    """Return <g>-wrapped shape elements for one IllustratedBerry centred at
    (cx, cy) in its parent coord system, sized `size` × `size`.
    """
    r = size / 2
    # Radial gradient centre is UnitPoint(0.38, 0.35) relative to the frame
    # (which spans cx-r..cx+r, cy-r..cy+r). Origin of UnitPoint is top-left.
    grad_cx = cx - r + size * 0.38
    grad_cy = cy - r + size * 0.35
    grad_radius = size * 0.62
    grad_id = _next_grad_id("berry-grad")
    defs.append(body_gradient_def(grad_id, grad_cx, grad_cy, grad_radius))

    out: list[str] = []
    # 1. Body — gradient-filled circle.
    out.append(f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="url(#{grad_id})"/>')
    # 2. Calyx crown — 10-point star at (cx, cy - size*0.44).
    calyx_cx = cx
    calyx_cy = cy - size * 0.44
    out.append(calyx_path(calyx_cx, calyx_cy, size * 0.44, size * 0.26))
    # 3. Primary specular highlight — rotated ellipse upper-left.
    hl_cx = cx - size * 0.30
    hl_cy = cy - size * 0.30
    out.append(
        f'<ellipse cx="{f(hl_cx)}" cy="{f(hl_cy)}" rx="{f(size * 0.06)}" '
        f'ry="{f(size * 0.03)}" fill="{BODY_LIGHT}" '
        f'transform="rotate(-28 {f(hl_cx)} {f(hl_cy)})"/>'
    )
    # 3b. Secondary highlight — only on happy.
    if expression == "happy":
        hl2_cx = cx - size * 0.36
        hl2_cy = cy - size * 0.20
        out.append(
            f'<ellipse cx="{f(hl2_cx)}" cy="{f(hl2_cy)}" rx="{f(size * 0.03)}" '
            f'ry="{f(size * 0.03)}" fill="{BODY_LIGHT}" '
            f'transform="rotate(-20 {f(hl2_cx)} {f(hl2_cy)})"/>'
        )

    # 4. Cheeks — Swift uses different opacities for left vs right.
    cheek_w = size * 0.16
    cheek_h = size * 0.10
    left_cheek_cx = cx - size * 0.30
    right_cheek_cx = cx + size * 0.30
    cheeks_cy = cy + size * 0.14
    out.append(
        f'<ellipse cx="{f(left_cheek_cx)}" cy="{f(cheeks_cy)}" rx="{f(cheek_w / 2)}" '
        f'ry="{f(cheek_h / 2)}" fill="{CHEEK}" opacity="0.75"/>'
    )
    out.append(
        f'<ellipse cx="{f(right_cheek_cx)}" cy="{f(cheeks_cy)}" rx="{f(cheek_w / 2)}" '
        f'ry="{f(cheek_h / 2)}" fill="{CHEEK}" opacity="0.60"/>'
    )

    # 5. Eyes. Wink → both eyes are closed arcs.
    eye_offset_x = size * 0.16
    if expression == "wink":
        stroke_w = size * 0.04
        arc_w = size * 0.18
        arc_h = size * 0.10
        arc_cy = cy + size * 0.03
        out.append(closed_eye_arc(cx - eye_offset_x, arc_cy, arc_w, arc_h, stroke_w))
        out.append(closed_eye_arc(cx + eye_offset_x, arc_cy, arc_w, arc_h, stroke_w))
    else:
        eye_size = size * 0.14
        eye_cy = cy + size * 0.02
        out.extend(eye_element(cx - eye_offset_x, eye_cy, eye_size))
        out.extend(eye_element(cx + eye_offset_x, eye_cy, eye_size))

    # 6. Mouth — per-expression.
    mouth_cy = cy + size * 0.22
    if expression == "happy":
        out.append(mouth_open(cx, mouth_cy, size * 0.22, size * 0.13, MOUTH_DARK))
        # Tongue sits inside the mouth, slightly below centre.
        tongue_w = size * 0.11
        tongue_h = size * 0.05
        tongue_cy = mouth_cy + size * 0.03
        out.append(
            f'<ellipse cx="{f(cx)}" cy="{f(tongue_cy)}" rx="{f(tongue_w / 2)}" '
            f'ry="{f(tongue_h / 2)}" fill="{MOUTH_RED}" opacity="0.85"/>'
        )
    elif expression == "smile":
        out.append(mouth_open(cx, mouth_cy, size * 0.17, size * 0.10, MOUTH_DARK))
        tongue_w = size * 0.08
        tongue_h = size * 0.04
        tongue_cy = mouth_cy + size * 0.02
        out.append(
            f'<ellipse cx="{f(cx)}" cy="{f(tongue_cy)}" rx="{f(tongue_w / 2)}" '
            f'ry="{f(tongue_h / 2)}" fill="{MOUTH_RED}" opacity="0.80"/>'
        )
    elif expression == "wink":
        stroke_w = size * 0.035
        out.append(smile_arc(cx, mouth_cy, size * 0.2, size * 0.09, stroke_w))

    return out


# ---- Leaves ---------------------------------------------------------------

def leaf_path(x: float, y: float, w: float, h: float) -> str:
    """Swift Leaf shape in a `w` × `h` rect with top-left at (x, y)."""
    base_x = x + w * 0.5
    base_y = y + h
    tip_x = x + w * 0.5
    tip_y = y + h * 0.02
    # Left side curve.
    c1_left = (x + w * -0.12, y + h * 0.70)
    c2_left = (x + w * 0.05, y + h * 0.10)
    # Right side curve.
    c1_right = (x + w * 0.95, y + h * 0.10)
    c2_right = (x + w * 1.12, y + h * 0.70)
    d = (f"M{f(base_x)},{f(base_y)} "
         f"C{f(c1_left[0])},{f(c1_left[1])} {f(c2_left[0])},{f(c2_left[1])} {f(tip_x)},{f(tip_y)} "
         f"C{f(c1_right[0])},{f(c1_right[1])} {f(c2_right[0])},{f(c2_right[1])} {f(base_x)},{f(base_y)} Z")
    return d


def leaf_veins_path(x: float, y: float, w: float, h: float) -> str:
    """Swift LeafVeins shape — midrib + 3 pairs of side ribs."""
    parts = []
    # Central midrib.
    parts.append(
        f"M{f(x + w * 0.5)},{f(y + h * 0.96)} "
        f"Q{f(x + w * 0.52)},{f(y + h * 0.5)} {f(x + w * 0.5)},{f(y + h * 0.08)}"
    )
    # Side ribs.
    for rib_y in (0.78, 0.58, 0.38):
        end_y = rib_y - 0.08
        ctl_y = rib_y - 0.02
        # Left rib.
        parts.append(
            f"M{f(x + w * 0.5)},{f(y + h * rib_y)} "
            f"Q{f(x + w * 0.32)},{f(y + h * ctl_y)} {f(x + w * 0.18)},{f(y + h * end_y)}"
        )
        # Right rib.
        parts.append(
            f"M{f(x + w * 0.5)},{f(y + h * rib_y)} "
            f"Q{f(x + w * 0.68)},{f(y + h * ctl_y)} {f(x + w * 0.82)},{f(y + h * end_y)}"
        )
    return " ".join(parts)


def styled_leaf(cx: float, cy_base: float, w: float, h: float, rotation: float,
                scale: float, defs: list[str]) -> list[str]:
    """Leaf rooted at (cx, cy_base). The Swift `StyledLeaf` uses a gradient fill
    plus dark veins and is rotated around the bottom-centre of its frame.
    """
    grad_id = _next_grad_id("leaf-grad")
    # LinearGradient from top to bottom in the leaf's local coords.
    defs.append(
        f'<linearGradient id="{grad_id}" x1="0" y1="0" x2="0" y2="1">'
        f'<stop offset="0%" stop-color="{LEAF_LIGHT}"/>'
        f'<stop offset="50%" stop-color="{LEAF_MID}"/>'
        f'<stop offset="100%" stop-color="{LEAF_DARK}"/>'
        '</linearGradient>'
    )
    # Draw at leaf-local (0,0)..(w,h) then transform: translate the bottom-
    # centre to (cx, cy_base), rotate around it, then adjust so local (w/2, h)
    # = (0, 0) pre-rotation in local coords.
    fill_d = leaf_path(-w / 2, -h, w, h)
    veins_d = leaf_veins_path(-w / 2, -h, w, h)
    vein_stroke = 1.0 * scale
    group_transform = f"translate({f(cx)} {f(cy_base)}) rotate({f(rotation)})"
    return [
        f'<g transform="{group_transform}">',
        f'  <path d="{fill_d}" fill="url(#{grad_id})"/>',
        f'  <path d="{veins_d}" fill="none" stroke="{LEAF_DARK}" '
        f'stroke-opacity="0.65" stroke-width="{f(vein_stroke)}" stroke-linecap="round"/>',
        '</g>',
    ]


def stem_path(cx: float, cy_base: float, w: float, h: float) -> str:
    """Swift Stem — curves up-and-right from the base."""
    base = (cx, cy_base)
    tip = (cx + w * 0.45, cy_base - h)   # w*0.95 relative to left edge = +0.45 from centre
    c1  = (cx - w * 0.05, cy_base - h * 0.45)  # w*0.45 from left = -0.05 from centre
    c2  = (cx, cy_base - h * 0.85)             # w*0.5 from left = 0 from centre
    return (f"M{f(base[0])},{f(base[1])} "
            f"C{f(c1[0])},{f(c1[1])} {f(c2[0])},{f(c2[1])} {f(tip[0])},{f(tip[1])}")


def top_foliage(cx: float, cy_anchor: float, scale: float, rotation: float, defs: list[str]) -> list[str]:
    """Swift `TopFoliage` — stem + small accent leaf + two big leaves, all
    anchored at a common base.
    """
    out: list[str] = [f'<g transform="translate({f(cx)} {f(cy_anchor)}) rotate({f(rotation)})">']

    stem_w = 10 * scale
    stem_h = 34 * scale
    stem_stroke = 6 * scale
    out.append(
        f'  <path d="{stem_path(0, 0, stem_w, stem_h)}" fill="none" '
        f'stroke="{LEAF_MID}" stroke-width="{f(stem_stroke)}" stroke-linecap="round"/>'
    )

    # Accent leaf: 22x30, rotated -60° around its bottom, offset (-3, -16) from anchor.
    out.extend("  " + el for el in styled_leaf(
        cx=-3 * scale, cy_base=-16 * scale,
        w=22 * scale, h=30 * scale,
        rotation=-60, scale=scale, defs=defs,
    ))
    # Left big leaf: 66x90, rotated -48°, offset (-18, 16).
    out.extend("  " + el for el in styled_leaf(
        cx=-18 * scale, cy_base=16 * scale,
        w=66 * scale, h=90 * scale,
        rotation=-48, scale=scale, defs=defs,
    ))
    # Right big leaf mirror.
    out.extend("  " + el for el in styled_leaf(
        cx=18 * scale, cy_base=16 * scale,
        w=66 * scale, h=90 * scale,
        rotation=48, scale=scale, defs=defs,
    ))

    out.append('</g>')
    return out


def bottom_foliage(cx: float, cy_anchor: float, scale: float, rotation: float, defs: list[str]) -> list[str]:
    """Swift `BottomFoliage` — two small leaves peeking out below the cluster,
    rotated ~158° so they point downward.
    """
    out: list[str] = [f'<g transform="translate({f(cx)} {f(cy_anchor)}) rotate({f(rotation)})">']

    out.extend("  " + el for el in styled_leaf(
        cx=-20 * scale, cy_base=-6 * scale,
        w=44 * scale, h=62 * scale,
        rotation=-158, scale=scale, defs=defs,
    ))
    out.extend("  " + el for el in styled_leaf(
        cx=20 * scale, cy_base=-6 * scale,
        w=44 * scale, h=62 * scale,
        rotation=158, scale=scale, defs=defs,
    ))

    out.append('</g>')
    return out


# ---- Single-berry SVGs (no leaves) ----------------------------------------

def build_single_svg(expression: str) -> str:
    size = 100.0
    defs: list[str] = []
    elements = berry(expression, cx=size / 2, cy=size / 2, size=size, defs=defs)
    lines = [
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">',
    ]
    if defs:
        lines.append('  <defs>')
        lines.extend(f'    {d}' for d in defs)
        lines.append('  </defs>')
    lines.extend(f'  {el}' for el in elements)
    lines.append('</svg>')
    lines.append('')
    return "\n".join(lines)


# ---- Cluster SVG ----------------------------------------------------------

def build_cluster_svg() -> str:
    """Mirror IllustratedBerryClusterView at its rest frame (phase=false).
    Canvas: 300x200, scale = 1 (matching the scale math in the Swift view).
    Rest-frame offsets and rotations are hard-coded from the Swift source.
    """
    vb_w, vb_h = 300, 200
    cx, cy = vb_w / 2, vb_h / 2  # ZStack centre
    scale = 1.0
    defs: list[str] = []
    body_lines: list[str] = []

    # --- Foliage behind everything --------------------------------------
    # TopFoliage: offset y = (false: -30) * scale - 24 = -54, rotation 3°.
    top_y = cy + (-30 * scale - 24)
    body_lines.extend(top_foliage(cx=cx, cy_anchor=top_y, scale=scale, rotation=3, defs=defs))

    # BottomFoliage: offset y = 18 * scale, rotation -2°.
    bot_y = cy + (18 * scale)
    body_lines.extend(bottom_foliage(cx=cx, cy_anchor=bot_y, scale=scale, rotation=-2, defs=defs))

    # --- Side berries (drawn before the centre) -------------------------
    # Smile (size 80, x=-70, y=4+22=26, rot -3°).
    _emit_berry_with_rotation(
        body_lines, defs,
        expression="smile",
        cx=cx - 70 * scale,
        cy=cy + 26 * scale,
        size=80 * scale,
        rotation=-3,
    )

    # Wink (size 76, x=70, y=6+24=30, rot 4°).
    _emit_berry_with_rotation(
        body_lines, defs,
        expression="wink",
        cx=cx + 70 * scale,
        cy=cy + 30 * scale,
        size=76 * scale,
        rotation=4,
    )

    # --- Centre berry (happy) with drop-shadow -------------------------
    # size 102, x=0, y=-4+10=6, no rotation. Shadow: bodyDark @ 0.25, radius 8, dy 4.
    filter_id = "happy-shadow"
    defs.append(
        f'<filter id="{filter_id}" x="-50%" y="-50%" width="200%" height="200%">'
        f'<feDropShadow dx="0" dy="{f(4 * scale)}" stdDeviation="{f(8 * scale / 2)}" '
        f'flood-color="{BODY_DARK}" flood-opacity="0.25"/>'
        '</filter>'
    )
    happy_cx = cx
    happy_cy = cy + 6 * scale
    happy_size = 102 * scale
    body_lines.append(f'<g filter="url(#{filter_id})">')
    body_lines.extend(f'  {el}' for el in berry("happy", cx=happy_cx, cy=happy_cy, size=happy_size, defs=defs))
    body_lines.append('</g>')

    # --- Assemble ------------------------------------------------------
    lines = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {vb_w} {vb_h}">']
    lines.append('  <defs>')
    lines.extend(f'    {d}' for d in defs)
    lines.append('  </defs>')
    lines.extend(f'  {el}' for el in body_lines)
    lines.append('</svg>')
    lines.append('')
    return "\n".join(lines)


def _emit_berry_with_rotation(out: list[str], defs: list[str], *,
                               expression: str, cx: float, cy: float,
                               size: float, rotation: float) -> None:
    """Wrap a berry in a `<g transform="rotate(° at cx,cy)">` if needed."""
    if rotation == 0:
        out.extend(berry(expression, cx=cx, cy=cy, size=size, defs=defs))
    else:
        out.append(f'<g transform="rotate({f(rotation)} {f(cx)} {f(cy)})">')
        out.extend(f'  {el}' for el in berry(expression, cx=cx, cy=cy, size=size, defs=defs))
        out.append('</g>')


# ---- Entry point ---------------------------------------------------------

def main() -> None:
    out_dir = pathlib.Path(__file__).resolve().parent.parent / "web" / "public"
    for expr in ("smile", "happy", "wink"):
        # Reset the gradient counter between files so diffs stay stable.
        _grad_counter[0] = 0
        path = out_dir / f"berry-{expr}.svg"
        path.write_text(build_single_svg(expr))
        print(f"wrote {path.relative_to(out_dir.parent.parent)} ({path.stat().st_size} bytes)")

    _grad_counter[0] = 0
    cluster = out_dir / "berry-cluster.svg"
    cluster.write_text(build_cluster_svg())
    print(f"wrote {cluster.relative_to(out_dir.parent.parent)} ({cluster.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
