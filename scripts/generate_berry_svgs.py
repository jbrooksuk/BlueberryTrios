#!/usr/bin/env python3
"""
Generate faithful SVG ports of:
- Blueberries/Views/BlueberryView.swift         → berry-{smile,happy,wink}.svg
- Blueberries/Views/BerryClusterView.swift      → berry-cluster.svg

Mirrors the Canvas drawing logic exactly: same shape primitives, same ratios,
same colours. Re-run when those Swift views change to keep the website in
lockstep with the app.
"""
from __future__ import annotations

import math
import pathlib

# ---- Palette (from Blueberries/Views/BlueberryView.swift + Theme.swift) ---

def rgb_hex(r: float, g: float, b: float) -> str:
    return "#{:02X}{:02X}{:02X}".format(
        round(r * 255), round(g * 255), round(b * 255)
    )

BERRY_BODY = rgb_hex(0.45, 0.48, 0.64)    # #737AA3
BERRY_LIGHT = rgb_hex(0.55, 0.58, 0.72)   # #8C94B8
BERRY_SHADOW = rgb_hex(0.32, 0.35, 0.50)  # #525980
CALYX_COLOR = rgb_hex(0.30, 0.34, 0.50)   # #4D5780
BLUSH_COLOR = rgb_hex(0.94, 0.52, 0.48)   # #F0857A
BLACK_EYE = "rgba(0,0,0,0.85)"
BLACK_MOUTH = "rgba(0,0,0,0.75)"
# Theme.berryBlue light mode, from Assets.xcassets/BerryBlue.colorset.
BERRY_BLUE = rgb_hex(0.208, 0.518, 0.894)  # #3584E4

# ---- Canvas geometry inside a single BlueberryView frame ------------------
# All helpers take a frame size `s` and derive their geometry; the berry body
# centre lands at (s/2, s*0.55) and its radius is s*0.40. This is identical to
# the Swift Canvas drawing in BlueberryView.body.


def f(v: float) -> str:
    """Format a number for SVG — strip trailing zeros but keep precision."""
    return ("{:.3f}".format(v)).rstrip("0").rstrip(".")


def ellipse(cx: float, cy: float, rx: float, ry: float, fill: str, opacity: float | None = None) -> str:
    attrs = f'cx="{f(cx)}" cy="{f(cy)}" rx="{f(rx)}" ry="{f(ry)}" fill="{fill}"'
    if opacity is not None:
        attrs += f' opacity="{opacity}"'
    return f"<ellipse {attrs}/>"


def rect_to_ellipse(x: float, y: float, w: float, h: float, fill: str, opacity: float | None = None) -> str:
    """Swift's `Path(ellipseIn: CGRect)` uses a rect; convert to centre+radii."""
    return ellipse(x + w / 2, y + h / 2, w / 2, h / 2, fill, opacity)


def petal_path(angle_deg: float, cx: float, cy: float, size: float) -> str:
    """One calyx petal — mirrors drawCalyx()'s per-petal logic."""
    spread = math.radians(18)
    base_r = size * 0.3
    theta = math.radians(angle_deg)

    def pt(a, radial, y_scale):
        return (cx + math.cos(a) * radial, cy + math.sin(a) * radial * y_scale)

    start = pt(theta - spread, base_r, 0.7)
    end = pt(theta + spread, base_r, 0.7)
    tip = (cx + math.cos(theta) * size, cy + math.sin(theta) * size * 0.7)
    # Swift uses size*0.8 as the control-point x-radius and size*0.6 as the
    # y-radius; the two axes are independent so we can't fold them into pt().
    ctrl1 = (cx + math.cos(theta - spread * 0.5) * size * 0.8,
             cy + math.sin(theta - spread * 0.5) * size * 0.6)
    ctrl2 = (cx + math.cos(theta + spread * 0.5) * size * 0.8,
             cy + math.sin(theta + spread * 0.5) * size * 0.6)

    d = (f"M{f(start[0])},{f(start[1])} "
         f"Q{f(ctrl1[0])},{f(ctrl1[1])} {f(tip[0])},{f(tip[1])} "
         f"Q{f(ctrl2[0])},{f(ctrl2[1])} {f(end[0])},{f(end[1])} Z")
    return f'<path d="{d}" fill="{CALYX_COLOR}"/>'


