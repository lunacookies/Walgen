#include <metal_stdlib>
using namespace metal;

struct Arguments
{
	float2 resolution;
	float3 background_color;
	float noise_influence;
	float noise_bias;
	uint pixel_size;
};

struct RasterizerData
{
	float4 position_ndc [[position]];
	float2 position;
};

constant float2 positions[] = {
        float2(0, 0),
        float2(0, 1),
        float2(1, 1),
        float2(1, 1),
        float2(1, 0),
        float2(0, 0),
};

vertex RasterizerData
VertexMain(uint vertex_id [[vertex_id]], constant Arguments &arguments)
{
	float2 vertex_position = arguments.resolution * positions[vertex_id];

	float4 vertex_position_ndc = float4(0, 0, 0, 1);
	vertex_position_ndc.xy = 2 * (vertex_position / arguments.resolution) - 1;
	vertex_position_ndc.y *= -1;

	RasterizerData output = {};
	output.position_ndc = vertex_position_ndc;
	output.position = vertex_position;
	return output;
}

// random number generator from Apple example code
// traced back to https://www.arendpeter.com/Perlin_Noise.html
float
RandFloat(uint seed)
{
	seed ^= seed << 13;
	seed = seed * (seed * seed * 15731 + 789221) + 1376312589;
	return ((1.0 - seed / 1073741824.0f) + 1.0f) / 2.0f;
}

fragment float4
FragmentMain(RasterizerData input [[stage_in]], constant Arguments &arguments)
{
	uint x = (uint)input.position.x / arguments.pixel_size;
	uint y = (uint)input.position.y / arguments.pixel_size;
	uint unique_index = y * ((uint)arguments.resolution.x / arguments.pixel_size) + x;
	float random_float = RandFloat(unique_index);
	random_float = clamp(pow(random_float, arguments.noise_bias), 0.f, 1.f);
	return float4(
	        arguments.background_color * mix(1, random_float, arguments.noise_influence), 1);
}
