/**
 * Created by josh on 25/07/2016.
 */

document.addEventListener("DOMContentLoaded", init, false);

var sandstorm = null;
var serviceAPI = null;

function init(){
    serviceAPI = new ServiceAPI();
    sandstorm = new Sandstorm(document.getElementById("canvas"));

    console.log("fetching dominate colours");

    var clusters = getQueryStringParameterByName("clusters");
    if(clusters == null || clusters.length == 0){
        clusters = "-1";
    }

    serviceAPI.dominatecolours(clusters, function(api, result){
        console.log("fetched dominate colours");

        // set colour set
        if(result != null){
            var colourClusters = result["colour_clusters"];
            for(var i=0; i<colourClusters.length; i++){
                var r = colourClusters[i]["colour"][0];
                var g = colourClusters[i]["colour"][1];
                var b = colourClusters[i]["colour"][2];
                var colour = new Vec3(r, g, b);
                sandstorm.colourSet.push(colour);
            }
        }

        sandstorm.start();
    });
}

function randomF(min, max){
    return (Math.random() * (max-min)) + min;
}

function randomI(min, max){
    return Math.floor((Math.random() * (max-min)) + min);
}

function constrain(val, min, max){
    return Math.min(Math.max(val, min), max);
}

function mapRange(value, low1, high1, low2, high2) {
    return low2 + (high2 - low2) * (value - low1) / (high1 - low1);
}

class Vec3{

    constructor(x=0, y=0, z=0){
        this.x = x;
        this.y = y;
        this.z = z;
    }

    set(x, y, z){
        this.x = x;
        this.y = y;
        this.z = z;
    }

    copy(other){
        this.x = other.x;
        this.y = other.y;
        this.z = other.z;
    }

    createCopy(){
        return new Vec3(this.x, this.y, this.z);
    }

    get colourStyle(){
        return "rgb(" + Math.floor(this.x) + ", " + Math.floor(this.y) + ", " + Math.floor(this.z) + ")";
    }

    static lerp(source, target, t){
        var dx = source.x - target.x;
        var dy = source.y - target.y;
        var dz = source.z - target.z;

        return new Vec3(source.x + t * dx, source.y + t * dy, source.z + t * dz);
    }
}

class Vec2{

    constructor(x=0, y=0){
        this.x = x;
        this.y = y;
    }

    add(other){
        this.x += other.x;
        this.y += other.y;
    }

    mul(s){
        this.x *= s;
        this.y *= s;
    }

    set(x, y){
        this.x = x;
        this.y = y;
    }

    normalize(){
        var length = this.length;

        if(length == 0){
            this.x = 0;
            this.y = 0;
        } else{
            this.x /= length;
            this.y /= length;
        }
    }

    get length(){
        return Math.sqrt(this.x * this.x + this.y * this.y);
    }

    copy(other){
        this.x = other.x;
        this.y = other.y;
    }

    createCopy(){
        return new Vec2(this.x, this.y);
    }

    static distance (v1, v2) {
        var dx = v1.x - v2.x;
        var dy = v1.y - v2.y;
        return Math.sqrt(dx * dx + dy * dy);
    }

    static add(v1, v2){
        return new Vec2(v1.x + v2.x, v1.y + v2.y);
    }

    static sub(v1, v2){
        return new Vec2(v1.x - v2.x, v1.y - v2.y);
    }

    static mul(v1, v2){
        return new Vec2(v1.x * v2.x, v1.y * v2.y);
    }

    static lerp(sv, tv, t){
        var dx = sv.x - tv.x;
        var dy = sv.y - tv.y;

        return new Vec2(sv.x + t * dx, sv.y + t * dy);
    }
}

class Grain{

    constructor(gusts=null, colourSet=null, canvasWidth=0, canvasHeight=0){
        this.position = new Vec2();
        this.oldPosition = new Vec2();
        this.velocity = new Vec2();
        this.radius = 1;
        this.colour = new Vec3();
        this.damping = 0.3;

        this.gusts = gusts;
        this.canvasWidth = canvasWidth;
        this.canvasHeight = canvasHeight;

        this.colourSet = colourSet;

        this.recycle();
    }