def berry_elements(expression: str, s: float = 100.0) -> list[str]:
    """
    Return the shape elements for one BlueberryView, drawn inside an `s`×`s`
    frame with the berry body centred at (s/2, s*0.55). No surrounding <svg>
    or <g> — callers wrap these in whatever transform they need.
    """
    cx = s / 2
    cy = s * 0.55
    r = s * 0.40
    face_cy = cy + r * 0.05
    out: list[str] = []

    # --- Body -------------------------------------------------------------
    out.append(rect_to_ellipse(cx - r, cy - r, r * 2, r * 2, BERRY_BODY))
    out.append(rect_to_ellipse(cx - r * 0.8, cy - r * 0.9, r * 1.6, r * 1.1,
                               BERRY_LIGHT, opacity=0.45))
    out.append(rect_to_ellipse(cx - r * 0.65, cy + r * 0.35, r * 1.3, r * 0.55,
                               BERRY_SHADOW, opacity=0.4))

    # --- Calyx (5-point star + centre dot) --------------------------------
    calyx_cx = cx
    calyx_cy = cy - r * 0.82
    calyx_size = r * 0.35
    for i in range(5):
        out.append(petal_path(i * 72 - 90, calyx_cx, calyx_cy, calyx_size))
    dot = calyx_size * 0.25
    out.append(rect_to_ellipse(
        calyx_cx - dot, calyx_cy - dot * 0.7,
        dot * 2, dot * 1.4, CALYX_COLOR,
    ))

    # --- Body highlights --------------------------------------------------
    out.append(rect_to_ellipse(cx - r * 0.52, cy - r * 0.62, r * 0.3, r * 0.38,
                               "white", opacity=0.55))
    out.append(rect_to_ellipse(cx - r * 0.18, cy - r * 0.38, r * 0.16, r * 0.2,
                               "white", opacity=0.4))

    # --- Eyes -------------------------------------------------------------
    eye_spacing = r * 0.32
    eye_size = r * 0.12
    eye_y = face_cy - r * 0.02
    shine_size = eye_size * 0.8

    out.append(rect_to_ellipse(
        cx - eye_spacing - eye_size, eye_y - eye_size * 1.1,
        eye_size * 2, eye_size * 2.2, BLACK_EYE,
    ))
    out.append(rect_to_ellipse(
        cx - eye_spacing + eye_size * 0.05, eye_y - eye_size * 0.85,
        shine_size, shine_size, "white",
    ))
    if expression == "wink":
        wx = cx + eye_spacing
        sx = wx - eye_size * 1.1
        ex = wx + eye_size * 1.1
        ctl_y = eye_y + eye_size * 1.4
        stroke_w = r * 0.04
        out.append(
            f'<path d="M{f(sx)},{f(eye_y)} Q{f(wx)},{f(ctl_y)} {f(ex)},{f(eye_y)}" '
            f'fill="none" stroke="{BLACK_EYE}" stroke-width="{f(stroke_w)}" stroke-linecap="round"/>'
        )
    else:
        out.append(rect_to_ellipse(
            cx + eye_spacing - eye_size, eye_y - eye_size * 1.1,
            eye_size * 2, eye_size * 2.2, BLACK_EYE,
        ))
        out.append(rect_to_ellipse(
            cx + eye_spacing + eye_size * 0.05, eye_y - eye_size * 0.85,
            shine_size, shine_size, "white",
        ))

    # --- Blush ------------------------------------------------------------
    blush_w = r * 0.18
    blush_h = r * 0.12
    blush_y = face_cy + r * 0.1
    out.append(rect_to_ellipse(
        cx - eye_spacing - blush_w * 1.3, blush_y,
        blush_w * 1.8, blush_h, BLUSH_COLOR, opacity=0.5,
    ))
    out.append(rect_to_ellipse(
        cx + eye_spacing - blush_w * 0.5, blush_y,
        blush_w * 1.8, blush_h, BLUSH_COLOR, opacity=0.5,
    ))

    # --- Mouth ------------------------------------------------------------
    mouth_y = face_cy + r * 0.2
    if expression == "happy":
        half, depth = r * 0.14, r * 0.16
        out.append(
            f'<path d="M{f(cx - half)},{f(mouth_y)} '
            f'Q{f(cx)},{f(mouth_y + depth)} {f(cx + half)},{f(mouth_y)} Z" '
            f'fill="{BLACK_MOUTH}"/>'
        )
        tw, th = r * 0.12, r * 0.06
        out.append(rect_to_ellipse(cx - tw / 2, mouth_y + r * 0.04, tw, th,
                                    BLUSH_COLOR, opacity=0.65))
    elif expression == "smile":
        half, depth = r * 0.12, r * 0.13
        out.append(
            f'<path d="M{f(cx - half)},{f(mouth_y)} '
            f'Q{f(cx)},{f(mouth_y + depth)} {f(cx + half)},{f(mouth_y)} Z" '
            f'fill="{BLACK_MOUTH}"/>'
        )
        tw, th = r * 0.08, r * 0.05
        out.append(rect_to_ellipse(cx - tw / 2, mouth_y + r * 0.03, tw, th,
                                    BLUSH_COLOR, opacity=0.6))
    elif expression == "wink":
        half, depth = r * 0.10, r * 0.10
        stroke_w = r * 0.04
        out.append(
            f'<path d="M{f(cx - half)},{f(mouth_y)} '
            f'Q{f(cx)},{f(mouth_y + depth)} {f(cx + half)},{f(mouth_y)}" '
            f'fill="none" stroke="{BLACK_MOUTH}" stroke-width="{f(stroke_w)}" '
            f'stroke-linecap="round"/>'
        )

    return out


