const canvas = document.getElementById("canvas")
const gl = canvas.getContext("webgl2");
let mainShaderProgram;

function getUni(uniform) {
  return gl.getUniformLocation(mainShaderProgram, uniform)
}

async function getText(path) {
  return (await fetch(path).then(r => r.text()))
}

async function buildFragmentShader() {
  const shaders = ["./scr/renderer/uniforms.glsl", 
               "./scr/renderer/camera.glsl", 
               "./scr/renderer/ray.glsl", 
               "./scr/renderer/sky.glsl", 
               "./scr/renderer/fragment.glsl"]

  let shader = "#version 300 es\nprecision highp float;\n";
  for (const s of shaders) {
    shader += await getText(s);
  }
  console.log(shader);
  return shader;
}

const CHUNKWIDTH = 32;
const LAYERSIZE = CHUNKWIDTH * CHUNKWIDTH;
const CHUNKSIZE = LAYERSIZE * CHUNKWIDTH;

function buildChunkXYZColors() {
  let colorData = new Float32Array(CHUNKSIZE * 4);
  for (let x = 0; x < CHUNKWIDTH; x++) {
    for (let y = 0; y < CHUNKWIDTH; y++) {
      for (let z = 0; z < CHUNKWIDTH; z++) {
        let index = x+(y*CHUNKWIDTH)+(z*LAYERSIZE);
        colorData[index*4] = x/8;
        colorData[index*4+2] = y/8;
        colorData[index*4+1] = z/8;
        colorData[index*4+3] = Math.round(Math.random());
      }
    }
  }
  return colorData;
}

function buildChunk() {
  let colorData = new Float32Array(CHUNKSIZE * 4);
  for (let i = 0; i < CHUNKSIZE*4; i++) {
    colorData[i] = Math.random();
    if ((i+1)%4 == 0) {
      colorData[i] = Math.round(colorData[i]);
    }
  }
  return colorData;
}

function chunkFromString(string) {
  string = string.split(",", CHUNKSIZE * 4);
  let colorData = new Float32Array(CHUNKSIZE * 4);
  for(let i = 0; i < CHUNKSIZE * 4; i++) {
    colorData[i] = float(string[i]);
  }
}

async function init() {
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
  
  mainShaderProgram = gl.createProgram();
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
}

async function update() {
  gl.uniform3f(getUni("screenSize"), 1/canvas.width, 1/canvas.height, canvas.width/canvas.height); // give fragment shader the screensize and aspect ratio (doing 1/size so we dont have to divide on the gpu)
  gl.uniform3f(getUni("cameraPos"), camera.position.x, camera.position.y, camera.position.z);
  gl.uniform2f(getUni("cameraRot"), camera.angle.yaw, camera.angle.pitch);
  gl.uniform1f(getUni("time"), time);
  gl.uniform1i(getUni("renderMode"), renderMode);
  let colorData = buildChunk();

  if (generate) {
    gl.uniform3i(getUni("ChunkPosition"), 0, 0, 0);

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
    generate = false;
  }
}

async function draw() {
  gl.drawArrays(gl.TRIANGLES, 0, 3);
}

let generate = true;

class Camera {
  constructor(x, y, z, pitch, yaw) {
    this.position = new Vector3(x, y, z);
    this.angle = {}
    this.angle.pitch = pitch;
    this.angle.yaw = yaw;
  }
}

var camera = new Camera(6, 4, -4, 0, 0);
var time = 0.0;
var renderMode = 0;

async function main() {
  await init();
  
  var lastLoop = new Date(); // last frames time
  var loop = function() {
    var thisLoop = new Date();
    var delta = (thisLoop - lastLoop)/1000;
    lastLoop = thisLoop;

    //var fps = 1 / delta; // calculate fps
    //console.log("FPS: " + fps);

    time += delta;
    
    var velocity = new Vector3(isPressed("d") - isPressed("a"), isPressed("e") - isPressed("q"), isPressed("w") - isPressed("s"));
    velocity = velocity.rotateY(-camera.angle.yaw).multiply(delta).multiply(cameraSpeed);
    camera.position = camera.position.add(velocity);

    const pitchDir = isPressed("i") - isPressed("k");
    camera.angle.pitch += delta*cameraSense*pitchDir;
    const yawDir = isPressed("j") - isPressed("l");
    camera.angle.yaw += delta*cameraSense*yawDir;

    if (justPressed("b")) {
      generate = true;
    }
    for(var i = 0; i < 4; i++) {
      if (isPressed(i+1)) {
        renderMode = i;
      }
    }

    updateJustPressed();

    update();
    draw();
    window.requestAnimationFrame(loop,canvas);
  };
  window.requestAnimationFrame(loop,canvas);
}

var keystate = {}
var cameraSense = 120;
var cameraSpeed = 8;
document.addEventListener("keydown", function(evt) {
  keystate[evt.key] = {
    pressed: true,
    justPressed: true
  };
});

document.addEventListener("keyup", function(evt) {
  keystate[evt.key] = {
    pressed: false,
    justPressed: false
  };
});

function isPressed(key) {
  if (!keystate[key]) return false;
  return keystate[key].pressed;
}
function justPressed(key) {
  if (!keystate[key]) return false;
  return keystate[key].justPressed;
}

function updateJustPressed() {
  for (const key of Object.keys(keystate)) {
    keystate[key].justPressed = false;
  }
}

main();