#version 120
uniform sampler2D iChannel0;

void main()
{
	int x = int(gl_TexCoord[0].x * 800);
	int y = int(gl_TexCoord[0].y * 600);
	vec2 uv = vec2(gl_TexCoord[0].x - mod(x, 2) / 800, gl_TexCoord[0].y + mod(y + 1, 2) / 600);
	vec4 c = texture2D(iChannel0, uv);
	gl_FragColor = c;
}