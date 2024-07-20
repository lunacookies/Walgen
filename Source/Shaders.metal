#include <metal_stdlib>
using namespace metal;

// random number generator from Apple example code
// traced back to https://www.arendpeter.com/Perlin_Noise.html
float
RandFloat(uint seed)
{
	seed ^= seed << 13;
	seed = seed * (seed * seed * 15731 + 789221) + 1376312589;
	return ((1.0 - seed / 1073741824.0f) + 1.0f) / 2.0f;
}

kernel void
GenerateNoise(uint2 position_in_grid [[thread_position_in_grid]],
        uint2 grid_size [[threads_per_grid]],
        texture2d<float, access::write> texture)
{
	uint index_in_grid = position_in_grid.y * grid_size.x + position_in_grid.x;
	texture.write(RandFloat(index_in_grid), position_in_grid);
}

struct Arguments
{
	float2 resolution;
	float3 background_color;
	float noise_influence;
	float noise_bias;
	float noise_threshold;
	uint pixel_size;
	texture2d<float> noise_texture;
};

struct RasterizerData
{
	float4 position [[position]];
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
	output.position = vertex_position_ndc;
	return output;
}

fragment float4
FragmentMain(RasterizerData input [[stage_in]], constant Arguments &arguments)
{
	uint2 noise_texture_size =
	        uint2(arguments.noise_texture.get_width(), arguments.noise_texture.get_height());

	uint2 position = (uint2)input.position.xy / arguments.pixel_size;
	float2 position_uv = ((float2)position + 0.5) / (float2)noise_texture_size;

	sampler sampler(address::repeat);
	float random_float = arguments.noise_texture.sample(sampler, position_uv).r;
	random_float = clamp(pow(random_float, arguments.noise_bias), 0.f, 1.f);
	random_float *= step(arguments.noise_threshold, random_float);

	return float4(
	        arguments.background_color * mix(1, random_float, arguments.noise_influence), 1);
}
