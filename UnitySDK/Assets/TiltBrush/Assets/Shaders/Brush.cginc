// Copyright 2017 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// -*- c -*-

// Canvas transform.
uniform float4x4 xf_CS;
// Inverse canvas transform.
uniform float4x4 xf_I_CS;

// Unity only guarantees signed 2.8 for fixed4.
// In practice, 2*exp(_EmissionGain * 10) = 180, so we need to use float4
float4 bloomColor(float4 color, float gain) {
  // Guarantee that there's at least a little bit of all 3 channels.
  // This makes fully-saturated strokes (which only have 2 non-zero
  // color channels) eventually clip to white rather than to a secondary.
  float cmin = length(color.rgb) * .05;
  color.rgb = max(color.rgb, float3(cmin, cmin, cmin));
  // If we try to remove this pow() from .a, it brightens up
  // pressure-sensitive strokes; looks better as-is.
  color = pow(color, 2.2);
  color.rgb *= 2 * exp(gain * 10);
  return color;
}

// Used by various shaders to animate selection outlines
// Needs to be visible even when the color is black
float4 GetAnimatedSelectionColor( float4 color) {
  return color + sin(_Time.w*2)*.1 + .2f;
}

//
// Common for Music Reactive Brushes
//

sampler2D _WaveFormTex;
sampler2D _FFTTex;
uniform float4 _BeatOutputAccum;
uniform float4 _BeatOutput;
uniform float4 _AudioVolume;
uniform float4 _PeakBandLevels;

// returns a random value seeded by color between 0 and 2 pi
float randomizeByColor(float4 color) {
  const float PI = 3.14159265359;
  float val =  (3*color.r + 2*color.g + color.b) * 1000;
  val =  2 * PI * fmod(val, 1);
  return val;
}

float3 randomNormal(float3 color) {
  float noiseX = frac(sin(color.x))*46336.23745f; 
  float noiseY = frac(sin(color.y))*34748.34744f; 
  float noiseZ = frac(sin(color.z))*59998.47362f; 
  return normalize(float3(noiseX, noiseY, noiseZ)); 
}

float4 musicReactiveColor(float4 color, float beat) {
  float randomOffset = randomizeByColor(color);
  color.xyz = color.xyz * .5 + color.xyz * saturate(sin(beat * 3.14159 + randomOffset) );
  return color;
}

float4 musicReactiveAnimation(float4 vertex, float4 color, float beat, float t) {
  float intensity = .15;
  float4 worldPos = mul(unity_ObjectToWorld, vertex);
  float randomOffset = 2 * 3.14159 * randomizeByColor(color) + _Time.w + worldPos.z; 
  // the first sin function makes the start and end points of the UV's (0:1) have zero modulation.  
  // The second sin term causes vibration along the stroke like a plucked guitar string - frequency defined by color
  worldPos.xyz += randomNormal(color.rgb) * beat * sin(t * 3.14159) * sin(randomOffset) * intensity;
  return mul(unity_WorldToObject, worldPos);
}

// Unity 5.1 and below use camera-space particle vertices
// Unity 5.2 and above use world-space particle vertices
#if UNITY_VERSION < 520
uniform float4x4 _ParticleVertexToWorld;
float4 ParticleVertexToWorld(float4 vertex) {
  return mul(_ParticleVertexToWorld, vertex);
}
#else
float4 ParticleVertexToWorld(float4 vertex) {
  return vertex;
}
#endif

