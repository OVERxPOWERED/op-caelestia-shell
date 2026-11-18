#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float uRadius;
    float uRimWidth;
    float uLightAngle;
    vec2 uSize;
    float uInnerSheen;
    float uAmbientRim;
    float uMode;
    float uTopSheen;
    float uCornerPower;
    float uSecondaryStrength;
    vec4 uHighlightColor;
    vec4 uShadowColor;
    vec4 uContourColor;
    float uGlowWidth;
    float uLensMix;
};

void main()
{
    vec2 halfDim = max(uSize * 0.5, vec2(1.0));
    float r = clamp(uRadius, 0.0, min(halfDim.x, halfDim.y));

    vec2 p = (qt_TexCoord0 - 0.5) * uSize;
    vec2 b = halfDim - vec2(r);
    vec2 q = abs(p) - b;

    vec2 qPos = max(q, 0.0);
    float dist = length(qPos) + min(max(q.x, q.y), 0.0) - r;

    if (dist > 0.5) {
        fragColor = vec4(0.0);
        return;
    }

    float aa = max(fwidth(dist), 0.75);

    // Smooth outward unit normal
    vec2 sp = vec2(p.x >= 0.0 ? 1.0 : -1.0, p.y >= 0.0 ? 1.0 : -1.0);
    vec2 n;
    if (q.x > 0.0 || q.y > 0.0) {
        float l = length(qPos);
        n = (l > 0.0001) ? (qPos / l) * sp : vec2(0.0, -1.0);
    } else {
        n = (q.x > q.y) ? vec2(sp.x, 0.0) : vec2(0.0, sp.y);
    }

    // Normalized spatial vector across bounding box
    vec2 u = p / halfDim;
    float uLen = length(u);
    vec2 uDir = (uLen > 0.0001) ? (u / uLen) : vec2(-0.707, -0.707);

    vec2 lightDir = vec2(cos(uLightAngle), sin(uLightAngle));
    float spatialAlign = dot(uDir, lightDir);
    float normalAlign = dot(n, lightDir);
    float combinedAlign = mix(spatialAlign, normalAlign, 0.25);

    float p1 = pow(max(combinedAlign, 0.0), uCornerPower);
    float p2 = pow(max(-combinedAlign, 0.0), uCornerPower) * uSecondaryStrength;
    float diagFactor = clamp(p1 + p2, 0.0, 1.0);

    float tb = pow(abs(n.y), uCornerPower * 0.85);
    float topBias = mix(uSecondaryStrength, 1.0, clamp(-n.y * 0.5 + 0.5, 0.0, 1.0));
    float lensFactor = clamp(tb * topBias, 0.0, 1.0);

    float specWeight = uAmbientRim;
    float cornerGlowWeight = 1.0;
    if (uMode < 0.5) {
        // Mode 0: Dual-Corner Diagonal Specular (top-left & bottom-right)
        specWeight = clamp(uAmbientRim + (1.0 - uAmbientRim) * diagFactor, 0.0, 1.0);
    } else if (uMode < 1.5) {
        // Mode 1: Overhead Physical Glass Slab (lit top & upper corners, smooth taper down)
        float topArc = clamp(-n.y * 0.72 + 0.28, 0.0, 1.0);
        float upperTilt = clamp(-u.y * 0.75 + 0.25, 0.0, 1.0);
        float dirBias = mix(0.82, 1.0, clamp(dot(n, lightDir) * 0.5 + 0.5, 0.0, 1.0));
        float topLit = pow(mix(topArc, upperTilt, 0.30), uCornerPower) * dirBias;
        specWeight = clamp(uAmbientRim + (1.0 - uAmbientRim) * topLit, 0.0, 1.0);
    } else if (uMode < 2.5) {
        // Mode 2: Top + Bottom Lens Rim (bright top & bottom arcs, softer ends)
        specWeight = clamp(uAmbientRim + (1.0 - uAmbientRim) * lensFactor, 0.0, 1.0);
    } else if (uMode < 3.5) {
        // Mode 3: Blend between Diagonal Specular (B) and Top/Bottom Lens (F)
        float combined = mix(diagFactor, lensFactor, clamp(uLensMix, 0.0, 1.0));
        specWeight = clamp(uAmbientRim + (1.0 - uAmbientRim) * combined, 0.0, 1.0);
    } else if (uMode < 4.5) {
        // Mode 4: Top-Left Liquid Glass Pane (overhead+top-left rim, tiny bottom-right corner bounce)
        float nLight = clamp(dot(n, lightDir) * 0.65 + 0.35, 0.0, 1.0);
        float sLight = clamp(dot(uDir, lightDir) * 0.55 + 0.45, 0.0, 1.0);
        float primaryArc = pow(mix(sLight, nLight, 0.45), uCornerPower);
        float brBounce = pow(max(-combinedAlign, 0.0), 2.4) * uSecondaryStrength;
        specWeight = clamp(uAmbientRim + (1.0 - uAmbientRim) * clamp(primaryArc + brBounce, 0.0, 1.0), 0.0, 1.0);
    } else {
        // Mode 5: Crystalline Carved Liquid Glass (sharp high-contrast corner crescents + quiet mid-edges)
        float tlCorner = pow(max(combinedAlign, 0.0), uCornerPower);
        float brCorner = pow(max(-combinedAlign, 0.0), uCornerPower * 1.15) * uSecondaryStrength;
        float corners = clamp(tlCorner + brCorner, 0.0, 1.0);
        specWeight = clamp(uAmbientRim + (1.0 - uAmbientRim) * corners, 0.0, 1.0);
        cornerGlowWeight = pow(corners, 1.45);
    }

    // Smoothly anti-aliased specular rim tucked cleanly inside dist <= 0 so clip:true / MSAA edges never jaggedly fight
    float rimCenter = -0.35 - uRimWidth * 0.5;
    float halfStroke = max(uRimWidth * 0.5, 0.45);
    float dFromRim = abs(dist - rimCenter) - halfStroke;
    float strokeScale = clamp(uRimWidth / 0.90, 0.72, 1.0);
    float rimMask = (1.0 - smoothstep(-aa * 0.8, aa * 0.8, dFromRim)) * strokeScale;

    // Subtle hairline dark contour tucked inside the edge
    float contourMask = (1.0 - smoothstep(-0.40, 0.05, dist)) * smoothstep(-1.35, -0.40, dist);
    float contourA = uContourColor.a * contourMask;

    float rimA = uHighlightColor.a * specWeight * rimMask;

    // Inner bevel edge refraction glow (configurable uGlowWidth in px)
    float insideClip = 1.0 - smoothstep(-aa * 0.85, 0.10, dist);
    float glowStart = -(max(uGlowWidth, 0.5) + 0.3);
    float bevelBase = smoothstep(glowStart, -0.3, dist);
    float edgeGlow = (uMode >= 4.5 ? pow(bevelBase, 1.8) * cornerGlowWeight : bevelBase * specWeight) * insideClip * uInnerSheen;

    // Surface glass reflection
    float surfaceSheen = 0.0;
    if (uMode >= 4.5) {
        // Curved glossy glass highlight band sweeping across the upper-left corner
        float diagPos = clamp(1.0 - ((u.x + u.y) * 0.32 + 0.68), 0.0, 1.0);
        float glossBand = smoothstep(0.32, 0.96, diagPos);
        surfaceSheen = pow(glossBand, 2.2) * uTopSheen * insideClip;
    } else {
        float vNorm = (uMode >= 3.5)
            ? clamp(0.5 - (u.x * 0.32 + u.y * 0.68) * 0.5, 0.0, 1.0)
            : clamp(0.5 - (p.y / (halfDim.y * 2.0)), 0.0, 1.0);
        surfaceSheen = pow(vNorm, 2.0) * uTopSheen * insideClip;
    }

    float glowA = clamp(edgeGlow + surfaceSheen, 0.0, 1.0) * uHighlightColor.a;

    // Premultiplied compositing
    vec3 col = uContourColor.rgb * contourA;
    float a = contourA;

    col = col * (1.0 - glowA) + uHighlightColor.rgb * glowA;
    a = a * (1.0 - glowA) + glowA;

    col = col * (1.0 - rimA) + uHighlightColor.rgb * rimA;
    a = a * (1.0 - rimA) + rimA;

    fragColor = vec4(col, a) * qt_Opacity;
}
