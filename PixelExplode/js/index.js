/**
 * Created by josh on 06/07/2016.
 */

Constants = {};

Constants.FLOAT_SIZE_BYTES        = 4;
Constants.INT_SIZE_BYTES          = 4;
Constants.SHORT_SIZE_BYTES        = 2;

Constants.UNIFORM_PROJECTION_MAT  = "uPMatrix";
Constants.UNIFORM_MODELVIEW_MAT   = "uMVMatrix";
Constants.UNIFORM_NORMAL          = "uNormalMatrix";
Constants.UNIFORM_SAMPLER_0       = "uSampler";

var engine;

document.addEventListener("DOMContentLoaded", init, false);

function init(){
    engine = new Engine(document.getElementById("canvas"));
    engine.start();
}

function getTextFromElement(elementId){
    var str = "";
    var elem = document.getElementById(elementId);
    var k = elem.firstChild;
    while (k) {
        if (k.nodeType == 3) {
            str += k.textContent;
        }
        k = k.nextSibling;
    }

    return str;
}

class Engine{

    constructor(canvas){
        this.canvas = canvas;
        this.gl = null;

        this.textureImage = null;

        this.running = false;
        this.lastUpdateTimestamp = 0;

        this.camera = new Camera("camera");
        this.camera.move(0,0,850);
        this.camera.type = CameraType.Perspective;
        this.models = [];

        this.force = 10.0;
        this.radius = 20;

        this.targetPositions = [
            [0, -100, 0],
            [0, 0, 0],
            [0, 100, 0],
        ]

        this.onAnimationFrame = this.onAnimationFrame.bind(this);
        this.onResize = this.onResize.bind(this);
        this.onOrientationChange = this.onOrientationChange.bind(this);
        this.onDrop = this.onDrop.bind(this);
        this.onCancelDrag = this.onCancelDrag.bind(this);
        this.onFileUploaded = this.onFileUploaded.bind(this);

        window.addEventListener('dragover', this.onCancelDrag, false);
        window.addEventListener('dragenter', this.onCancelDrag, false);
        window.addEventListener('dragexit', this.onCancelDrag, false);
        window.addEventListener('drop', this.onDrop, false);
        window.addEventListener("resize", this.onResize);
        window.addEventListener("orientationchange", this.onOrientationChange);

        this._init3D();

        this.orbit = 0.0;
    }

    _init3D(){
        try {
            this.gl = this.canvas.getContext("experimental-webgl");
        }
        catch (e) {
            console.log("ERROR " + e);
        }

        if (!this.gl) {
            throw new Error("WebGL not supported");
        }

        this.onResize();

        this.createParticles();

        return this.gl;
    }

    _initViewport(){
        this.gl.viewport(0, 0, this.canvas.width, this.canvas.height);
    }

    start(){
        this.lastUpdateTimestamp = Date.now();
        this.running = true;

        window.requestAnimationFrame(this.onAnimationFrame);
    }

    stop(){
        this.running = false;
    }

    onAnimationFrame(){
        if(!this.running){
            return;
        }

        var elapsedTime = Date.now() - this.lastUpdateTimestamp;
        this.lastUpdateTimestamp = Date.now();

        elapsedTime /= 1000; // elapsedTime in ms

        this.onUpdate(elapsedTime);
        this.onRender();

        window.requestAnimationFrame(this.onAnimationFrame);
    }

    onUpdate(et){

        this.camera.update(et);

        for(var i=0; i<this.models.length; i++){
            var model = this.models[i];

            if(model.tag == "particles"){
                this.updateParticles(et, model.mesh);
                //model.rotate(0,et * 0.1, 0);
            }

            model.update(et);
        }
    }

