/**
 * Created by josh on 11/07/2016.
 */

var canvas = null;
var context = null;

var bgCanvas = null;
var bgContext = null;

var srcImageData = null;
var dstImageData = null;

var fading = false;

document.addEventListener("DOMContentLoaded", init, false);

function init(){
    canvas = document.getElementById("target-image-canvas");
    context = canvas.getContext("2d");

    bgCanvas = document.getElementById("bg-target-image-canvas");
    bgContext = bgCanvas.getContext("2d");

    document.getElementById("url-input").addEventListener("keydown", function(evt){
        if(evt.keyCode == 13){
            analyseImage(document.getElementById("url-input").value, document.getElementById("colours").value);
        }
    });

    document.getElementById("colours").addEventListener("keydown", function(evt){
        if(evt.keyCode == 13){
            analyseImage(document.getElementById("url-input").value, document.getElementById("colours").value);
        }
    });

    analyseImage(document.getElementById("url-input").value, document.getElementById("colours").value);
}

function colouriseImage(swatchIndex) {
    // var serviceURL = "https://instacolour.herokuapp.com/api/colourise";
    //
    // var packet = "image_url=" + url;
    // packet += "&colours=" + colours;
    // packet += "&swatch_index=" + swatchIndex;
    //
    // var xhr = new XMLHttpRequest();
    // xhr.onload = function(e) {
    //
    // }
    //
    // xhr.open("POST", serviceURL, true);
    // xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    // xhr.send(packet);

    var url = document.getElementById("url-input").value;
    var colours = document.getElementById("colours").value;

    var imageUrl = "https://instacolour.herokuapp.com/api/colourise?image_url=" + url;
    imageUrl += "&colours=" + colours;
    imageUrl += "&swatch_index=" + swatchIndex;

    console.log("requesting " + imageUrl);

    loadImage(imageUrl, false);
}

function loadImage(url, fade=false, callbackFunc=null){
    var image = new Image();
    image.onload = function(e) {
        var h = 400;
        var w = (400/image.height * image.width);

        if(fade){
            bgCanvas.height = h;
            bgCanvas.width = w;
            bgContext.drawImage(image, 0, 0, w, h);
            fading = true;
            srcImageData = context.getImageData(0, 0, w, h);
            dstImageData = bgContext.getImageData(0, 0, w, h);

            console.log("fading into image");

            startFading();
        } else{
            canvas.height = h;
            canvas.width = w;
            context.drawImage(image, 0, 0, w, h);
        }

        if(callbackFunc != null){
            callbackFunc();
        }
    }
    image.onerror = function(){
        if(callbackFunc != null){
            callbackFunc();
        }
    }
    image.src = url;
    // image.crossOrigin = "anonymous";
}

function startFading(){

    var maxDiff = 0;

    for(var i=0; i<srcImageData.data.length; i++){
        srcImageData[i] +=  (dstImageData[i] - srcImageData[i]) * 0.3;
        var diff = (dstImageData[i].data - srcImageData[i].data);
        if(diff > maxDiff)
            maxDiff = diff;
    }

    context.putImageData(srcImageData, 0, 0);

    if(maxDiff < 5){
        srcImageData = null;
        dstImageData = null;
        fading = false;
    }

    if(fading) {
        window.requestAnimationFrame(startFading);
    }
}

function analyseImage(url, colours) {
    var colorsElem = document.getElementById("colors");
    while (colorsElem.firstChild) {
        colorsElem.removeChild(colorsElem.firstChild);
    }

    var swatchesElem = document.getElementById("swatches");
    while (swatchesElem.firstChild) {
        swatchesElem.removeChild(swatchesElem.firstChild);
    }

    loadImage(url, false);


    var packet = "image_url=" + url;
    packet += "&colours=" + colours;

    var serviceURL = "https://instacolour.herokuapp.com/api/vibrantcolours";

    var xhr = new XMLHttpRequest();
    xhr.onload = function(e) {
        console.log(xhr.response);
        if(xhr.response != null){
            var jsonObj = JSON.parse(xhr.response)

            if(jsonObj.hasOwnProperty("palette")){
                var palettes = jsonObj["palette"];

                if(palettes.hasOwnProperty("swatches")){
                    var swatches = palettes["swatches"];
                    for(var i=0; i<swatches.length; i++){
                        var swatch = swatches[i];
                        if(swatch.hasOwnProperty("rgb")){
                            var rgb = createRGBValue(swatch["rgb"]);
                            var elem = addColourSwatch(rgb, i);

                            // add click listener
                            elem.dataset["index"] = i;
                            elem.name = i;
                            elem.addEventListener('click', function(e){
                                colouriseImage(e.target.dataset.index);
                            });
                        }
                    }
                }

                if(palettes.hasOwnProperty("vibrant_swatch")){
                    var rgb = createRGBValue(palettes["vibrant_swatch"]);
                    addColourElement("Vibrant", rgb);
                }

                if(palettes.hasOwnProperty("light_vibrant_swatch")){
                    var rgb = createRGBValue(palettes["light_vibrant_swatch"]);
                    addColourElement("Light Vibrant", rgb);
                }

                if(palettes.hasOwnProperty("dark_vibrant_swatch")){
                    var rgb = createRGBValue(palettes["dark_vibrant_swatch"]);
                    addColourElement("Dark Vibrant", rgb);
                }

                if(palettes.hasOwnProperty("muted_swatch")){
                    var rgb = createRGBValue(palettes["muted_swatch"]);
                    addColourElement("Muted", rgb);
                }

                if(palettes.hasOwnProperty("light_muted_swatch")){
                    var rgb = createRGBValue(palettes["light_muted_swatch"]);
                    addColourElement("Light Muted", rgb);
                }

                if(palettes.hasOwnProperty("dark_muted_swatch")){
                    var rgb = createRGBValue(palettes["dark_muted_swatch"]);
                    addColourElement("Dark Muted", rgb);
                }
            }
        }
    }

    xhr.open("POST", serviceURL, true);
    xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    xhr.send(packet);
}

function createRGBValue(swatchColour){
    return "rgb(" + swatchColour[0] + "," + swatchColour[1] + "," + swatchColour[2] + ")";
}

function addColourSwatch(rgb, i){
    var parentDiv = document.createElement("div");
    var div = document.createElement("div");
    div.className = "colorswatch shadow-z-1";
    div.dataset.index = i;
    div.style["background-color"] = rgb;
    parentDiv.appendChild(div);
    document.getElementById("swatches").appendChild(parentDiv);

    return parentDiv;
}

function addColourElement(text, rgb){
    /*
    <div><div class="color shadow-z-1" style="background-color: rgb(191, 216, 84);"></div><span>Vibrant</span></div><div>
     */
    var parentDiv = document.createElement("div");
    var div = document.createElement("div");
    div.className = "color shadow-z-1";
    div.style["background-color"] = rgb;
    parentDiv.appendChild(div);
    var span = document.createElement("span");
    span.innerText = text;
    parentDiv.appendChild(span);
    document.getElementById("colors").appendChild(parentDiv);
}

function getColourFromJSONObject(obj){
    return "rgb(" + obj["colour"][0] + ", " + obj["colour"][1] + ", " + obj["colour"][2] + ")";
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