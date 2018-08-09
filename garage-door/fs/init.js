load('api_config.js');
load('api_gpio.js');
load('api_rpc.js');
load('api_sys.js');
load('api_timer.js');

// GPIO pin to control relay with
let relay = Cfg.get('app.relayPin');

// Value for GPIO pin to hold relay open (unpressed)
let up = Cfg.get('app.relayUpState') ? 1 : 0;

// Value for GPIO pin to close relay (press)
let down = up ? 0 : 1;

// How many milliseconds to hold relay in pressed state
let hold = Cfg.get('app.relayDownMsecs');

// Count of button presses and time of last button press
let pCnt = 0;
let pTime = 0;

// Initialize GPIO for controlling relay
GPIO.set_mode(relay, GPIO.MODE_OUTPUT);
GPIO.write(relay, up);

// Function that emulates human pressing a garage door button
// by driving a relay using one of the GPIO pins
function pressButton() {
  let now = Sys.uptime();
  if ((now - pTime) <= (hold * 0.002)) {
    // Not enough time has elapsed since the last press, ignore
    // request
    return false;
  }
  pTime = now;
  pCnt = pCnt + 1;
  //print("Pressing garage door button", pCnt, Sys.uptime());
  // Close relay - "press down on button"
  GPIO.write(relay, down);
  Timer.set(hold, 0, function() {
    // Open relay - "release button"
    GPIO.write(relay, up);
  }, null);
  return true;
}

// Builds object of status information.
function getStatus() {
  return {
    presses: pCnt,
    upTime: Sys.uptime(),
    freeRam: Sys.free_ram(),
    totalRam: Sys.total_ram()
  };
}

// RPC method to return status
RPC.addHandler('Get.Status', function(args) {
  return getStatus();
});

// RPC method to press button
RPC.addHandler('Press.Button', function(args) {
  let pressed = pressButton();
  let s = getStatus();
  s["pressed"] = pressed;
  return s;
});