    onRender(){
        // Clear the canvas
        this.gl.clearColor(0.0, 0.0, 0.0, 1.0);

        // Clear the color buffer bit
        this.gl.clear(this.gl.COLOR_BUFFER_BIT | this.gl.DEPTH_BUFFER_BIT);

        // Enable the depth test
        this.gl.enable(this.gl.DEPTH_TEST);
        this.gl.enable(this.gl.BLEND);

        this.gl.depthFunc(this.gl.LESS);
        this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE);

        for(var i=0; i<this.models.length; i++){
            this.models[i].draw(this.gl, this.camera);
        }
    }

    onCancelDrag(event){
        if(event.preventDefault)
            event.preventDefault();

        return false;
    }

    onDrop(evt){
        event.stopPropagation();
        event.preventDefault();

        // query what was dropped
        var files = event.dataTransfer.files;

        // if we have something
        if(files.length) {
            var file = files[0];
            var fileReader = new FileReader();
            fileReader.onloadend = this.onFileUploaded;
            fileReader.readAsDataURL(file);
        }

        return false;
    }
    onFileUploaded(event){
        if(event.target.result.match(/^data:image/)){

            if(this.textureImage != null){
                // TODO: remove previous information
            }

            var imageSrc = event.target.result;
            this.textureImage = document.createElement("img");
            this.textureImage.src = imageSrc;

            this.createParticles(this.textureImage);
        }
    }

    updateParticles(et, mesh){

        for(var i=0; i<mesh.vertexData.length; i+= mesh.stride){
            //debugger;

            var x = mesh.vertexData[i];
            var y = mesh.vertexData[i+1];
            var z = mesh.vertexData[i+2];

            var r = mesh.vertexData[i+3];
            var g = mesh.vertexData[i+4];
            var b = mesh.vertexData[i+5];
            var a = mesh.vertexData[i+6];

            var size = mesh.vertexData[i+7];

            var targetIndex = 0;
            if(r > g && r > b){
                targetIndex = 0;
            } else if( g > r && g > b){
                targetIndex = 1;
            } else{
                targetIndex = 2;
            }

            var targetPosition = this.targetPositions[targetIndex];
            var tx = targetPosition[0];
            var ty = targetPosition[1];
            var tz = targetPosition[2];

            var source = vec3.create([x, y, z]);
            var target = vec3.create([tx, ty, tz]);
            var diff = vec3.create();
            vec3.subtract(target, source, diff);
            var dis = vec3.length(diff);
            if(dis > this.radius){
                var dir = vec3.create();
                vec3.normalize(diff, dir);

                mesh.vertexData[i] += this.force * et * dir[0];
                mesh.vertexData[i+1] += this.force * et * dir[1];
                mesh.vertexData[i+2] += this.force * et * dir[2];
            }
        }

        mesh.setVertexBuffer(this.gl);
    }

    createParticles(image){
        if(image == null){
            return;
        }

        var padding = Math.max(this.canvas.width * 0.1, this.canvas.height * 0.1) * 2;

        var ratio = 1. / Math.max(image.width/(this.canvas.width-padding), image.height/(this.canvas.height-padding));
        var scaledWidth = image.width * ratio;
        var scaledHeight = image.height * ratio;

        var tmpCanvas = document.createElement('canvas');
        tmpCanvas.width = scaledWidth;
        tmpCanvas.height = scaledHeight;

        console.log("ratio " + ratio + ", scaledWidth " + scaledWidth + ", scaledheight" + scaledHeight);

        var tmpContext = tmpCanvas.getContext("2d");
        tmpContext.drawImage(
            image,
            0,0, tmpCanvas.width,tmpCanvas.height);

        var pixels = tmpContext.getImageData(0, 0, tmpCanvas.width, tmpCanvas.height);
        var step = 5.;
        var density = step * 0.7;
        var x = 0, y = 0;

        var ox = -tmpCanvas.width / 2;
        var oy = -tmpCanvas.height / 2;

        var mesh = new Mesh("particles");
        mesh.addVertextDefinition("vertexPosition", 3, this.gl.FLOAT);
        mesh.addVertextDefinition("vertexColour", 4, this.gl.FLOAT);
        mesh.addVertextDefinition("pointSize", 1, this.gl.FLOAT);

        for(y=0; y<tmpCanvas.height; y += step){
            for(x=0; x<tmpCanvas.width; x += step){

                var flippedY = tmpCanvas.height - y;
                var pixelIndex = ((flippedY * tmpCanvas.width) + x) * 4;

                if(pixels.data[pixelIndex + 3] > 0 || true){
                    // add particle position
                    mesh.vertexData.push(ox + x); // x
                    mesh.vertexData.push(oy + y); // y
                    mesh.vertexData.push(0.0); // z

                    mesh.vertexData.push(pixels.data[pixelIndex] / 255.0); // r
                    mesh.vertexData.push(pixels.data[pixelIndex + 1] / 255.0); // g
                    mesh.vertexData.push(pixels.data[pixelIndex + 2] / 255.0); // b
                    mesh.vertexData.push(pixels.data[pixelIndex + 3] / 255.0); // a

                    mesh.vertexData.push(density); // pixel size
                }
            }
        }

        mesh.setVertexBuffer(this.gl);

        mesh = mesh;

        var shader = new Shader(
            getTextFromElement("vertex_shader"),
            getTextFromElement("fragment_shader")
        )

        shader.load(this.gl);

        var material = new Material("material", shader);
        var texture = Texture.createTexture(this.gl, "particle_tex", "images/particle.png");
        var model = new Model("particles", mesh, material, texture);
        this.models.push(model);
    }

    onOrientationChange(){
        this.onResize();
    }

    onResize(){
        this.canvas.width = document.width | document.body.clientWidth;
        this.canvas.height = document.height | document.body.clientHeight;

        this.camera.setViewSize(this.canvas.width, this.canvas.height);

        this._initViewport();
    }
}

