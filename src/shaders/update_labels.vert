#version 330 core

layout (location = 0) in vec3  in_vertex;
layout (location = 1) in float in_remission;
layout (location = 2) in uint  in_label;
layout (location = 3) in uint  in_visible;

uniform mat4 mvp;
uniform int width;
uniform int height;
uniform vec2 window_pos;
uniform float radius;
uniform uint new_label;
uniform bool overwrite;
uniform float minRange;
uniform float maxRange;

uniform int labelingMode;
uniform sampler2DRect triangles;
uniform int numTriangles;

uniform bool removeGround;
uniform float groundThreshold;

out uint out_label;

bool insideTriangle(vec2 p, vec2 v1, vec2 v2, vec2 v3) {
  float b0 = ((v2.x - v1.x) * (v3.y - v1.y) - (v3.x - v1.x) * (v2.y - v1.y));

  if (abs(b0) > 0) {
    // compute barycentric coordinates.
    float b1 = (((v2.x - p.x) * (v3.y - p.y) - (v3.x - p.x) * (v2.y - p.y)) / b0);
    float b2 = (((v3.x - p.x) * (v1.y - p.y) - (v1.x - p.x) * (v3.y - p.y)) / b0);
    float b3 = 1.0f - b1 - b2;

    // only if all are greater equal 0, the point can be inside.
    return (b1 > 0) && (b2 > 0) && (b3 > 0);
  }

  return false;
}

void main()
{
  float range = length(in_vertex);
  vec4 point = mvp * vec4(in_vertex, 1.0);
  point = vec4(point.x/point.w, point.y/point.w, point.z/point.w, 1.0);
  gl_Position = mvp * vec4(in_vertex, 1.0);
  
  out_label = in_label;
    
  vec3 pos =  vec3(0.5f * (point.x + 1.0) * width, 0.5f * (point.y + 1.0) * height, 0.5f * (point.z + 1.0)); 
  pos.y = height - pos.y;
  
  bool visible = (in_visible > uint(0)) && (!removeGround || in_vertex.z > groundThreshold); 
  

  if(visible && !(range < minRange || range > maxRange))
  {
    if(pos.x >= 0 && pos.x < width  && pos.y >= 0 && pos.y < height && pos.z >= 0.0f && pos.z <= 1.0f)
    {
      if(labelingMode == 0)
      {
        float distance =  length(pos.xy - window_pos);
        if( (distance < radius) && (overwrite || in_label == uint(0)))
        {
          out_label = new_label;
        } 
      } 
      else if(labelingMode == 1)
      {
        for(int i = 0; i < numTriangles; ++i)
        {
          vec2 v1 = texture(triangles, vec2(3 * i + 0.5, 0.5)).xy * vec2(width, height);
          vec2 v2 = texture(triangles, vec2(3 * i + 1.5, 0.5)).xy * vec2(width, height);
          vec2 v3 = texture(triangles, vec2(3 * i + 2.5, 0.5)).xy * vec2(width, height);

          if(insideTriangle(pos.xy, v1, v2, v3) && (overwrite || in_label == uint(0)))
          {
            out_label = new_label;
            break;
          }
        }
      }
    }
    
  }
}