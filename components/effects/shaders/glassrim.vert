#version 440

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;
layout(location = 0) out vec2 qt_TexCoord0;

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
    // Derive normalized [0, 1] UVs directly from local item vertex coordinates so
    // ClippingRectangle / offscreen FBO atlases never skew or clip the SDF rim.
    qt_TexCoord0 = qt_Vertex.xy / max(uSize, vec2(1.0));
    gl_Position = qt_Matrix * qt_Vertex;
}
