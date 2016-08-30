/**
 * Created by josh on 27/07/2016.
 */

document.addEventListener("DOMContentLoaded", init, false);

var renderer = null;
var serviceAPI = null;

function init(){
    serviceAPI = new ServiceAPI();
    renderer = new BallRenderer(document.getElementById("canvas"));

    console.log("fetching dominate colours");

    var clusters = getQueryStringParameterByName("clusters");
    if(clusters == null || clusters.length == 0){
        clusters = "-1";
    }

    serviceAPI.dominatecolours(clusters, function(api, result){
        console.log(result);
        console.log("fetched dominate colours");

        // set colour set
        if(result != null){
            var colourClusters = result["colour_clusters"];
            for(var i=0; i<colourClusters.length; i++){
                var r = colourClusters[i]["colour"][0];
                var g = colourClusters[i]["colour"][1];
                var b = colourClusters[i]["colour"][2];
                var colour = new Colour(r, g, b, 0.6);
                renderer.clusters.push(colour);
                renderer.clustersPercentages.push(colourClusters[i]["percentage"]/100.0)
            }
        }

        renderer.start();
    });
}

class Ball{

    constructor(position, velocity, colour, radius){
        this.position = position;
        this.velocity = velocity;
        this.colour = colour;
        this.radius = radius;

        console.log("creating ball " + this.radius);

        //generate the random function that will be used to vary the radius, 9 iterations of subdivision
		this.pointList = this.setLinePoints(9);
        this.phase = Math.random() * Math.PI * 2;

        this.maxRad = this.radius + randomF(-5, 5);
		this.minRad = 0.88 * this.maxRad;
    }

    setLinePoints(iterations) {
		var pointList = {};
		pointList.first = {x:0, y:1};
		var lastPoint = {x:1, y:1}
		var minY = 1;
		var maxY = 1;
		var point;
		var nextPoint;
		var dx, newX, newY;

		pointList.first.next = lastPoint;
		for (var i = 0; i < iterations; i++) {
			point = pointList.first;
			while (point.next != null) {
				nextPoint = point.next;

				dx = nextPoint.x - point.x;
				newX = 0.5*(point.x + nextPoint.x);
				newY = 0.5*(point.y + nextPoint.y);
				newY += dx*(Math.random()*2 - 1);

				var newPoint = {x:newX, y:newY};

				//min, max
				if (newY < minY) {
					minY = newY;
				}
				else if (newY > maxY) {
					maxY = newY;
				}

				//put between points
				newPoint.next = nextPoint;
				point.next = newPoint;

				point = nextPoint;
			}
		}

		//normalize to values between 0 and 1
		if (maxY != minY) {
			var normalizeRate = 1/(maxY - minY);
			point = pointList.first;
			while (point != null) {
				point.y = normalizeRate*(point.y - minY);
				point = point.next;
			}
		}
		//unlikely that max = min, but could happen if using zero iterations. In this case, set all points equal to 1.
		else {
			point = pointList.first;
			while (point != null) {
				point.y = 1;
				point = point.next;
			}
		}

		return pointList;
	}

    update(et){
        this.position.x += this.velocity.x;
        this.position.y += this.velocity.y;
    }

    render(canvas, context){
        var point;
		var rad, theta;
		var twoPi = 2*Math.PI;
		var x0,y0;

		context.strokeStyle = this.colour.colourStyle;
		context.lineWidth = 1.01;
		context.fillStyle = this.colour.colourStyle;
		context.beginPath();
		point = this.pointList.first;
		theta = this.phase;
		rad = this.minRad + point.y*(this.maxRad - this.minRad);
		x0 = this.position.x + rad*Math.cos(theta);
		y0 = this.position.y + rad*Math.sin(theta);
		context.lineTo(x0, y0);
		while (point.next != null) {
			point = point.next;
			theta = twoPi*point.x + this.phase;
			rad = this.minRad + point.y*(this.maxRad - this.minRad);
			x0 = this.position.x + rad*Math.cos(theta);
			y0 = this.position.y + rad*Math.sin(theta);
			context.lineTo(x0, y0);
		}
		context.stroke();
		context.fill();
    }

    collidesWith(other){
        var dis = Vec2.distance(this.position, other.position);
        return dis < (this.maxRad + other.maxRad);
    }

}

class BallRenderer{

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

        this.clusters = [];
        this.clustersPercentages = [];

        this.balls = [];

