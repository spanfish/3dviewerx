#version 330 core
// Declare our modelViewProjection matrix that we'll compute
//  outside the shader and set each frame
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform vec4 constantColor; //固定颜色
uniform mat3 normalMatrix;

in vec4  inPosition;
in vec4  inColor;
//in vec2  inTexcoord;
in vec3  inNormal;

//out vec2 varTexcoord;
out vec4 varColor;
out vec3 varNormal;

void main (void) 
{
	gl_Position	= projectionMatrix * modelViewMatrix * inPosition;

    //varTexcoord = inTexcoord;
    varColor = constantColor;
    
    // transform the normal, without perspective, and normalize it
    varNormal = normalize(normalMatrix * inNormal);;
}
