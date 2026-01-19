#version 330 core

in vec3 ourColor;
in vec2 TexCoord;

out vec4 FragColor;

uniform sampler2D tex1;
uniform sampler2D tex2;

void main() {
    // FragColor = vec4(1.0, 0.5, 0.2, 1.0);
    // FragColor = vec4(ourColor, 1.0);
    // 0.2 -> 80% of first, 20% of second
    FragColor = mix(texture(tex1, TexCoord), texture(tex2, TexCoord), 0.2);
}

