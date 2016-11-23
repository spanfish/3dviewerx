#version 330 core

uniform vec3 ambientColor;      //环境光
uniform vec3 lightDirection;    //灯方向
uniform vec3 lightColor;        //灯颜色
uniform vec3 eyeDirection;      //眼睛方向
uniform float shininess;
uniform float strength;
uniform int useMaterial;

struct materialProp {
//    vec3 emission;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
};

uniform materialProp material;

//in vec2      varTexcoord;
in vec3      varNormal;
in vec4      varColor;
out vec4     fragColor;


void main (void)
{
    float diffuse = max(0.0, dot(varNormal, lightDirection));
    float specular = max(0.0, dot(eyeDirection, reflect(lightDirection, varNormal)));
    if(diffuse == 0) {
        specular = 0;
    } else {
        if(useMaterial == 1) {
            specular = pow(specular, shininess * material.shininess);
        } else {
            specular = pow(specular, shininess);
        }
    }
    
    vec3 scatteredLight;
    vec3 reflectedLight;
    if(useMaterial == 1) {
        scatteredLight = lightColor * (ambientColor * material.ambient) + lightColor * (diffuse * material.diffuse);
        reflectedLight = lightColor  * (specular  * material.specular);
    } else {
        scatteredLight = lightColor * ambientColor + lightColor * diffuse;
        reflectedLight = lightColor  * specular;
    }

    vec3 rgb = min(varColor.rgb * scatteredLight + reflectedLight, vec3(1.0, 1.0, 1.0));
    fragColor = vec4(rgb, varColor.a);
}