const CameraType = {
    Perspective     : 0,
    Orthorgrpahic   : 1
}

class Material{

    constructor(tag, shader){
        this.tag = tag;
        this.shader = shader;

        this.texture = null;

        this.projectionMatrix = mat4.create();
        this.viewMatrix = mat4.create();
        this.modelMatrix = mat4.create();

        this._modelViewMatrix = mat4.create();
        this._modelViewProjectionMatrix = mat4.create();
        this._normalMatrix = mat4.create();
    }

    draw(gl, mesh){
        var program = this.shader.program;

        this.shader.activate(gl);

        this.initMatrixUniforms(gl, program);
        this.initTextureUniforms(gl, program);

        mesh.draw(gl, program);

        this.shader.deactivate(gl);
    }

    initMatrixUniforms(gl, program){
        mat4.multiply(this.viewMatrix, this.modelMatrix, this._modelViewMatrix);
        mat4.multiply(this.projectionMatrix, this._modelViewMatrix, this._modelViewProjectionMatrix);

        mat4.identity(this._normalMatrix);
        mat4.set(this._modelViewMatrix, this._normalMatrix);
        mat4.inverse(this._normalMatrix);
        mat4.transpose(this._normalMatrix);

        // projection matrix
        var pMatrixPtr = gl.getUniformLocation(program, Constants.UNIFORM_PROJECTION_MAT);
        if( pMatrixPtr != -1 ){
            gl.uniformMatrix4fv(pMatrixPtr, false, this.projectionMatrix);
        }

        // model view matrix
        var mvMatrixPtr = gl.getUniformLocation(program, Constants.UNIFORM_MODELVIEW_MAT);
        if( mvMatrixPtr != -1 ){
            gl.uniformMatrix4fv(mvMatrixPtr, false, this._modelViewMatrix);
        }

        // normal matrix
        var normalMatrixPtr = gl.getUniformLocation(program, Constants.UNIFORM_NORMAL);
        if( normalMatrixPtr != -1 ){
            gl.uniformMatrix4fv(normalMatrixPtr, false, this._normalMatrix);
        }
    }