    recycle(){
        this.position.set(randomI(0, this.canvasWidth), randomI(-this.canvasHeight, 0));
        this.oldPosition.copy(this.position);

        this.velocity.set(randomF(-0.02, 0.02), randomF(0.4, 1.8));
        this.radius = randomF(0.25, 2.0);

        var sectionWidth = this.canvasWidth / this.colourSet.length;
        var a = ((this.position.x / this.canvasWidth) * sectionWidth)/sectionWidth;
        var setNumber = Math.floor((this.position.x / this.canvasWidth) * this.colourSet.length);

        // var colourSteps = Math.ceil(this.colourSet.length / 3.0) - 1;
        // var setWidth = 1.0 * this.canvasWidth/colourSteps;
        // var setNumber = Math.floor(this.position.x/setWidth);
        //var a = (this.position.x - (setNumber * setWidth))/setWidth;

        // this.colour = this.colourSet[setNumber].createCopy();

        var nextSetNumber = setNumber + 1;
        if(nextSetNumber >= this.colourSet.length){
            nextSetNumber = 0;
        }

        this.colour = Vec3.lerp(this.colourSet[setNumber], this.colourSet[nextSetNumber], a);
        this.colour = this.colourSet[setNumber].createCopy();

        this.colour.x = constrain(this.colour.x + randomI(-10, 10), 0, 255);
        this.colour.y = constrain(this.colour.y + randomI(-10, 10), 0, 255);
        this.colour.z = constrain(this.colour.z + randomI(-10, 10), 0, 255);

        //console.log(this.colour.colourStyle);
    }

    update(et){
        this.oldPosition.copy(this.position);

        this.velocity.mul(this.damping);

        var totalWind = new Vec2(0, randomF(1.5, 2.0));

        if(this.gusts != null){
            for(var i=0; i<this.gusts.length; i++){
                var gust = this.gusts[i];
                var gustForce = gust.getForceAt(this.position);
                totalWind.x += gustForce.x;
                totalWind.y += gustForce.y;
            }
        }

        this.velocity.add(totalWind);

        this.position.add(this.velocity);

        if(this.position.y > this.canvasHeight){
            this.recycle();
        }
    }
    
    render(canvas, ctx){
        ctx.save();

        ctx.beginPath();
        ctx.lineWidth=this.radius;
        ctx.strokeStyle = this.colour.colourStyle;
        ctx.moveTo(this.oldPosition.x, this.oldPosition.y);
        ctx.lineTo(this.position.x, this.position.y);
        ctx.stroke();

        ctx.restore();
    }
}

class Wind{

    constructor(canvasWidth, canvasHeight){
        this.position = new Vec2(randomI(50, canvasWidth-50), randomI(50, canvasHeight-50));

        this.canvasWidth = canvasWidth;
        this.canvasHeight = canvasHeight;
        this.velocity = new Vec2(randomF(-1.0, 1.0), randomF(-1.0, 1.0));
        //this.force = new Vec2(randomF(-3.0, 3.0), randomF(-1.0, 1.0));
        this.radius = randomI(50, 250);
        this.strength = randomF(-10.0, 10.0);
    }

    update(et){
        this.position.add(this.velocity);
        if(this.position.x < 0 || this.position.x >= this.canvasWidth){
            this.velocity.x = -this.velocity.x;
            this.position.x += 2 * this.velocity.x;
        }

        if(this.position.y < 0 || this.position.y >= this.canvasHeight){
            this.velocity.y = -this.velocity.y;
            this.position.y += 2 * this.velocity.y;
        }
    }

    getForceAt(position){
        var forceHere = new Vec2(0,0);

        var distance = Vec2.distance(this.position, position);
        if(distance > this.radius){
            return forceHere;
        }

        //function mapRange(value, low1, high1, low2, high2)
        var force = mapRange(distance, 0, this.radius, this.strength, 0);
        var dPoint = new Vec2(position.x - this.position.x, position.y - this.position.y);
        var forceDirection = new Vec2(dPoint.y, -dPoint.x);
        forceDirection.normalize();
        forceDirection.mul(force);
        forceHere.add(forceDirection);

        return forceHere;
    }
}

