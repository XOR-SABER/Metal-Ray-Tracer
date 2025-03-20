#include <metal_stdlib>

using namespace metal;

struct Sphere {
    float4 center;
    float4 color;
    float radius;
};

struct Ray {
    float4 direction;
    float4 origin;
};

struct Result {
    float4 hitPoint;
    float4 normal;
    float4 color;
    bool hit;
    float t;
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
        res.hitPoint = ray.origin + t * ray.direction;
        res.t = t;
        res.color = sph.color;
        res.normal = normalize(res.hitPoint - sph.center);
    }
    
    return res;
}

float computeShadowFactor(Result result, float4 lightDirection, constant Sphere *spheres, int sphereCount) {
    constexpr float SHADOW_BIAS = 0.1f;
    Ray shadowRay;
    shadowRay.origin = result.hitPoint + result.normal * SHADOW_BIAS;
    shadowRay.direction = -lightDirection;

    for (int i = 0; i < sphereCount; i++) {
        Result shadowRes = raySphereIntersection(shadowRay, spheres[i]);
        if (shadowRes.hit) return 0.4;
    }

    return 1.0;
}


float4 computeLighting(Result closestHit, float4 lightDirection, float shadowFactor) {
    float ambient = 0.65;
    float diffuse = max(dot(closestHit.normal, -lightDirection), 0.1);
    float lighting = ambient + shadowFactor * diffuse;
    return closestHit.color * lighting;
}



kernel void compute_shader(texture2d<float, access::write> output [[texture(0)]],
                           constant Sphere *spheres [[buffer(0)]],
                           constant int &sphereCount [[buffer(1)]],
                           constant float4x4 &viewMatrix [[buffer(2)]],
                           uint2 gid [[thread_position_in_grid]]) {
    float4 lightDirection = normalize(float4(0.3, -0.7, 0.3, 0.0));
    constexpr float INF = 1e10;
    
    uint width = output.get_width();
    uint height = output.get_height();
    
    float2 uv = (float2(gid) / float2(width, height)) * 2.0 - 1.0;
    uv.x *= float(width) / float(height);
    
    Ray ray;
    ray.origin = viewMatrix * float4(0.0, 0.0, 0.0, 1.0);
    ray.direction = normalize(viewMatrix * float4(uv, 1.0, 1.0));
    
    Result closestHit;
    closestHit.hit = false;
    closestHit.t = INF;
    closestHit.color = float4(0.0, 0.0, 0.0, 1.0);
    
    for (int i = 0; i < sphereCount; i++) {
        Result res = raySphereIntersection(ray, spheres[i]);
        if (res.hit && res.t < closestHit.t) {
            closestHit = res;
        }
    }
    
    if (closestHit.hit) {
            float shadowFactor = computeShadowFactor(closestHit, lightDirection, spheres, sphereCount);
        closestHit.color = computeLighting(closestHit, lightDirection, shadowFactor);

    } else {
        closestHit.color = computeBackgroundColor(ray.direction);
    }
    closestHit.color = clamp(closestHit.color, 0.0f, 1.0f);
    closestHit.color.w = 1.0f;
    output.write(closestHit.color, gid);
}