    initTextureUniforms(gl, program){
        if( this.texture != null && this.texture.loaded){
            gl.activeTexture(gl.TEXTURE0);
            gl.bindTexture(gl.TEXTURE_2D, this.texture._textureId);
            var samplerPtr = gl.getUniformLocation(program, Constants.UNIFORM_SAMPLER_0);
            if( samplerPtr != -1 ){
                gl.uniform1i(samplerPtr, 0);
            }

        }
    }
}

class Transform{

    constructor(tag){
        this.tag = tag;

        this.position = vec3.create();
        this.rotation = vec3.create()
        this.scale = vec3.create();
        this.scale[0] = this.scale[1] = this.scale[2] = 1;
        this.modelMatrix = mat4.create();

        mat4.identity(this.modelMatrix);
    }

    setPosition(x, y, z){
        this.position[0] = x;
        this.position[1] = y;
        this.position[2] = z;
    }

    move(dx, dy, dz){
        this.position[0] += dx;
        this.position[1] += dy;
        this.position[2] += dz;
    }

    setRotation(x, y, z){
        this.rotation[0] = x;
        this.rotation[1] = y;
        this.rotation[2] = z;
    }

    rotate(dx, dy, dz){
        this.rotation[0] += dx;
        this.rotation[1] += dy;
        this.rotation[2] += dz;
    }

    setUnfiformScale(s){
        this.scale[0] = s;
        this.scale[1] = s;
        this.scale[2] = s;
    }

    getModelMatrix(){
        return this.modelMatrix;
    }

    updateModelMatrix(){
        mat4.identity(this.modelMatrix);

        mat4.translate(this.modelMatrix, this.position, this.modelMatrix);

        mat4.rotateX(this.modelMatrix, this.rotation[0]);
        mat4.rotateY(this.modelMatrix, this.rotation[1]);
        mat4.rotateZ(this.modelMatrix, this.rotation[2]);

        mat4.scale(this.modelMatrix, this.scale, this.modelMatrix);
    }

    update(dt){

    }
}

class Camera extends Transform{

    constructor(tag){
        super(tag);

        this.viewWidth = 0;
        this.viewHeight = 0;

        // perspective properties
        this.fov = 45.0;
        this._near = 0.01;
        this._far = 10000;

        this.orthScale = 1.0;

        this.viewMatrix = mat4.create();
        mat4.identity(this.viewMatrix);

        this.projectionMatrix = mat4.create();
        mat4.identity(this.projectionMatrix);

        this.type = CameraType.Perspective;

        this.viewProjectionMatrix = mat4.create();
        mat4.identity(this.viewProjectionMatrix);

        this.invertedViewProjectionMatrix = mat4.create();
        mat4.identity(this.invertedViewProjectionMatrix);
    }

    update(dt){
        super.update(dt);

        this.updateModelMatrix();

        mat4.identity(this.viewMatrix);
        mat4.inverse(this.modelMatrix, this.viewMatrix);


        mat4.identity(this.viewProjectionMatrix);
        mat4.identity(this.invertedViewProjectionMatrix);

        mat4.multiply(this.projectionMatrix, this.viewMatrix, this.viewProjectionMatrix);
        mat4.inverse(this.viewProjectionMatrix, this.invertedViewProjectionMatrix);
    }

