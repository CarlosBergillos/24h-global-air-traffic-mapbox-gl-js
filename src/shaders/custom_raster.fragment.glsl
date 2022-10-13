uniform float u_fade_t;
uniform float u_opacity;
uniform sampler2D u_image0;
uniform sampler2D u_image1;
varying vec2 v_pos0;
varying vec2 v_pos1;

uniform float u_brightness_low;
uniform float u_brightness_high;

uniform float u_saturation_factor;
uniform float u_contrast_factor;
uniform vec3 u_spin_weights;

uniform float u_zoom;
uniform float u_c0_opacity;
uniform float u_c1_opacity;



float zoomMult(float z) {
    float MIN_Z = 2.0;
    float MAX_Z = 11.0;
    float MIN_MULT = 0.5;
    float MAX_MULT = 8.0;

    float f = clamp((z - MIN_Z) / (MAX_Z - MIN_Z), 0.0, 1.0);  // 0 to 1, linear
    f *= f;  // 0 to 1, quadratic

    return mix(MIN_MULT, MAX_MULT, f);
}

float zoomAdd(float z) {
    float MIN_Z = 2.0;
    float MAX_Z = 11.0;
    float MIN_ADD = 4.0;
    float MAX_ADD = 8.0;

    float f = clamp((z - MIN_Z) / (MAX_Z - MIN_Z), 0.0, 1.0);  // 0 to 1, linear
    f *= f;  // 0 to 1, quadratic

    return mix(MIN_ADD, MAX_ADD, f);
}


vec4 colorMap(float k, vec4 baseColor, float a) {
    // vec4 c2 = vec4(0.16, 0.086, 0.301, 0.1);  // #16174d
    vec4 outColor = vec4(0.0);
    outColor.rgb = baseColor.rgb * baseColor.a * k * a;
    outColor.a = a;
    outColor = clamp(outColor, 0.0, 1.0);
    return outColor;
}


vec4 renderPixel(vec4 rawColor) {
    float zm = zoomMult(u_zoom);
    float za = zoomAdd(u_zoom);

    // vec3 channelsMask = vec3(u_channels & 0x01, u_channels & 0x02, u_channels & 0x04);
    // vec3 p = texture(u_image, v_texCoord).rgb * channelsMask.rgb;
    float v0 = rawColor.r;
    float c0 = v0 * 255.0;
    // float k0 = max(c0, 10.0);
    float k0 = c0;
    float a0 = clamp(c0, 0.0, 1.0) * u_c0_opacity;
    k0 = (k0 * zm) + (za * min(1.0, k0));

    float v1 = rawColor.a;
    float c1 = v1 * 255.0;
    // float k1 = max(c1, 10.0);
    float k1 = c1;
    float a1 = clamp(c1, 0.0, 1.0) * u_c1_opacity;
    k1 = (k1 * zm) + (za * min(1.0, k1));

    return colorMap(k0, vec4(0.301, 0.09, 0.086, 0.1), a0)
        + colorMap(k1, vec4(0.16, 0.086, 0.301, 0.2), a1);
}


void main() {

    // read and cross-fade colors from the main and parent tiles
    vec4 color0 = texture2D(u_image0, v_pos0);
    vec4 color1 = texture2D(u_image1, v_pos1);
    
    color0 = renderPixel(color0);  // TODO: different textures are part of a different zoom level?
    color1 = renderPixel(color1);  // TODO: different textures are part of a different zoom level?

    // "un-premultiply" alpha?
    // if (color0.a > 0.0) {
    //     color0.rgb = color0.rgb / color0.a;
    // }
    // if (color1.a > 0.0) {
    //     color1.rgb = color1.rgb / color1.a;
    // }

    vec4 color = mix(color0, color1, u_fade_t);
    // color.a *= u_opacity;
    // vec3 rgb = color.rgb;

    // if (color.a < 0.01) {
    //     rgb = vec3(1.0);
    // }

    // vec3 out_color= rgb;

#ifdef FOG
    // disable fog
    // out_color = fog_dither(fog_apply(out_color, v_fog_pos));
#endif

    gl_FragColor = vec4(color.rgb, color.a);

#ifdef OVERDRAW_INSPECTOR
    gl_FragColor = vec4(1.0);
#endif
    // if (v_pos0.x > 0.5) {
    //     color = vec4(1.0); 
    // } else {
    //     color = vec4(0.0); 
    // }
    // // color = vec4(1.0, 1.0, 1.0, v_pos0.x); 
    // gl_FragColor = vec4(color.rgb * color.a, color.a);
}
