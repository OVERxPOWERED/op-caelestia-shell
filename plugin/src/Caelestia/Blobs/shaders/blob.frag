#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float paddedX;
    float paddedY;
    float paddedW;
    float paddedH;
    float smoothFactor;
    int rectCount;
    int myIndex;
    vec4 color;
    int hasInverted;
    float invertedRadius;
    vec4 invertedOuter;
    vec4 invertedInner;
    vec4 rectData[80];
};

float sdRoundedBox(vec2 p, vec2 center, vec2 halfSize, float radius) {
    vec2 d = abs(p - center) - halfSize + vec2(radius);
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - radius;
}

float sdRoundedBox4(vec2 p, vec2 center, vec2 halfSize, vec4 r) {
    // r = (topRight, bottomRight, bottomLeft, topLeft)
    p -= center;
    r.xy = (p.x > 0.0) ? r.xy : r.wz;
    r.x  = (p.y > 0.0) ? r.y : r.x;
    vec2 q = abs(p) - halfSize + r.x;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

float sdBox(vec2 p, vec2 center, vec2 halfSize) {
    vec2 d = abs(p - center) - halfSize;
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
}

float smin(float a, float b, float k) {
    // Cubic smooth min (C2 continuous — no curvature kinks at blend boundary)
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * h * k * (1.0/6.0);
}

float sminNoBulge(float a, float b, float k) {
    // Cubic smooth min with reduced outward expansion when shapes overlap
    float h = max(k - abs(a - b), 0.0) / k;
    float blend = h * h * h * k * (1.0/6.0);
    blend *= smoothstep(-k, 0.0, min(a, b));
    return min(a, b) - blend;
}

float smax(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return max(a, b) + h * h * h * k * (1.0/6.0);
}

float smaxSharpA(float a, float b, float k) {
    // smax variant that keeps a's boundary sharp (no inward rounding at a = 0).
    // Used for the frame outer edge so it always fills to the edges.
    float h = max(k - abs(a - b), 0.0) / k;
    float blend = h * h * h * k * (1.0/6.0);
    blend *= smoothstep(0.0, k * 0.5, -a);
    return max(a, b) + blend;
}

void main() {
    vec2 pixel = vec2(paddedX, paddedY) + qt_TexCoord0 * vec2(paddedW, paddedH);

    float mergedSdf = 1e10;
    int owner = -2;
    float minDist = 1e10;

    for (int i = 0; i < rectCount; i++) {
        vec4 rect = rectData[i * 5];         // cx, cy, hw, hh
        vec4 props = rectData[i * 5 + 1];    // radius, offsetX, offsetY, minEig
        vec4 invDm = rectData[i * 5 + 2];    // inverse deform matrix
        vec4 sh = rectData[i * 5 + 3];       // screenHalfX, screenHalfY, 0, 0
        vec4 fills = rectData[i * 5 + 4];    // f_tr, f_br, f_bl, f_tl

        // Offset center for asymmetric deformation
        vec2 center = rect.xy + props.yz;

        // AABB early-out: skip rects far from this pixel
        vec2 extent = sh.xy + vec2(smoothFactor * 1.5);
        if (abs(pixel.x - center.x) > extent.x || abs(pixel.y - center.y) > extent.y)
            continue;

        // Apply pre-computed inverse deformation to the evaluation point
        mat2 invDeform = mat2(invDm.xy, invDm.zw);
        vec2 transformedPixel = center + invDeform * (pixel - center);

        // Use pre-computed corner fill factors
        float br = props.x;
        float minR = 2.0;
        vec4 radii = max(br * fills, vec4(minR));
        float d = sdRoundedBox4(transformedPixel, center, rect.zw, radii);

        // Use pre-computed minimum eigenvalue for SDF correction
        d *= max(props.w, 0.01);

        // Scale SDF on the axis facing a nearby border to narrow the smin blend zone
        // in that direction only, without reducing k (which would cause sharp edges).
        if (hasInverted != 0) {
            vec2 screenHalf = sh.xy;

            float distY0 = (center.y + screenHalf.y) - (invertedInner.y - invertedInner.w);
            float distY1 = (invertedInner.y + invertedInner.w) - (center.y - screenHalf.y);
            float distX0 = (center.x + screenHalf.x) - (invertedInner.x - invertedInner.z);
            float distX1 = (invertedInner.x + invertedInner.z) - (center.x - screenHalf.x);

            // 0 = far from border, 1 = at border (max compression)
            float yProx = 1.0 - min(
                smoothstep(0.0, smoothFactor, distY0),
                smoothstep(0.0, smoothFactor, distY1)
            );
            float xProx = 1.0 - min(
                smoothstep(0.0, smoothFactor, distX0),
                smoothstep(0.0, smoothFactor, distX1)
            );

            // Smooth axis weights: gradient-based at corners, face-based inside.
            vec2 q = abs(pixel - center) - screenHalf;
            vec2 qp = max(q, vec2(0.0));
            float cornerLen = length(qp);

            // Gradient direction in corner region (smooth 90-degree rotation)
            float gradX = qp.x / max(cornerLen, 0.001);
            float gradY = qp.y / max(cornerLen, 0.001);

            // Smooth face weights for inside/edge (no hard branch)
            float faceY = smoothstep(-4.0, 4.0, q.y - q.x);
            float faceX = 1.0 - faceY;

            // Blend: gradient in corner region, face-based inside
            float t = smoothstep(0.0, 2.0, cornerLen);
            float xWeight = mix(faceX, gradX, t);
            float yWeight = mix(faceY, gradY, t);

            float boost = 3.0;
            float scale = 1.0 + (xProx * xWeight + yProx * yWeight) * boost;
            d *= scale;
        }

        // Rect-to-rect edge sink: indent this rect's edge where another
        // rect is slightly past it, fading once past threshold.
        if (rectCount > 1) {
            vec2 iSh = sh.xy;
            float sinkT = smoothFactor * 0.75;
            float sinkOff = smoothFactor * (1.0 / 6.0);
            float rectSinkVal = 0.0;

            for (int j = 0; j < rectCount; j++) {
                if (j == i) continue;

                vec4 jR = rectData[j * 5];
                vec4 jP = rectData[j * 5 + 1];
                vec2 jSh = rectData[j * 5 + 3].xy;
                vec2 jC = jR.xy + jP.yz;

                // Skip non-adjacent rects
                float sinkRange = smoothFactor * 1.5;
                if (abs(center.x - jC.x) > iSh.x + jSh.x + sinkRange ||
                    abs(center.y - jC.y) > iSh.y + jSh.y + sinkRange)
                    continue;

                // Penetration of j past i's edges (positive = past)
                float pT = (jC.y + jSh.y) - (center.y - iSh.y) - sinkOff;
                float pB = (center.y + iSh.y) - (jC.y - jSh.y) - sinkOff;
                float pL = (jC.x + jSh.x) - (center.x - iSh.x) - sinkOff;
                float pR = (center.x + iSh.x) - (jC.x - jSh.x) - sinkOff;

                // Smooth bump: rises then falls, zero outside [0, sinkT]
                float aT = smoothstep(0.0, sinkT * 0.4, pT) * (1.0 - smoothstep(sinkT * 0.5, sinkT, pT));
                float aB = smoothstep(0.0, sinkT * 0.4, pB) * (1.0 - smoothstep(sinkT * 0.5, sinkT, pB));
                float aL = smoothstep(0.0, sinkT * 0.4, pL) * (1.0 - smoothstep(sinkT * 0.5, sinkT, pL));
                float aR = smoothstep(0.0, sinkT * 0.4, pR) * (1.0 - smoothstep(sinkT * 0.5, sinkT, pR));

                // Lateral falloff from rect j's extent
                float hLat = max(abs(pixel.x - jC.x) - jSh.x, 0.0);
                float vLat = max(abs(pixel.y - jC.y) - jSh.y, 0.0);
                float latF = smoothFactor * 2.0;

                // Perpendicular zone (near rect i's edge only)
                float zT = 1.0 - smoothstep(center.y - iSh.y, center.y - iSh.y + smoothFactor, pixel.y);
                float zB = smoothstep(center.y + iSh.y - smoothFactor, center.y + iSh.y, pixel.y);
                float zL = 1.0 - smoothstep(center.x - iSh.x, center.x - iSh.x + smoothFactor, pixel.x);
                float zR = smoothstep(center.x + iSh.x - smoothFactor, center.x + iSh.x, pixel.x);

                float s = max(
                    max(aT * smoothstep(latF, 0.0, hLat) * zT,
                        aB * smoothstep(latF, 0.0, hLat) * zB),
                    max(aL * smoothstep(latF, 0.0, vLat) * zL,
                        aR * smoothstep(latF, 0.0, vLat) * zR)
                );
                rectSinkVal = max(rectSinkVal, s);
            }
            d += rectSinkVal * smoothFactor * 0.25;
        }

        mergedSdf = sminNoBulge(mergedSdf, d, smoothFactor);
        if (d < smoothFactor && d < minDist) {
            minDist = d;
            owner = i;
        }
    }

    if (hasInverted != 0) {
        float dOuter = sdBox(pixel, invertedOuter.xy, invertedOuter.zw) - 1.0;
        float dInner = sdRoundedBox(pixel, invertedInner.xy, invertedInner.zw, invertedRadius);

        // Border sinks: track the opposite rect edge, clamped to border thickness
        float innerTop = invertedInner.y - invertedInner.w;
        float innerBot = invertedInner.y + invertedInner.w;
        float innerLeft = invertedInner.x - invertedInner.z;
        float innerRight = invertedInner.x + invertedInner.z;
        float outerTop = invertedOuter.y - invertedOuter.w;
        float outerBot = invertedOuter.y + invertedOuter.w;
        float outerLeft = invertedOuter.x - invertedOuter.z;
        float outerRight = invertedOuter.x + invertedOuter.z;

        float sinkValue = 0.0;
        for (int i = 0; i < rectCount; i++) {
            vec4 rect = rectData[i * 5];
            vec4 sinkProps = rectData[i * 5 + 1];
            vec2 sinkSh = rectData[i * 5 + 3].xy;

            // Screen-space center (with offset) and pre-computed AABB half-extents
            vec2 ctr = rect.xy + sinkProps.yz;

            // Delay sink to absorb smin blend depth (cubic smin max = k/6)
            float preOff = smoothFactor * (1.0/6.0);

            // Top border: track rect's BOTTOM edge, only within border thickness
            float topPen = clamp(innerTop - (ctr.y + sinkSh.y) - preOff, 0.0, innerTop - outerTop);

            // Bottom border: track rect's TOP edge
            float botPen = clamp((ctr.y - sinkSh.y) - innerBot - preOff, 0.0, outerBot - innerBot);

            // Left border: track rect's RIGHT edge
            float leftPen = clamp(innerLeft - (ctr.x + sinkSh.x) - preOff, 0.0, innerLeft - outerLeft);

            // Right border: track rect's LEFT edge
            float rightPen = clamp((ctr.x - sinkSh.x) - innerRight - preOff, 0.0, outerRight - innerRight);

            // Lateral distance from pixel to rect's extent along each edge
            float hLat = max(abs(pixel.x - ctr.x) - sinkSh.x, 0.0);
            float vLat = max(abs(pixel.y - ctr.y) - sinkSh.y, 0.0);

            // Perpendicular proximity: full strength in border, fade inside inner area
            float topZone = 1.0 - smoothstep(innerTop, innerTop + smoothFactor, pixel.y);
            float botZone = smoothstep(innerBot - smoothFactor, innerBot, pixel.y);
            float leftZone = 1.0 - smoothstep(innerLeft, innerLeft + smoothFactor, pixel.x);
            float rightZone = smoothstep(innerRight - smoothFactor, innerRight, pixel.x);

            float s = smoothFactor * 2.0;
            float sink = max(
                max(topPen * smoothstep(s, 0.0, hLat) * topZone,
                    botPen * smoothstep(s, 0.0, hLat) * botZone),
                max(leftPen * smoothstep(s, 0.0, vLat) * leftZone,
                    rightPen * smoothstep(s, 0.0, vLat) * rightZone)
            );
            sinkValue = max(sinkValue, sink);
        }

        dInner -= sinkValue;

        float dFrame = smaxSharpA(dOuter, -dInner, smoothFactor);

        mergedSdf = smin(mergedSdf, dFrame, smoothFactor);
        if (dFrame < minDist) {
            owner = -1;
        }
    }

    // Each renderer only outputs pixels it owns, but allow rendering
    // blend zones to prevent gaps (mergedSdf < smoothFactor means in blend)
    // myIndex == -1: inverted rect renders border-owned pixels
    // myIndex >= 0: individual rect renders its owned pixels
    if (owner != myIndex && mergedSdf > smoothFactor)
        discard;

    float fw = fwidth(mergedSdf);
    float alpha = 1.0 - smoothstep(-fw, fw, mergedSdf);
    fragColor = vec4(color.rgb * alpha, alpha) * qt_Opacity;
}
