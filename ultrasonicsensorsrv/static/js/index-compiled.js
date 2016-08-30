"use strict";

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

/**
 * Created by josh on 16/08/2016.
 */

document.addEventListener("DOMContentLoaded", init, false);

var renderer;
var usService;

function log(message) {
    document.getElementById("output").innerHTML = message + "<br/>" + document.getElementById("output").innerHTML;
}

function mapRange(value, istart, istop, ostart, ostop) {
    return ostart + (ostop - ostart) * ((value - istart) / (istop - istart));
}

function init() {
    renderer = new Renderer(document.getElementById("canvas"));
    usService = new UltrasonicService(renderer);
    renderer.onResize();
    renderer.start();
}

var UltrasonicService = function () {
    function UltrasonicService(listener) {
        _classCallCheck(this, UltrasonicService);

        this.listener = listener;

        this.socket = io.connect('http://' + document.domain + ':' + location.port + "/sense");
        this.socket.on('connect', function () {
            log("connected");
            listener.onConnected();
        });

        this.socket.on('disconnect', function () {
            log("disconnected");
            listener.onDisconnected();
        });

        this.socket.on('message', function (message) {
            log("message " + message.data);
            listener.onMessageReceived(message.data);
        });
        this.socket.on('reading', function (message) {
            listener.onReadingReceived(message.data);
        });
    }

    _createClass(UltrasonicService, [{
        key: "poll",
        value: function poll() {
            this.socket.emit("reading", {});
        }
    }]);

    return UltrasonicService;
}();

var Renderer = function () {
    function Renderer(canvas) {
        _classCallCheck(this, Renderer);

        this.canvas = canvas;
        this.context = canvas.getContext("2d");

        this.context.mozImageSmoothingEnabled = false;
        this.context.imageSmoothingEnabled = false;
        this.context.imageSmoothingEnabled = false;

        this.running = false;
        this.lastUpdateTimestamp = 0;

        this.dirty = true;

        this.maxDistance = 200.0;
        this.minDistance = 5.0;
        this.timeSincePolledDistance = 0;
        this.targetDistance = this.maxDistance;
        this.distance = this.maxDistance;

        this.imageLoaded = false;
        this.image = new Image();
        this.image.src = "http://" + document.domain + ':' + location.port + "/img/ldf_test.jpg";
        var _this = this;
        this.image.onload = function () {
            log("image loaded");
            _this.imageLoaded = true;
            _this.dirty = true;
        };
        this.image.onerror = function () {
            log("Error occured while trying to load " + _this.src);
        };

        this.onAnimationFrame = this.onAnimationFrame.bind(this);
        this.onResize = this.onResize.bind(this);
        this.onOrientationChange = this.onOrientationChange.bind(this);

        this.onConnected = this.onConnected.bind(this);
        this.onDisconnected = this.onDisconnected.bind(this);
        this.onMessageReceived = this.onMessageReceived.bind(this);
        this.onReadingReceived = this.onReadingReceived.bind(this);

        window.addEventListener("resize", this.onResize);
        window.addEventListener("orientationchange", this.onOrientationChange);
    }

    _createClass(Renderer, [{
        key: "start",
        value: function start() {
            this.lastUpdateTimestamp = Date.now();
            this.running = true;

            window.requestAnimationFrame(this.onAnimationFrame);
        }
    }, {
        key: "stop",
        value: function stop() {
            this.running = false;
        }
    }, {
        key: "onAnimationFrame",
        value: function onAnimationFrame() {
            if (!this.running) {
                return;
            }

            var elapsedTime = Date.now() - this.lastUpdateTimestamp;
            this.lastUpdateTimestamp = Date.now();

            elapsedTime /= 1000; // elapsedTime in ms

            this.onUpdate(elapsedTime);

            if (this.dirty) {
                this.onRender();
                this.dirty = false;
            }

            window.requestAnimationFrame(this.onAnimationFrame);
        }
    }, {
        key: "onUpdate",
        value: function onUpdate(et) {
            var elapsedTimeSincePolledSensor = Date.now() - this.timeSincePolledDistance; // milliseconds

            if (elapsedTimeSincePolledSensor > 2.0 * 1000) {
                this.timeSincePolledDistance = Date.now();
                usService.poll();
            }

            this.distance += (this.targetDistance - this.distance) * 0.5;

            if (!this.dirty) {
                this.dirty = Math.abs(this.distance - this.targetDistance) > 5.0;
            }
        }
    }, {
        key: "onRender",
        value: function onRender() {
            this.context.fillStyle = "white";
            this.context.fillRect(0, 0, this.canvas.width, this.canvas.height);

            if (!this.imageLoaded) {
                return;
            }

            var distance = Math.min(Math.max(this.distance, this.minDistance), this.maxDistance);

            var size = mapRange(distance, this.minDistance, this.maxDistance, 1, 50) * 0.01;
            //log("distance " + this.distance + ", target distance " + this.targetDistance);
            var w = this.width * size;
            var h = this.height * size;

            // draw original image to the scaled size
            this.context.drawImage(this.image, 0, 0, w, h);
            // then draw that scaled image thumb back to fill canvas
            // As smoothing is off the result will be pixelated
            this.context.drawImage(this.canvas, 0, 0, w, h, 0, 0, this.width, this.height);
        }
    }, {
        key: "onResize",
        value: function onResize() {
            this.dirty = true;

            var containers = document.getElementsByClassName("canvas_container");
            if (containers == null || containers.length == 0) {
                return;
            }

            var container = containers[0];
            this.width = parseInt(window.getComputedStyle(container).getPropertyValue("width"));
            this.height = parseInt(window.getComputedStyle(container).getPropertyValue("height"));
        }
    }, {
        key: "onOrientationChange",
        value: function onOrientationChange() {
            this.onResize();
        }
    }, {
        key: "onConnected",
        value: function onConnected() {}
    }, {
        key: "onDisconnected",
        value: function onDisconnected() {}
    }, {
        key: "onMessageReceived",
        value: function onMessageReceived(messageData) {}
    }, {
        key: "onReadingReceived",
        value: function onReadingReceived(reading) {
            if (Math.abs(reading - this.targetDistance) > 1.0) {
                this.dirty = true;
                this.targetDistance = reading;
                log("current distance = " + reading + " (updating)");
            } else {
                //log("current distance = " + reading);
            }
        }
    }, {
        key: "width",
        get: function get() {
            return this.canvas.width;
        },
        set: function set(width) {
            this.canvas.width = width;
        }
    }, {
        key: "height",
        get: function get() {
            return this.canvas.height;
        },
        set: function set(height) {
            this.canvas.height = height;
        }
    }]);

    return Renderer;
}();

//# sourceMappingURL=index-compiled.js.map