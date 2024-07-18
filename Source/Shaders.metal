#include <metal_stdlib>
using namespace metal;

struct Arguments
{
	float2 resolution;
};

struct RasterizerData
{
	float4 position_ndc [[position]];
	float2 position;
	float4 color;
};

constant float2 positions[] = {
        float2(0, 0),
        float2(0, 1),
        float2(1, 1),
        float2(1, 1),
        float2(1, 0),
        float2(0, 0),
};

constant float4 colors[] = {
        float4(1, 0, 0, 1),
        float4(0, 1, 0, 1),
        float4(0, 0, 1, 1),
        float4(1, 0, 0, 1),
        float4(0, 1, 0, 1),
        float4(0, 0, 1, 1),
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
	output.color = colors[vertex_id];
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
	uint pixel_diameter = 2;
	uint x = (uint)input.position.x / pixel_diameter;
	uint y = (uint)input.position.y / pixel_diameter;
	uint unique_index = y * ((uint)arguments.resolution.x / pixel_diameter) + x;
	float random_float = RandFloat(unique_index);
	return input.color * pow(random_float, 0.3);
}