    setViewSize(viewWidth, viewHeight){
        this.viewWidth = viewWidth;
        this.viewHeight = viewHeight;

        if( this.type == CameraType.Perspective ){
            console.log( "Camera setting up projection matrix ; fov " + this.fov + ", viewWidth " + this.viewWidth + ", viewHeight " + this.viewHeight );
            this.projectionMatrix = mat4.perspective(this.fov, this.viewWidth / this.viewHeight, this._near, this._far);
        } else{
            console.log( "Camera setting up orthographic matrix ; viewWidth " + this.viewWidth + ", viewHeight " + this.viewHeight );
            var aspectRatio = viewWidth > viewHeight ? parseFloat(viewWidth) / parseFloat(viewHeight) : parseFloat(viewHeight) / parseFloat(viewWidth);

            if( viewWidth > viewHeight ){
                this.projectionMatrix = mat4.ortho(-aspectRatio * this.orthScale,
                    aspectRatio * this.orthScale,
                    -1.0 * this.orthScale,
                    1.0 * this.orthScale,
                    this._near,
                    this._far);
            } else{
                this.projectionMatrix = mat4.ortho(
                    -1.0 * this.orthScale,
                    1.0 * this.orthScale,
                    -aspectRatio * this.orthScale,
                    aspectRatio * this.orthScale,
                    this._near,
                    this._far);
            }
        }
    }
}

class Model extends Transform{

    constructor(tag, mesh, material, texture){
        super(tag);

        this.mesh = mesh;
        this.material = material;
        this.texture = texture;
    }

    update(dt){
        if(!this.isReady){
            return;
        }

        super.update(dt);

        this.updateModelMatrix();
    }

    draw(gl, camera){
        if(!this.isReady){
            return;
        }

        mat4.set(camera.projectionMatrix, this.material.projectionMatrix);
        mat4.set(camera.viewMatrix, this.material.viewMatrix);

        this.material.texture = this.texture;

        mat4.set(this.modelMatrix, this.material.modelMatrix);

        this.material.draw(gl, this.mesh);
    }

    get isReady(){
        return (this.mesh != null) &&
            (this.material != null) &&
            (this.texture == null || (this.texture.loaded && this.texture._textureId != -1))
    }
}

class Texture{

    static createTexture(gl, tag, imageSource){
        var tex = new Texture(tag);
        tex.loadTexture(gl, imageSource);
        return tex;
    }

    constructor(tag){
        this.tag = tag;
        this._imageSource;
        this._textureId = -1;
        this.loaded = false;
    }

    loadTexture(gl, imageSource){
        this._imageSource = imageSource;
        this._image = new Image();

        var instance = this;
        this._image.onload = function(){
            instance._onImageLoaded(gl);
        }
        this._image.onerror = function(){
            instance._onImageError();
        }

        this._image.src = this._imageSource;
    }

    _onImageLoaded(gl){
        if(this._textureId == -1){
            this._textureId = gl.createTexture();
        }
        // bind the texture
        gl.bindTexture(gl.TEXTURE_2D, this._textureId);
        //gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, 1);
        // load the image into OpenGL
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, this._image);
        // set texture properties
        //gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        //gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);

        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);

        // gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_NEAREST);
        // gl.generateMipmap(gl.TEXTURE_2D);

        //gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        //gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

        // unbind texture
        gl.bindTexture(gl.TEXTURE_2D, null);

        this.loaded = true;
    }

    _onImageError(gl){
        console.error("Error loading image for texture");
    }
}

class VertexDefinition{

    constructor(attribute, count, type, offset){
        this.attribute = attribute;
        this.count = count;
        this.type = type;
        this.offset = offset;
    }
}

class Mesh{

    constructor(tag){
        this.tag = tag;

        this.vertexBufferStride = 0;

        this.vertexDefinitions = [];
        this.vertexData = [];
        this.vertexBuffer = -1;
    }

    get vertexCount() {
        var count = 0;

        this.vertexDefinitions.forEach(function(element, index, array){
            count += element.count;
        });

        return this.vertexData.length/count;
    }

    get stride() {
        var count = 0;

        this.vertexDefinitions.forEach(function(element, index, array){
            count += element.count;
        });

        return count;
    }


    addVertextDefinition(attribute, count, type){
        var offsetCount = 0;
        for( var i=0; i<this.vertexDefinitions.length; i++ ){
            offsetCount += this.vertexDefinitions[i].count;
        }

        var offset = offsetCount * Constants.FLOAT_SIZE_BYTES;

        this.vertexBufferStride = (offsetCount + count) * Constants.FLOAT_SIZE_BYTES;

        this.vertexDefinitions.push(new VertexDefinition(attribute, count, type, offset))
    }