class Sandstorm{

    constructor(canvas){
        this.canvas = canvas;
        this.context = this.canvas.getContext("2d");
        this.running = false;
        this.startTimestamp = 0;
        this.lastUpdateTimestamp = 0;

        this.onAnimationFrame = this.onAnimationFrame.bind(this);
        this.onResize = this.onResize.bind(this);
        this.onOrientationChange = this.onOrientationChange.bind(this);

        window.addEventListener("resize", this.onResize);
        window.addEventListener("orientationchange", this.onOrientationChange);

        this.gusts = new Array();
        this.grains = new Array();
        this.colourSet = new Array();

        this.numberOfGusts = 8;
        this.numberOfGrains = 5000;

        this.onResize();
    }

    start(){
        if(this.running){
            return;
        }

        this.startTimestamp = Date.now();

        console.log("starting Sandstorm");

        this.initScene();
        
        this.lastUpdateTimestamp = Date.now();
        this.running = true;

        window.requestAnimationFrame(this.onAnimationFrame);
    }

    stop(){
        this.running = false;
    }

    initScene(){
        console.log("initScene");

        this.clearCanvas();

        this.gusts = new Array();
        this.grains = new Array();

        for(var i=0; i<this.numberOfGusts; i++){
            this.gusts.push(new Wind(this.canvas.width, this.canvas.height));
        }

        for(var i=0; i<this.numberOfGrains; i++){
            this.grains.push(
                new Grain(this.gusts, this.colourSet, this.canvas.width, this.canvas.height)
            );
        }
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
        // update gusts
        this.gusts.forEach(function(element, index, array){
            element.update(et);
        });

        this.grains.forEach(function(element, index, array){
            element.update(et);
        });
    }

    clearCanvas(){
        this.context.fillStyle = "#FFFFFF";
        this.context.fillRect(0, 0, this.canvas.width, this.canvas.height);
    }

    onRender(){
        var canvas = this.canvas; 
        var context = this.context;

        // this.clearCanvas();

        this.grains.forEach(function(element, index, array){
            element.render(canvas, context);
        });

        // this.gusts.forEach(function(element, index, array){
        //     context.beginPath();
        //     context.fillStyle = "blue";
        //     context.arc(element.position.x, element.position.y, element.radius,  0, Math.PI * 2, true);
        //     context.fill();
        //
        // });

        this.drawPalette(canvas, context);
    }

    drawPalette(canvas, context){
        var width = Math.min(canvas.width, canvas.height) * 0.05;
        var padding = width * 0.05;
        var x = canvas.width - ((width + padding) * (this.colourSet.length + 1));
        var y = canvas.height - width - padding;

        for(var i=0; i<this.colourSet.length; i++){
            context.fillStyle = this.colourSet[i].colourStyle;
            context.fillRect(x, y, width, width);
            x += (width + padding);
        }

    }

    onOrientationChange(){
        this.onResize();
    }

    onResize(){
        this.canvas.width = document.width | document.body.clientWidth;
        this.canvas.height = document.height | document.body.clientHeight;

        if(this.running){
            this.initScene(); // reset scene
        }
    }
}

class ServiceAPI{

    constructor(){
        this._rootUrl = "http://instacolour.herokuapp.com";
        this._busy = false;
    }

    get isBusy(){
        return this._busy;
    }

    dominatecolours(clusters, handler){
        this._busy = true;

        var _this = this;

        var xhr = new XMLHttpRequest();
        xhr.onload = function(e) {
            _this._busy = false;
            var jsonObj = JSON.parse(xhr.response)
            if(handler != null){
                handler(_this, jsonObj);
            }
        }
        xhr.onerror = function(e){
            _this._busy = false;
            if(handler != null) {
                handler(_this, null);
            }
        }

        console.log("calling " + this._rootUrl + "/api/dominatecolours?clusters=" + clusters);

        xhr.open("GET", this._rootUrl + "/api/dominatecolours?clusters=" + clusters, true);
        xhr.send();
    }
}

function getQueryStringParameterByName(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, " "));
}