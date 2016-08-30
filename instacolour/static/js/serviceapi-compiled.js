/**
 * Created by josh on 25/07/2016.
 */

class ServiceAPI {

    constructor() {
        this._rootUrl = "http://instacolour.herokuapp.com";
        this._busy = false;
    }

    get isBusy() {
        return this._busy;
    }

    dominatecolours(handler) {
        this._busy = true;

        var _this = this;

        var xhr = new XMLHttpRequest();
        xhr.onload = function (e) {
            _this._busy = false;
            var jsonObj = JSON.parse(xhr.response);
            if (handler != null) {
                handler(_this, jsonObj);
            }
        };
        xhr.onerror = function (e) {
            _this._busy = false;
            if (handler != null) {
                handler(_this, null);
            }
        };

        xhr.open("GET", this._rootUrl + "/api/dominatecolours", true);
        xhr.send();
    }
}

//# sourceMappingURL=serviceapi-compiled.js.map