        this.onResize();
    }

    start(){
        if(this.running){
            return;
        }

        this.startTimestamp = Date.now();

        console.log("starting");

        this.initScene();

        this.lastUpdateTimestamp = Date.now();
        this.running = true;

        window.requestAnimationFrame(this.onAnimationFrame);
    }

    stop(){
        this.running = false;
    }

    initScene(){
        var paddingX = 20;
        var paddingY = 20;

        var maxRadius = 200.0;
        var minRadius = 50.0;

        this.balls = [];
        
        var ballCount = this.clusters.length;

        for(var i=0; i<ballCount; i++){
            var colour = this.clusters[i].createCopy();

            var radius = minRadius + (maxRadius - minRadius) * this.clustersPercentages[i];

            var position = new Vec2(
                randomI(paddingX, this.canvas.width-paddingX), randomI(paddingY, this.canvas.height-paddingY));

            // make sure if doesn't collide with any other balls previously created
            var collisionDetected = true;
            while(collisionDetected){
                collisionDetected = false;

                for(var j=0; j<i; j++){
                    var ball = this.balls[j];
                    var dis = Vec2.distance(position, ball.position);
                    collisionDetected = dis < (radius + ball.maxRad);
                    if(collisionDetected){
                        position.set(randomI(paddingX, this.canvas.width-paddingX), randomI(paddingY, this.canvas.height-paddingY));
                        break;
                    }
                }
            }

            var maxVelocity = 0.2;

            var velocity = new Vec2(randomF(-maxVelocity, maxVelocity), randomF(-maxVelocity, maxVelocity));
            this.balls.push(new Ball(position, velocity, colour, radius));
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
        var canvas = this.canvas;

        this.balls.forEach(function(ball, index, array){
            ball.update(et);

            // collides with boundary?
            if(ball.position.x - ball.maxRad < 0){
                ball.velocity.x = -ball.velocity.x;
                ball.position.x = ball.maxRad;
            } else if(ball.position.x + ball.maxRad > canvas.width){
                ball.velocity.x = -ball.velocity.x;
                ball.position.x = canvas.width - ball.maxRad;
            }

            if(ball.position.y - ball.maxRad < 0){
                ball.velocity.y = -ball.velocity.y;
                ball.position.y = ball.maxRad;
            } else if(ball.position.y + ball.maxRad > canvas.height){
                ball.velocity.y = -ball.velocity.y;
                ball.position.y = canvas.height - ball.maxRad;
            }

        });

        // collision detection and response
        for(var i=0; i<this.balls.length; i++){
            var ball = this.balls[i];
            for(var j=i+1; j<this.balls.length; j++){
                var otherBall = this.balls[j];
                if(ball.collidesWith(otherBall)){
                    // direction
                    var direction = Vec2.sub(ball.position, otherBall.position).normalize();
                    var overlap = (ball.maxRad + otherBall.maxRad) - Vec2.distance(ball.position, otherBall.position);

                    // console.log(" " + direction.x + "," + direction.y + ", " + overlap);

                    // if direction.x < 0 (otherBall is to the right of ball)
                    // if direction.y < 0 (otherBall is below ball)

                    ball.position.x -= direction.x * (overlap/2.0);
                    otherBall.position.x += direction.x * (overlap/2.0);

                    ball.position.y += direction.y * (overlap/2.0);
                    otherBall.position.y -= direction.y * (overlap/2.0);

                    ball.velocity.x = Math.sign(direction.x) * Math.abs(ball.velocity.x);
                    otherBall.velocity.x = Math.sign(-direction.x) * Math.abs(otherBall.velocity.x);

                    ball.velocity.y = Math.sign(direction.y) * Math.abs(ball.velocity.y);
                    otherBall.velocity.y = Math.sign(-direction.y) * Math.abs(otherBall.velocity.y);
                }
            }
        }
    }

    clearCanvas(){
        this.context.fillStyle = "#FFFFFF";
        this.context.fillRect(0, 0, this.canvas.width, this.canvas.height);
    }

    onRender(){
        var canvas = this.canvas;
        var context = this.context;

        this.clearCanvas();

        this.balls.forEach(function(ball, index, array){
            ball.render(canvas, context);
        });

        this.drawPalette(canvas, context);
    }

    drawPalette(canvas, context){
        var width = Math.min(canvas.width, canvas.height) * 0.05;
        var padding = width * 0.05;
        var x = canvas.width - ((width + padding) * (this.clusters.length + 1));
        var y = canvas.height - width - padding;

        for(var i=0; i<this.clusters.length; i++){
            context.fillStyle = this.clusters[i].colourStyle;
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
            this.initScene();
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

        console.log("Calling " + this._rootUrl + "/api/dominatecolours?clusters=" + clusters);

        xhr.open("GET", this._rootUrl + "/api/dominatecolours?clusters=" + clusters, true);
        xhr.send();
    }
}

class Colour{

    constructor(r=0, g=0, b=0, a=0.4){
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;

    }

    set(r, g, b, a=0.4){
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }

    copy(other){
        this.r = other.r;
        this.g = other.g;
        this.b = other.b;
        this.a = other.a;
    }

    createCopy(){
        return new Colour(this.r, this.g, this.b, this.a);
    }

    get colourStyle(){
        return "rgba(" + Math.floor(this.r) + ", " + Math.floor(this.g) + ", " + Math.floor(this.b) + "," + this.a + ")";
    }

    static lerp(source, target, t){
        var dr = source.r - target.r;
        var dg = source.g - target.g;
        var db = source.b - target.b;
        var da = source.a - target.a;

        return new Colour(
            source.r + t * dr,
            source.g + t * dg,
            source.b + t * db,
            source.a + t * da
        );
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

        return this;
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

function getQueryStringParameterByName(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, " "));
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