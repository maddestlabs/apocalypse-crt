// Title: Apocalypse CRT
// Author: MaddestLabs

SamplerState Sampler;
Texture2D contentTexture : register(t0);
Texture2D bgTexture : register(t1);  // Reflection/overlay texture

cbuffer PixelShaderSettings
{
    float Time;
    float Scale;
    float2 Resolution;
    float4 Background;
};

// Gaussian blur constants
#define SCALED_GAUSSIAN_SIGMA (2.0 * Scale)
static const float M_PI = 3.14159265;

float rnd(float2 c) {
    return frac(sin(dot(c.xy, float2(12.9898,78.233))) * 43758.5453);
}

float3 hsl2rgb(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// RGB shift
float3 rgbDistortion(float2 uv, float offset) {
    float3 color;
    color.r = contentTexture.Sample(Sampler, uv + float2(offset, 0.0)).r;
    color.g = contentTexture.Sample(Sampler, uv).g;
    color.b = contentTexture.Sample(Sampler, uv - float2(offset, 0.0)).b;
    return color;
}

// Gaussian 2D function for bloom effect
float Gaussian2D(float x, float y, float sigma) {
    return 1 / (sigma * sqrt(2 * M_PI)) * exp(-0.5 * (x * x + y * y) / sigma / sigma);
}

// Blur function for Bloom effect
float3 Blur(float2 tex_coord, float sigma, float sampleCount, float borderSize, float hWave) {
    float width, height;
    float2 dimensions = Resolution;
    width = dimensions.x;
    height = dimensions.y;

    float texelWidth = 1.0 / width;
    float texelHeight = 1.0 / height;

    float3 color = float3(0, 0, 0);
    float totalWeight = 0.0;
    
    for (float x = 0; x < sampleCount; x++) {
        float2 samplePos = float2(0, 0);
        samplePos.x = tex_coord.x + (x - sampleCount / 2.0) * texelWidth;

        for (float y = 0; y < sampleCount; y++) {
            samplePos.y = tex_coord.y + (y - sampleCount / 2.0) * texelHeight;
            
            // Transform coordinates to account for border
            float2 adjustedPos = (samplePos - float2(borderSize, borderSize)) / (1.0 - 2.0 * borderSize);
            
            // Apply horizontal sync distortion just like in the main rendering path
            adjustedPos.x += hWave;
            
            // Check if the adjusted position is within the valid range
            if (adjustedPos.x >= 0.0 && adjustedPos.x <= 1.0 && 
                adjustedPos.y >= 0.0 && adjustedPos.y <= 1.0) {
                
                float weight = Gaussian2D(x - sampleCount / 2.0, y - sampleCount / 2.0, sigma);
                totalWeight += weight;
                
                color += rgbDistortion(adjustedPos, 0.0005) * weight;
            }
        }
    }
    
    // Prevent division by zero if all samples were outside the valid range
    if (totalWeight > 0.0) {
        return color / totalWeight;
    } else {
        return float3(0, 0, 0);
    }
}

// Calculate light effect
float calculateLightFactor(float2 uv, float iTime) {
    // Light configuration
    float intesnity = 1.5;      // Overall light intensity
    float ambient_light = 0.25; // Minimum brightness in darker areas

    // Calculate moving light position
    float lightX = 0.5 + sin(iTime * 1.75) * 0.35;
    float2 lightPos = float2(lightX, 0.2);
    
    // Calculate vector to light
    float2 lightVector = uv - lightPos;
    float2 scaledVector = float2(lightVector.x, lightVector.y);
    float scaledDistance = length(scaledVector);
    
    // Apply smooth falloff
    float lightFalloff = pow(saturate(1.0 - (scaledDistance / 1.5)), 0.85);
    
    // Create smooth transition from light to ambient
    return lerp(ambient_light, 1.0 + intesnity, lightFalloff);
}

float3 tex(float2 uv, float bSize, float3 bColor, bool isFrame, float fSize) {
    float iTime = Time;
    float2 iResolution = Resolution;

    // ML Parameters
    float grilleLvl = 0.95; // Range: 0.0, 3.0
    float grilleDensity = 800.0; // Range: 0.0, 1000.0
    float scanlineLvl = 0.8; // Range: 0.05, 3.0
    float scanlines = 1.0; // Range:  1.0, 6.0
    float rgbOffset = 0.001;
    float noiseLevel = 0.1;
    float flicker = 0.15;
    float glassTint = 0.2;
    float glassHue = 0.0;
    float glassSat = 0.3;
    float screenTint = 0.2;
    float screenHue = 0.0;
    float screenSat = 1.0;
    float bloomLevel = 0.0; // Range: 0.0, 2.0
    float vignetteStart = 0.25; //Range: 0.0, 2.0
    float vignetteLvl = 20.0; //Range: 1.0, 20.0
    float hSync = 0.01; // Range: 0.0, 3.0
    float lightSpeed = 1.0; // Range: 0.0, 2.0
    float overlay = 1.0;
    // ML Parameters
    
    // Configure parameters for horizontal sync wave
    float time = iTime * 5.0;
    float size = lerp(0.0, hSync, 0.1);

    // Horizontal sync wave effect
    float cyclePeriod = 2.0; // Base cycle of 2 seconds
    float randomOffset = frac(sin(floor(iTime / cyclePeriod) * 12345.67) * 43758.5453); // Pseudo-random per cycle
    float actualCyclePeriod = cyclePeriod + randomOffset; // Varies between 2-3 seconds
    float cyclePosition = frac(iTime / actualCyclePeriod);

    // Only show wave effect for the first 15% of each cycle
    float waveDuration = 0.15;
    float waveStrength = 0.0;

    if (cyclePosition < waveDuration) {
        float normalizedTime = cyclePosition / waveDuration;
        waveStrength = sin(normalizedTime * 3.14159) * size;
    }

    // Apply wave effect only during the active period
    float hWave = sin(uv.y * 10.0 + time) * waveStrength;

    //float hWave = sin(uv.y * 10.0 + time) * size;
    float3 color;

    // Use borderColor if within border width
    bool isBorder = 
        (uv.x < bSize || uv.x > 1.0 - bSize || 
         uv.y < bSize || uv.y > 1.0 - bSize);

    // Calculate normalized coordinates within the screen area
    float2 screenUV = (uv - float2(bSize, bSize)) / (1.0 - 2.0 * bSize);
    if (isBorder && bSize > 0.0) {
        // DISTORT - Horizontal Sync
        if (screenUV.x < 0.0 || screenUV.x > 1.0 || screenUV.y < 0.0 || screenUV.y > 1.0) {
            // If out of bounds, use border color
            color = bColor;
        } else {
            // If in bounds but in border area, apply RGB shift to screen content
            // for reflection effect
            color = rgbDistortion(screenUV, rgbOffset);
        }
    } else {
        // No border specified
        screenUV.x += hWave;
        if (screenUV.x < 0.0 || screenUV.x > 1.0 || screenUV.y < 0.0 || screenUV.y > 1.0) {
            // If out of bounds after distortion, use border color
            color = bColor;
        } else {
            // Use RGB shift with distortion
            color = rgbDistortion(screenUV, rgbOffset);
        }
    }
    
    // FX Aperture Grille
    if (grilleLvl > 0.0) {
        float grillePattern = sin(uv.x * grilleDensity * 3.14159);
        grillePattern = grilleLvl + (1.0 - grilleLvl) * grillePattern;
        color *= (0.5 + 0.5 * grillePattern);
    }
    
    // FX Scanlines
    if (scanlineLvl > 0.05) {
        float scanlinePattern = sin(uv.y * iResolution.y * 3.14159 / scanlines);
        color *= (scanlineLvl + (1.0 - scanlineLvl) * scanlinePattern);
    }
    
    // FX Noise
    if (noiseLevel > 0.0) {
        float timeFactor = iTime * 1.0;
        float noise = rnd(uv + timeFactor);
        color += noise * noiseLevel * 0.5;
    }

    // FX Screen tint
    if (screenTint > 0.0) {
        float l = dot(color, float3(0.2126, 0.7152, 0.0722));
        float3 screen = hsl2rgb(float3(screenHue, screenSat, l));
        color = float3(lerp(color, float3(screen), screenTint));
    }
    
    // FX Glass tint
    if (glassTint > 0.0) {
        float t = 0.5 + 0.5 * uv.y;
        float3 tintColor = hsl2rgb(float3(glassHue, glassSat, t));
        color += tintColor * glassTint;
    }

    // FX Flicker
    if (flicker > 0.0) {
        float f = 1.0 + 0.25 * sin(iTime * 60.0) * flicker;
        color *= f;
    }

    // FX Bloom
    if (bloomLevel > 0.0) {
        float sampleCount = 2;
        float3 bloom = Blur(uv, SCALED_GAUSSIAN_SIGMA, sampleCount, bSize, hWave);
        color += bloom * bloomLevel;
    }

    // FX background texture/overlay
    if (overlay > 0.0) {
        float4 bgTex = bgTexture.Sample(Sampler, uv);
        // Mix based on opacity for PNG alpha levels
        if (bgTex.a < 1.0 ) {
            color = float3(lerp(color, bgTex, bgTex.a * overlay));
        } else {
            color = float3(lerp(color, bgTex, (0.5 * overlay)));
            color += bgTex.rgb * 0.5;
        }
    }
    
    // FX Vignette
    if (isFrame) uv = (uv - 0.5) * (1.0 / (1.0 - fSize)) + 0.5;
    uv *= (1.0 - uv.yx);
    color *= pow(uv.x * uv.y * vignetteLvl, vignetteStart);
    
    // FX Light Source
    if (lightSpeed > 0.0) {
        float lightFactor = calculateLightFactor(uv, iTime * lightSpeed);
        float3 lightColor = float3(1.0, 0.98, 0.95); // Slightly warm light
        color *= lightColor * lightFactor;
    }

    return color;
}

float4 main(float4 fragCoord : SV_POSITION, float2 hlsluv : TEXCOORD) : SV_TARGET
{
    float iTime = Time;
    float2 iResolution = Resolution;
    float4 fragColor;

    float2 uv = fragCoord / iResolution.xy;

    // FX Rumble
    // Use a hash for random intervals
    float hash = frac(sin(floor(iTime / 7.0) * 43758.5453));
    float interval = 7.0 + hash * 6.0;
    // ML Parameters
    float rumbleDuration = 1.0;
    // ML Parameters
    float rumbleDim = 0.0;
    if (rumbleDuration > 0.0) {
        float rumbleStrength = 0.0;
        
        // Calculate phase within current interval
        float currentIntervalStart = floor(iTime / interval) * interval;
        float phase = iTime - currentIntervalStart;
        
        if (phase < rumbleDuration) {
            // Rumble strength peaks in middle and fades at start/end
            rumbleStrength = sin(phase * 3.14159 / rumbleDuration);
            rumbleDim = 0.05 * rumbleStrength;
        }
        
        // Create random offset for rumble effect
        float maxOffset = 3.0; // Maximum pixel offset
        float2 rumbleOffset = float2(
            sin(iTime * 20.0 + 0.3) * cos(iTime * 13.0),
            cos(iTime * 17.0 - 0.7) * sin(iTime * 11.0)
        ) * rumbleStrength * maxOffset / Resolution;
        uv += rumbleOffset;
    }

    float2 center = float2(0.5, 0.5);
    float alpha = 1.0;
    float distanceFromCenter = length(uv - center);
    // Calculate pixel size in UV coordinates
    float2 pxSize = 1.0 / iResolution.xy;
    
    // Calculate curvature for main screen
    float curveStrength = 0.95; // Range: 0.0, 5.0
    float curveDistance = 5.0; // Range: 0.0, 5.0
    
    uv += (uv - center) * pow(distanceFromCenter, curveDistance) * curveStrength;
    
    // ML Parameters
    float frameSize = 20.0;
    float frameHue = 0.025;
    float frameSat = 0.1;
    float frameLight = 0.02;
    float frameReflect = 0.5;
    float frameGrain = 0.15;
    float borderSize = 20.0;
    float borderHue = 0.0;
    float borderSat = 0.0;
    float borderLight = 0.0;
    // ML Parameters
    
    float3 bColor = hsl2rgb(float3(borderHue, borderSat, borderLight));
    
    float frame = frameSize * pxSize.x;
    float border = borderSize * pxSize.x;
    // Calculate scaled UV coordinates with offset
    float2 suv = (uv - float2(frame, frame)) / (1.0 - 2.0 * (frame));

    float3 color;

    // Check if pixel is in frame region
    bool isFrame = (uv.x < frame || uv.x > (1.0 - frame) ||
                    uv.y < frame || uv.y > (1.0 - frame));
   
    // Determine color based on region
    if (isFrame) {
        if (frameLight == 0.0) alpha = 0.0;
        // Calculate frame intensity based on distance to center
        float frame = 100.0;
        float nX = frame / iResolution.x;
        float nY = frame / iResolution.y;
        float intensity = 0.0;
        // Calculate minimum distance to frame
        float distX = min(uv.x, 1.0-uv.x);
        float distY = min(uv.y, 1.0-uv.y);
        float minDist = min(distX, distY);
        // Scale intensity based on distance, closer to center gets darker
        intensity = lerp(frameLight, 0.0, minDist / max(nX, nY) * 4.0);
        
        // Get base reflection coordinates
        float2 f = border / iResolution.xy;
        float2 reflectedUV = suv;
        
        // Apply standard mirror reflection
        if (reflectedUV.x < f.x) {
            reflectedUV.x = f.x - (reflectedUV.x - f.x);
        } else if (reflectedUV.x > 1.0 - f.x) {
            reflectedUV.x = 1.0 - f.x - (reflectedUV.x - (1.0 - f.x));
        }
        if (reflectedUV.y < f.y) {
            reflectedUV.y = f.y - (reflectedUV.y - f.y);
        } else if (reflectedUV.y > 1.0 - f.y) {
            reflectedUV.y = 1.0 - f.y - (reflectedUV.y - (1.0 - f.y));
        }
        
        // Apply controlled curvature to mirrored coordinates
        float2 reflCenter = float2(0.5, 0.5);
        float reflDistFromCenter = length(reflectedUV - reflCenter);

        // Use curved coordinates for sampling texture
        float3 blurred = float3(0.0, 0.0, 0.0);
        float blur = 2.0 / iResolution.x;
        float frameBlur = 1.0; // Range: 1.0, 6.0
        int r = int(frameBlur);
        for (int x = -r; x <= r; x++) {
            for (int y = -r; y <= r; y++) {
                float2 blurPos = reflectedUV + float2(float(x) * blur, float(y) * blur);
                blurred += tex(blurPos, border, bColor, isFrame, frameSize);
            }
        }
        blurred /= 32.0;
        
        color = hsl2rgb(float3(frameHue, frameSat, intensity));
        color *= 1.0 - frameGrain * rnd(suv);
        color += blurred * frameReflect * 0.5;
        
        // FX Light Source
        float lightFactor = calculateLightFactor(uv, iTime);
        float3 lightColor = float3(1.0, 0.98, 0.95); // Slightly warm light
        color *= lightColor * lightFactor;
    } else {
        color = tex(suv, border, bColor, isFrame, frameSize);
    }

    // Dim lights during rumble
    color -= rumbleDim;

    fragColor = float4(color, alpha);
    return fragColor;
}