# ---- Single-berry SVGs ----------------------------------------------------


def build_single_svg(expression: str) -> str:
    parts = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">']
    parts.extend("  " + el for el in berry_elements(expression, s=100))
    parts.append("</svg>")
    parts.append("")
    return "\n".join(parts)


# ---- Cluster SVG ----------------------------------------------------------
# Mirrors Blueberries/Views/BerryClusterView.swift at its rest state (the
# phase=false frame of the PhaseAnimator). The Swift view has no explicit
# frame; we use a 120×90 viewBox centred at (60, 45) so all three berries and
# the drop-shadow fit without clipping.

CLUSTER_CENTRE_X = 60.0
CLUSTER_CENTRE_Y = 45.0

# (size, expression, offsetX, offsetY, rotation_degrees).
CLUSTER_BERRIES = [
    (48.0, "smile", -32.0, 2.0, -3.0),
    (64.0, "happy", 0.0, -4.0, 0.0),   # happy draws on top of the others
    (44.0, "wink",  32.0,  4.0,  4.0),
]
CLUSTER_HAPPY_INDEX = 1  # which berry gets the drop-shadow


def build_cluster_svg() -> str:
    parts = [
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 90">',
        # Drop shadow matches BerryClusterView's .shadow(color: Theme.berryBlue
        # .opacity(0.3), radius: 8, y: 4). stdDeviation uses radius/2 per
        # Apple's mapping.
        '  <defs>',
        f'    <filter id="happy-shadow" x="-50%" y="-50%" width="200%" height="200%">',
        f'      <feDropShadow dx="0" dy="4" stdDeviation="4" flood-color="{BERRY_BLUE}" flood-opacity="0.3"/>',
        '    </filter>',
        '  </defs>',
    ]
    # Render in Swift's ZStack order: first declared is at the back. The happy
    # berry is in the middle of our list but renders last in Swift (largest /
    # on-top); re-emit in that order here.
    order = [0, 2, 1]  # smile, wink, happy
    for i in order:
        s, expr, ox, oy, rot = CLUSTER_BERRIES[i]
        frame_cx = CLUSTER_CENTRE_X + ox
        frame_cy = CLUSTER_CENTRE_Y + oy
        # translate-rotate-translate:
        # 1) move frame centre to (frame_cx, frame_cy)
        # 2) rotate around that point
        # 3) shift so the berry's local-frame top-left lines up, then scale
        transform = f"translate({f(frame_cx)} {f(frame_cy)}) rotate({f(rot)}) translate({f(-s / 2)} {f(-s / 2)})"
        filter_attr = ' filter="url(#happy-shadow)"' if i == CLUSTER_HAPPY_INDEX else ''
        parts.append(f'  <g transform="{transform}"{filter_attr}>')
        for el in berry_elements(expr, s=s):
            parts.append(f'    {el}')
        parts.append('  </g>')
    parts.append('</svg>')
    parts.append('')
    return "\n".join(parts)


# ---- Entrypoint -----------------------------------------------------------


def main() -> None:
    out_dir = pathlib.Path(__file__).resolve().parent.parent / "web" / "public"
    for expr in ("smile", "happy", "wink"):
        path = out_dir / f"berry-{expr}.svg"
        path.write_text(build_single_svg(expr))
        print(f"wrote {path.relative_to(out_dir.parent.parent)} ({path.stat().st_size} bytes)")
    cluster = out_dir / "berry-cluster.svg"
    cluster.write_text(build_cluster_svg())
    print(f"wrote {cluster.relative_to(out_dir.parent.parent)} ({cluster.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
