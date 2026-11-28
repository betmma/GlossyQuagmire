uniform float progress;
uniform Image canvas;
uniform vec2 canvasSize;
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    // Get the original texture color
    vec4 texcolor = Texel(tex, texture_coords)*color;
    // get text canvas
    vec2 uv=screen_coords/canvasSize+progress*0.4;
    vec4 textColor=Texel(canvas,uv);
    // fade text
    textColor.a=textColor.a*min(1.0,min(progress*4.0,(1.0-progress)*4.0))*0.5;
    texcolor=mix(texcolor,textColor,textColor.a);
    return texcolor;
}