    setVertexBuffer(gl){

        if(this.vertexBuffer == -1){
            this.vertexBuffer = gl.createBuffer();
        }

        //Bind appropriate array buffer to it
        gl.bindBuffer(gl.ARRAY_BUFFER, this.vertexBuffer);

        // Pass the vertex data to the buffer
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(this.vertexData), gl.STATIC_DRAW);

        // unbind
        gl.bindBuffer(gl.ARRAY_BUFFER, null);
    }

    draw(gl, program){
        // bind
        gl.bindBuffer(gl.ARRAY_BUFFER, this.vertexBuffer);

        // enable each attribute
        for( var i=0; i<this.vertexDefinitions.length; i++ ){
            var vd = this.vertexDefinitions[i];
            var attrPtr = gl.getAttribLocation(program, vd.attribute);

            if( attrPtr == -1 ){
                console.error("Mesh.draw - error while trying to bind attributes; missing " + vd.attribute );
            } else{
                gl.enableVertexAttribArray(attrPtr);
                gl.vertexAttribPointer(attrPtr, vd.count, vd.type, false, this.vertexBufferStride, vd.offset);
            }
        }

        // draw
        gl.drawArrays(gl.POINTS, 0, this.vertexCount);

        // unbind attributes
        for( var i=0; i<this.vertexDefinitions.length; i++ ){
            var vd = this.vertexDefinitions[i];
            var attrPtr = gl.getAttribLocation(program, vd.attribute);

            if( attrPtr == -1 ){
                //console.error("Mesh.draw - error while trying to bind attributes; missing " + vd.attribute );
            } else{
                gl.disableVertexAttribArray(attrPtr);
            }
        }

        // UNBIND
        gl.bindBuffer(gl.ARRAY_BUFFER, null);
    }

}

class Shader{

    constructor(vsSource, fsSource){
        this.vsSource = vsSource;
        this.fsSource = fsSource;

        this.program = -1;
        this._vertexShader;
        this._fragmentShader;
    }

    load(gl){
        this._vertexShader = gl.createShader(gl.VERTEX_SHADER);
        this._fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);

        gl.shaderSource(this._vertexShader, this.vsSource);
        gl.shaderSource(this._fragmentShader, this.fsSource);

        this.compile(gl);
        this.createProgram(gl);
    }

    compile(gl){
        gl.compileShader(this._vertexShader);
        if (!gl.getShaderParameter(this._vertexShader, gl.COMPILE_STATUS)) {
            console.log( "ERROR :: Error compiling vertex shader: " + gl.getShaderInfoLog(this._vertexShader));
            return false;
        }
        gl.compileShader(this._fragmentShader);
        if (!gl.getShaderParameter(this._fragmentShader, gl.COMPILE_STATUS)) {
            console.log( "ERROR :: Error compiling fragment shader: " + gl.getShaderInfoLog(this._fragmentShader));
            return false;
        }

        return true;
    }

    createProgram(gl){
        this.program = gl.createProgram();

        gl.attachShader(this.program, this._vertexShader);
        gl.attachShader(this.program, this._fragmentShader);

        gl.linkProgram(this.program);
        if (!gl.getProgramParameter(this.program, gl.LINK_STATUS)) {
            console.log("ERROR :: Unable to initialize the shader program.");
            return false;
        }

        return true;
    }

    activate(gl){
        gl.useProgram(this.program);
    }

    deactivate(gl){
        gl.useProgram(null);
    }

    dispose(gl){
        this.use(gl);

        gl.detachShader(this.program, this._vertexShader);
        gl.detachShader(this.program, this._fragmentShader);

        gl.deleteShader(this._vertexShader);
        gl.deleteShader(this._fragmentShader);

        gl.deleteProgram(this.program);

        this.program = 0;

        this.use(gl);
    }
}