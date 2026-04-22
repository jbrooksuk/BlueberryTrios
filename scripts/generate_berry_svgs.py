#!/usr/bin/env python3
"""
Generate faithful SVG ports of Blueberries/Views/BlueberryView.swift.

Mirrors the Canvas drawing logic exactly: same shape primitives, same ratios,
same colours. Output viewBox is 100x100 (matching the Swift frame being
square). Writes to web/public/berry-{smile,happy,wink}.svg.
"""
from __future__ import annotations

import math
import pathlib

# ---- Colour palette (from Blueberries/Views/BlueberryView.swift) ----------

def rgb_hex(r: float, g: float, b: float) -> str:
    return "#{:02X}{:02X}{:02X}".format(
        round(r * 255), round(g * 255), round(b * 255)
    )

BERRY_BODY = rgb_hex(0.45, 0.48, 0.64)      # #737AA3
BERRY_LIGHT = rgb_hex(0.55, 0.58, 0.72)     # #8C94B8
BERRY_SHADOW = rgb_hex(0.32, 0.35, 0.50)    # #525980
CALYX_COLOR = rgb_hex(0.30, 0.34, 0.50)     # #4D5780
BLUSH_COLOR = rgb_hex(0.94, 0.52, 0.48)     # #F0857A
BLACK_EYE = "rgba(0,0,0,0.85)"
BLACK_MOUTH = "rgba(0,0,0,0.75)"

# ---- Canvas geometry (s=100 to match Swift's square frame) ----------------

S = 100.0
CX = S / 2         # 50
CY = S * 0.55      # 55
R = S * 0.40       # 40

# Expression-specific face tweaks mirror Swift's drawFace() centre:
FACE_CY = CY + R * 0.05   # 57

# ---- Helpers --------------------------------------------------------------

def f(v: float) -> str:
    """Format a number for SVG: strip trailing zeros but keep precision."""
    return ("{:.3f}".format(v)).rstrip("0").rstrip(".")


def ellipse(cx: float, cy: float, rx: float, ry: float, fill: str, opacity: float | None = None) -> str:
    attrs = f'cx="{f(cx)}" cy="{f(cy)}" rx="{f(rx)}" ry="{f(ry)}" fill="{fill}"'
    if opacity is not None:
        attrs += f' opacity="{opacity}"'
    return f"  <ellipse {attrs}/>"


def rect_to_ellipse(x: float, y: float, w: float, h: float, fill: str, opacity: float | None = None) -> str:
    """Swift's `Path(ellipseIn: CGRect)` uses a rect; convert to centre+radii."""
    return ellipse(x + w / 2, y + h / 2, w / 2, h / 2, fill, opacity)


def path_petal(angle_deg: float) -> str:
    """One calyx petal — mirrors drawCalyx()'s per-petal logic."""
    calyx_cx = CX
    calyx_cy = CY - R * 0.82  # 22.2
    size = R * 0.35            # 14
    spread = math.radians(18)
    base_r = size * 0.3        # 4.2

    theta = math.radians(angle_deg)

    def pt(a, radial, y_scale):
        return (calyx_cx + math.cos(a) * radial,
                calyx_cy + math.sin(a) * radial * y_scale)

    start = pt(theta - spread, base_r, 0.7)
    end = pt(theta + spread, base_r, 0.7)
    tip = (calyx_cx + math.cos(theta) * size,
           calyx_cy + math.sin(theta) * size * 0.7)
    # Swift uses size*0.8 as the control-point x-radius and size*0.6 as the
    # y-radius; they're not expressible as a single radial with a y-scale.
    ctrl1 = (calyx_cx + math.cos(theta - spread * 0.5) * size * 0.8,
             calyx_cy + math.sin(theta - spread * 0.5) * size * 0.6)
    ctrl2 = (calyx_cx + math.cos(theta + spread * 0.5) * size * 0.8,
             calyx_cy + math.sin(theta + spread * 0.5) * size * 0.6)

    d = (f"M{f(start[0])},{f(start[1])} "
         f"Q{f(ctrl1[0])},{f(ctrl1[1])} {f(tip[0])},{f(tip[1])} "
         f"Q{f(ctrl2[0])},{f(ctrl2[1])} {f(end[0])},{f(end[1])} Z")
    return f'  <path d="{d}" fill="{CALYX_COLOR}"/>'


def calyx() -> list[str]:
    out = []
    # 5 petals, starting at the top (-90°) and rotating 72° per petal.
    for i in range(5):
        out.append(path_petal(i * 72 - 90))
    # Centre dot (Swift draws it last, on top of the petals).
    calyx_cx = CX
    calyx_cy = CY - R * 0.82
    size = R * 0.35
    dot_size = size * 0.25
    out.append(rect_to_ellipse(
        calyx_cx - dot_size,
        calyx_cy - dot_size * 0.7,
        dot_size * 2,
        dot_size * 1.4,
        CALYX_COLOR,
    ))
    return out


def body() -> list[str]:
    out = []
    # Base circle.
    out.append(rect_to_ellipse(CX - R, CY - R, R * 2, R * 2, BERRY_BODY))
    # Top highlight ellipse (roundness).
    out.append(rect_to_ellipse(
        CX - R * 0.8, CY - R * 0.9, R * 1.6, R * 1.1,
        BERRY_LIGHT, opacity=0.45,
    ))
    # Bottom shadow crescent.
    out.append(rect_to_ellipse(
        CX - R * 0.65, CY + R * 0.35, R * 1.3, R * 0.55,
        BERRY_SHADOW, opacity=0.4,
    ))
    return out


