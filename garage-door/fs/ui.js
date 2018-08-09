// Helper methods used client side (in user's browser) when rendering
// dynamic content in simple HTML page

// Changes text value of DOM object.
//
// id - ID of DOM object to update value of.
// val - New value to display.
function updateValue(id, val) {
  var v = document.getElementById(id);
  if (v) {
    while (v.firstChild) {
      v.removeChild(v.firstChild);
    }
    v.appendChild(document.createTextNode(val));
  }
}

// Updates status information on HTML page based on RPC results
// from a Get.Status or Press.Button request.
function statusUpdate() {
  // NOTE: this is from the original XHR request
  let status = JSON.parse(this.responseText);
  updateValue("presses", status["presses"]);
  updateValue("freeRam", status["freeRam"]);
  let hours = parseFloat(status["upTime"]) / 3600.0;
  updateValue("upHours", hours.toFixed(2));

  var pressed = status["pressed"];
  if (pressed !== undefined) {
    var b = document.getElementById("button");
    b.style.color = pressed ? "green" : "red";
    setTimeout(function() {
      b.style.color = "";
    }, 250);
  }
}

// Request status information.
function requestStatus() {
  var xhr = new XMLHttpRequest();
  xhr.open('GET', '/Rpc/Get.Status');
  // Update page info when we get results
  xhr.addEventListener('load', statusUpdate);
  xhr.send();
}        

// Press the garage door button and request status information
function pressButton() {
  var xhr = new XMLHttpRequest();
  xhr.open('GET', '/Rpc/Press.Button');
  // Update page info when we get results
  xhr.addEventListener('load', statusUpdate);
  xhr.send();
}
