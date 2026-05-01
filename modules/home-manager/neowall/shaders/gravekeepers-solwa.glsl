mat2 mtx = mat2(0.80, 0.60, -0.60, 0.80);

float hash(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(in vec2 x)
{
    vec2 p = floor(x);
    vec2 f = fract(x);

    f = f * f * (3.0 - 2.0 * f);

    float a = hash(p + vec2(0.0, 0.0));
    float b = hash(p + vec2(1.0, 0.0));
    float c = hash(p + vec2(0.0, 1.0));
    float d = hash(p + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p)
{
    float f = 0.0;

    f += 0.500000 * noise(p); p = mtx * p * 2.02;
    f += 0.250000 * noise(p); p = mtx * p * 2.03;
    f += 0.125000 * noise(p); p = mtx * p * 2.01;
    f += 0.062500 * noise(p); p = mtx * p * 2.04;
    f += 0.031250 * noise(p); p = mtx * p * 2.01;
    f += 0.015625 * noise(p);

    return f / 0.984375;
}

float pattern(in vec2 p, in float t, out vec2 q, out vec2 r, out vec2 g)
{
    q = vec2(
        fbm(p),
        fbm(p + vec2(10.0, 1.3))
    );

    r = vec2(
        fbm(p + 4.0 * q + vec2(t) + vec2(1.7, 9.2)),
        fbm(p + 4.0 * q + vec2(t) + vec2(8.3, 2.8))
    );

    g = vec2(
        fbm(p + 2.0 * r + vec2(t * 20.0) + vec2(2.0, 6.0)),
        fbm(p + 2.0 * r + vec2(t * 10.0) + vec2(5.0, 3.0))
    );

    return fbm(p + 5.5 * g + vec2(-t * 7.0, 0.0));
}

vec3 palette(float noise)
{
    vec3 dark   = vec3(0.12, 0.00, 0.00);
    vec3 mid    = vec3(0.65, 0.05, 0.03);
    vec3 bright = vec3(1.00, 0.30, 0.12);

    noise = clamp(noise, 0.0, 1.0);

    vec3 color = mix(dark, mid, smoothstep(0.0, 0.6, noise));
    color = mix(color, bright, smoothstep(0.55, 1.0, noise));

    return color;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 centered = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    vec2 q, r, g;
    float speed = iTime * 0.005;
    float noise = pattern(centered * 3.2, speed, q, r, g);
    float smooth_noise = smoothstep(0.15, 0.85, noise);

    vec3 color = palette(smooth_noise);

    color += 0.08 * vec3(q.x, r.x * 0.25, g.y * 0.15);
    color += 0.02 * sin(vec3(0.0, 1.2, 2.4) + noise * 6.0 + iTime * 0.01);

    vec2 centered_uv = uv * 2.0 - 1.0;
    float vignette = 1.0 - 0.35 * dot(centered_uv, centered_uv);

    color *= vignette;



    vec2 uv = fragCoord / iResolution.xy;
    vec4 myTex = texture2D(iChannel0, uv);


    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
