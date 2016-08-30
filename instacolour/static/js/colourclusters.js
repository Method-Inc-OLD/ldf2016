/**
 * Created by josh on 11/07/2016.
 */
document.addEventListener("DOMContentLoaded", init, false);

var swatchCanvas;
var swatchCanvasCtx;

function init(){
    document.getElementById("url-input").addEventListener("keydown", function(evt){
        if(evt.keyCode == 13){
            extractDominateColour(document.getElementById("url-input").value);
        }
    });

    swatchCanvas = document.getElementById("swatch_canvas");
    swatchCanvasCtx = swatchCanvas.getContext("2d");
}

function extractDominateColour(url) {
    var swatches = document.getElementById("swatches");
    // while (swatches.firstChild) {
    //     swatches.removeChild(swatches.firstChild);
    // }
    swatchCanvasCtx.clearRect(0, 0, swatchCanvasCtx.width, swatchCanvasCtx.height);

    document.getElementById("dominant-swatch").style.background = "rgb(255, 255, 255)";

    document.getElementById("target-image").src = url;

    var clusters = getQueryStringParameterByName("clusters");
    if(clusters == null || clusters.length == 0){
        clusters = "6";
    }

    var mode = getQueryStringParameterByName("mode");
    if(mode == null || mode.length == 0){
        mode = "kmeans";
    }

    var colourSpace = getQueryStringParameterByName("colourspace");
    if(colourSpace == null || colourSpace.length == 0){
        colourSpace = "rgb";
    }

    var packet = "image_url=" + url;
    packet += "&clusters=" + clusters;
    packet += "&colourspace=" + colourSpace.toLowerCase();
    packet += "&mode=" + mode.toLowerCase();

    var serviceURL = "https://instacolour.herokuapp.com/api/colourclusters";

    var xhr = new XMLHttpRequest();
    xhr.onload = function(e) {
        console.log(xhr.response);
        if(xhr.response != null){
            var jsonObj = JSON.parse(xhr.response)
            if(jsonObj.hasOwnProperty("colour_clusters")){
                var colourClusters = jsonObj["colour_clusters"];

                if(colourClusters != null && colourClusters.length > 0){
                    colourClusters.sort(function(a,b){
                        if(a["percentage"] > b["percentage"]){
                            return -1;
                            
                        }
                        else if(a["percentage"] < b["percentage"]){
                            return 1;
                        }
                        return 0;
                    });

                    document.getElementById("dominant-swatch").style.background = getColourFromJSONObject(colourClusters[0]);

                    for(var i=0; i<colourClusters.length; i++) {
                        var colourCluster = colourClusters[i];
                        if(colourCluster.hasOwnProperty("swatch")){
                            if(colourCluster["swatch"] == "vibrant_swatch"){
                                document.getElementById("dominant-swatch").style.background = getColourFromJSONObject(colourCluster);
                                break;
                            }
                        }

                    }


                    // var swatchContainer = document.getElementById("swatches");
                    // for(var i=0; i<colourClusters.length; i++){
                    //     var div = document.createElement("div");
                    //     div.className = "swatch";
                    //     div.style.background = getColourFromJSONObject(colourClusters[i]);
                    //     swatchContainer.appendChild(div);
                    // }

                    var ox = 0;

                    var totalPercentage = 0.0;
                    for(var i=0; i<colourClusters.length; i++){
                        var colourCluster = colourClusters[i];
                        totalPercentage += colourCluster["percentage"];
                    }

                    for(var i=0; i<colourClusters.length; i++){
                        var colourCluster = colourClusters[i];
                        var percentage = colourCluster["percentage"] / totalPercentage;
                        var width = parseInt(swatchCanvas.width * percentage);
                        swatchCanvasCtx.fillStyle = getColourFromJSONObject(colourCluster);
                        swatchCanvasCtx.fillRect(ox, 0, width, swatchCanvas.height);
                        ox += width;
                    }
                }
            }
        }
    }

    xhr.open("POST", serviceURL, true);
    xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    xhr.send(packet);
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