load('api_config.js');
load('api_gpio.js');
load('api_rpc.js');
load('api_sys.js');
load('api_timer.js');

// For temperature/humidty DHT-22 sensor readings
load('api_dht.js');

// For posting updates
load('api_mqtt.js');

// GPIO pin to control relay with
let relay = Cfg.get('app.relayPin');

// GPIO pin to control relay with
let dhtPin = Cfg.get('app.dhtPin');
let msecsBetweenReadings = Cfg.get('app.msecsBetweenReadings');
let tmpTolerance = Cfg.get('app.temperatureTolerance');
let humTolerance = Cfg.get('app.humidityTolerance');

// Value for GPIO pin to hold relay open (unpressed)
let up = Cfg.get('app.relayUpState') ? 1 : 0;

// Value for GPIO pin to close relay (press)
let down = up ? 0 : 1;

// How many milliseconds to hold relay in pressed state
let hold = Cfg.get('app.relayDownMsecs');

// Count of button presses and time of last button press
let pCnt = 0;
let pTime = 0;

// Temperature and humidity readings
let dht = undefined;
let lastTemp = 0;
let lastHumidity = 0;
let curTemp = 0;
let curHumidity = 0;
let curAvailable = false;
let badReadings = 0;

// If dhtPin pin is set, then enable periodic reading of temp/humidty
if (dhtPin !== -1) {
  // Initialize DHT library
  dht = DHT.create(dhtPin, DHT.DHT22);

  if (dht === undefined) {
    dhtPin = -1;
    print('Failed to connect to sensor on pin ' + dhtPin);
  } else {
    // This function reads data from the DHT sensor every 2 second
    Timer.set(msecsBetweenReadings, Timer.REPEAT, function() {
      let t = dht.getTemp();
      let h = dht.getHumidity();

      if (isNaN(h) || isNaN(t)) {
	print('Failed to read data from sensor');
	badReadings++;
	if (badReadings > 10) {
	  lastTemp = lastHumidity = -1;
	}
	return;
      }
      badReadings = 0;

      if ((Math.abs(t - lastTemp) <= tmpTolerance) && (Math.abs(h - lastHumidity) <= humTolerance)) {
	// At this point we have confirmed readings, show them
	curTemp = t;
	curHumidity = h;
	curAvailable = true;
      } else {
	curAvailable = false;
      }

      // Save values last read
      lastTemp = t;
      lastHumidity = h;
	
    }, null);
  }
}

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
  let dhtPresent = (dht !== undefined);
  
  let status = {
    presses: pCnt,
    upTime: Sys.uptime(),
    freeRam: Sys.free_ram(),
    totalRam: Sys.total_ram(),
    hasSensor: dhtPresent
  };
  if (dhtPresent) {
    status["tempC"] = lastTemp;
    status["tempF"] = lastTemp * (9.0/5.0) + 32;
    status["humidity"] = lastHumidity;
  }
  return status;
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

// If MQTT posting is enabled, then set up time to post status
// periodically
if (Cfg.get('mqtt.enable')) {
    // This function reads data from the DHT sensor every 2 second
  Timer.set(Cfg.get('mqtt.msecsBetweenPosts'), Timer.REPEAT, function() {
    let s = getStatus();
    let topic = Cfg.get("mqtt.topic");
    let res = MQTT.pub(topic, JSON.stringify(s), 1);
    if (!res) {
      print("Failed to publish MQTT topic " + topic);
    }
  }, null);
}