def highlights() -> list[str]:
    out = []
    # Bigger primary highlight spot.
    out.append(rect_to_ellipse(
        CX - R * 0.52, CY - R * 0.62, R * 0.3, R * 0.38,
        "white", opacity=0.55,
    ))
    # Secondary highlight.
    out.append(rect_to_ellipse(
        CX - R * 0.18, CY - R * 0.38, R * 0.16, R * 0.2,
        "white", opacity=0.4,
    ))
    return out


def eyes(expression: str) -> list[str]:
    """Mirrors drawFace()'s eye block."""
    out = []
    eye_spacing = R * 0.32      # 12.8
    eye_size = R * 0.12         # 4.8
    eye_y = FACE_CY - R * 0.02  # 56.2
    shine_size = eye_size * 0.8

    # Left eye — always an open ellipse.
    out.append(rect_to_ellipse(
        CX - eye_spacing - eye_size,
        eye_y - eye_size * 1.1,
        eye_size * 2,
        eye_size * 2.2,
        BLACK_EYE,
    ))
    # Left eye shine.
    out.append(rect_to_ellipse(
        CX - eye_spacing + eye_size * 0.05,
        eye_y - eye_size * 0.85,
        shine_size,
        shine_size,
        "white",
    ))

    if expression == "wink":
        # Right eye is a stroked smile curve.
        wx = CX + eye_spacing
        sx = wx - eye_size * 1.1
        ex = wx + eye_size * 1.1
        cx_ = wx
        cy_ = eye_y + eye_size * 1.4
        d = f"M{f(sx)},{f(eye_y)} Q{f(cx_)},{f(cy_)} {f(ex)},{f(eye_y)}"
        stroke_w = R * 0.04
        out.append(
            f'  <path d="{d}" fill="none" stroke="{BLACK_EYE}" '
            f'stroke-width="{f(stroke_w)}" stroke-linecap="round"/>'
        )
    else:
        out.append(rect_to_ellipse(
            CX + eye_spacing - eye_size,
            eye_y - eye_size * 1.1,
            eye_size * 2,
            eye_size * 2.2,
            BLACK_EYE,
        ))
        out.append(rect_to_ellipse(
            CX + eye_spacing + eye_size * 0.05,
            eye_y - eye_size * 0.85,
            shine_size,
            shine_size,
            "white",
        ))
    return out


def blush() -> list[str]:
    eye_spacing = R * 0.32
    blush_w = R * 0.18
    blush_h = R * 0.12
    blush_y = FACE_CY + R * 0.1
    return [
        rect_to_ellipse(
            CX - eye_spacing - blush_w * 1.3, blush_y,
            blush_w * 1.8, blush_h,
            BLUSH_COLOR, opacity=0.5,
        ),
        rect_to_ellipse(
            CX + eye_spacing - blush_w * 0.5, blush_y,
            blush_w * 1.8, blush_h,
            BLUSH_COLOR, opacity=0.5,
        ),
    ]


def mouth(expression: str) -> list[str]:
    mouth_y = FACE_CY + R * 0.2
    out = []
    if expression == "happy":
        half = R * 0.14
        depth = R * 0.16
        d = (f"M{f(CX - half)},{f(mouth_y)} "
             f"Q{f(CX)},{f(mouth_y + depth)} {f(CX + half)},{f(mouth_y)} Z")
        out.append(f'  <path d="{d}" fill="{BLACK_MOUTH}"/>')
        tongue_w = R * 0.12
        tongue_h = R * 0.06
        out.append(rect_to_ellipse(
            CX - tongue_w / 2, mouth_y + R * 0.04,
            tongue_w, tongue_h,
            BLUSH_COLOR, opacity=0.65,
        ))
    elif expression == "smile":
        half = R * 0.12
        depth = R * 0.13
        d = (f"M{f(CX - half)},{f(mouth_y)} "
             f"Q{f(CX)},{f(mouth_y + depth)} {f(CX + half)},{f(mouth_y)} Z")
        out.append(f'  <path d="{d}" fill="{BLACK_MOUTH}"/>')
        tongue_w = R * 0.08
        tongue_h = R * 0.05
        out.append(rect_to_ellipse(
            CX - tongue_w / 2, mouth_y + R * 0.03,
            tongue_w, tongue_h,
            BLUSH_COLOR, opacity=0.6,
        ))
    elif expression == "wink":
        half = R * 0.10
        depth = R * 0.10
        d = (f"M{f(CX - half)},{f(mouth_y)} "
             f"Q{f(CX)},{f(mouth_y + depth)} {f(CX + half)},{f(mouth_y)}")
        stroke_w = R * 0.04
        out.append(
            f'  <path d="{d}" fill="none" stroke="{BLACK_MOUTH}" '
            f'stroke-width="{f(stroke_w)}" stroke-linecap="round"/>'
        )
    return out


def build_svg(expression: str) -> str:
    parts = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">']
    parts.extend(body())
    parts.extend(calyx())
    parts.extend(highlights())
    parts.extend(eyes(expression))
    parts.extend(blush())
    parts.extend(mouth(expression))
    parts.append("</svg>")
    parts.append("")  # trailing newline
    return "\n".join(parts)


def main() -> None:
    out_dir = pathlib.Path(__file__).resolve().parent.parent / "web" / "public"
    for expr in ("smile", "happy", "wink"):
        path = out_dir / f"berry-{expr}.svg"
        path.write_text(build_svg(expr))
        print(f"wrote {path.relative_to(out_dir.parent.parent)} ({path.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
