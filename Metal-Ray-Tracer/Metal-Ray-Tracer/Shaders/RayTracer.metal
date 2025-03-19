#include <metal_stdlib>
using namespace metal;

using namespace metal;

struct Sphere {
    float4 center;  // Keep float4 for future transparency
    float4 color;   // Keep float4 for alpha support
    float radius;
};

struct Ray {
    float4 origin;
    float4 direction;
};

struct Result {
    bool hit;
    float t;
    float4 color;
};

float4 computeBackgroundColor(float4 raydir) {
    float t = 0.5 * (raydir.y + 1.0);
    return mix(float4(1.0, 1.0, 1.0, 1.0), float4(0.5, 0.7, 1.0, 1.0), t);
}

Result raySphereIntersection(Ray ray, Sphere sph) {
    constexpr float INF = 1e10;
    Result res;
    res.hit = false;
    res.t = INF;
    res.color = computeBackgroundColor(ray.direction);

    float4 oc = ray.origin - sph.center;
    float a = dot(ray.direction.xyz, ray.direction.xyz);
    float b = 2.0 * dot(oc.xyz, ray.direction.xyz);
    float c = dot(oc.xyz, oc.xyz) - sph.radius * sph.radius;
    float discriminant = b * b - 4.0 * a * c;
    
    if (discriminant < 0) return res;

    float sqrtd = sqrt(discriminant);
    float t0 = (-b - sqrtd) / (2.0 * a);
    float t1 = (-b + sqrtd) / (2.0 * a);
    
    float t = (t0 > 0) ? t0 : ((t1 > 0) ? t1 : INF);
    if (t < INF) {
        res.hit = true;
        res.t = t;
        res.color = sph.color;
    }
    
    return res;
}

kernel void compute_shader(texture2d<float, access::write> output [[texture(0)]],
                           constant Sphere *spheres [[buffer(0)]],
                           constant int &sphereCount [[buffer(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    constexpr float INF = 1e10;

    uint width = output.get_width();
    uint height = output.get_height();

    float2 uv = (float2(gid) / float2(width, height)) * 2.0 - 1.0;
    uv.x *= float(width) / float(height);

    Ray ray;
    ray.origin = float4(0.0, 0.0, -10.0, 1.0);
    ray.direction = normalize(float4(uv, 1.0, 0.0));

    Result closestHit;
    closestHit.hit = false;
    closestHit.t = INF;
    closestHit.color = computeBackgroundColor(ray.direction);

    for (int i = 0; i < sphereCount; i++) {
        Result res = raySphereIntersection(ray, spheres[i]);
        if (res.hit && res.t < closestHit.t) {
            closestHit = res;
        }
    }

    output.write(closestHit.color, gid);
}
