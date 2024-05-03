async function getText(path) {
  return (await fetch(path).then(r => r.text()))
}

async function buildFragmentShader() {
  let shader = "#version 300 es\nprecision highp float;\n";
  shader += await getText("./scr/renderer/camera.glsl");
  shader += await getText("./scr/renderer/ray.glsl");
  shader += await getText("./scr/renderer/random.glsl");
  shader += await getText("./scr/renderer/fragment.glsl");
  return shader;
}
const CHUNKWIDTH = 8;
const LAYERSIZE = CHUNKWIDTH * CHUNKWIDTH;
const CHUNKSIZE = LAYERSIZE * CHUNKWIDTH;

function buildChunk() {
  let colorData = new Float32Array(CHUNKSIZE * 4);
  for (let i = 0; i < CHUNKSIZE * 4; i++) {
    // Generate random color values between 0 and 1
    colorData[i] = i/(CHUNKSIZE*4);
    if ((i+1)%4 == 0) { // if on the fourth parameter (alpha) round it to 0 or 1 solid or empty
      colorData[i] = Math.round(colorData[i]);
      colorData[i] = 1.0;
    }
  }
  return colorData;
}


async function main() {
  const canvas = document.getElementById("canvas")
  const gl = canvas.getContext("webgl2");

  const triangleVerts = [
    -1, -3,// bottom left
    -1, 1, // top left
    3, 1, // top right
  ];
  
  const triangleCPUBuffer = new Float32Array(triangleVerts);

  const triangleGPUBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, triangleGPUBuffer);
  gl.bufferData(gl.ARRAY_BUFFER, triangleCPUBuffer, gl.STATIC_DRAW);
  gl.bindBuffer(gl.ARRAY_BUFFER, null);

  async function compileShader(source, type) {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      const compileError = gl.getShaderInfoLog(shader);
      console.log(compileError);
      return;
    }
    return shader
  }

  const vertexShaderSource = await getText("./scr/renderer/vertex.glsl");
  const vertexShader = await compileShader(vertexShaderSource, gl.VERTEX_SHADER);

  const fragmentShaderSource = await buildFragmentShader();
  const fragmentShader = await compileShader(fragmentShaderSource, gl.FRAGMENT_SHADER)
  
  const mainShaderProgram = gl.createProgram();
  gl.attachShader(mainShaderProgram, vertexShader);
  gl.attachShader(mainShaderProgram, fragmentShader);
  gl.linkProgram(mainShaderProgram);

  if (!gl.getProgramParameter(mainShaderProgram, gl.LINK_STATUS)) {
    const linkError = gl.getProgramInfoLog(mainShaderProgram);
    console.log(linkError);
    return;
  }

  const vertexPositionAttribLocation = gl.getAttribLocation(mainShaderProgram, "vertexPosition");
  if (vertexPositionAttribLocation < 0) {
    console.log("Failed to get attrib location for vertexPosition");
    return;
  }

  const screenSizeUniformLocation = gl.getUniformLocation(mainShaderProgram, "screenSize");
  if (screenSizeUniformLocation < 0) {
    console.log("Failed to get uniform location for screenSize");
    return;
  }
  
  function getUni(uniform) {
    return gl.getUniformLocation(mainShaderProgram, uniform)
  }

  // Output merger
  canvas.width = canvas.clientWidth;
  canvas.height = canvas.clientHeight;
  gl.clearColor(0.0, 0.0, 0.0, 1.0);
  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  
  // Rasterizer
  gl.viewport(0, 0, canvas.width, canvas.height);

  //setup gpu program
  gl.useProgram(mainShaderProgram);
  gl.enableVertexAttribArray(vertexPositionAttribLocation);

  // Input assembler
  gl.bindBuffer(gl.ARRAY_BUFFER, triangleGPUBuffer);
  gl.vertexAttribPointer(
    vertexPositionAttribLocation, // which attrib to use
    2, // how many components in the attrib
    gl.FLOAT, // what type of data are we sending over
    false, // should we normalize the data
    2*Float32Array.BYTES_PER_ELEMENT, // how many bytes forward do we skip before we get the next position in buffer (0 makes gpu figure it out)
    0 // how many bytes do we skip before reading attib
  );
  
  gl.uniform3f(getUni("screenSize"), 1/canvas.width, 1/canvas.height, canvas.width/canvas.height); // give fragment shader the screensize and aspect ratio (doing 1/size so we dont have to divide on the gpu)
  gl.uniform3f(getUni("cameraPos"), -2, 12, -2);
  gl.uniform2f(getUni("cameraRot"), -45.0, -45);
  gl.uniform3i(getUni("ChunkPosition"), 0, 0, 0);

  let colorData = buildChunk();

  // Create 3D texture
  let chunkDataTexture = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_3D, chunkDataTexture);

  // Set texture parameters
  gl.texParameteri(gl.TEXTURE_3D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_3D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE);

  // Fill texture with data
  gl.texImage3D(gl.TEXTURE_3D, 0, gl.RGBA32F, CHUNKWIDTH, CHUNKWIDTH, CHUNKWIDTH, 0, gl.RGBA, gl.FLOAT, colorData);

  gl.activeTexture(gl.TEXTURE0);
  gl.bindTexture(gl.TEXTURE_3D, chunkDataTexture);

  gl.uniform1i(getUni("chunkData"), 0); // Texture unit 0

  // draw call (also configures primitives)
  gl.drawArrays(gl.TRIANGLES, 0, 3)
}

main();