// Photoresistor connected to analog pin A0
// Active buzzer connected to digital pin 2
// Trigger pin connected to digital pin 8

const int PHOTORESISTOR_PIN = A0;
const int BUZZER_PIN = 2;
const int TRIGGER_PIN = 8;
const int THRESHOLD = 125;

bool hasTriggered = false; // Flag to prevent retriggering while above threshold

void setup() {
  // Initialize serial communication for debugging (optional)
  Serial.begin(115200);
  
  // Set buzzer pin as output
  pinMode(BUZZER_PIN, OUTPUT);
  
  // Set trigger pin as output
  pinMode(TRIGGER_PIN, OUTPUT);
  
  // Ensure buzzer and trigger pin start off
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(TRIGGER_PIN, LOW);
}

void loop() {
  // Read the photoresistor value
  int photoValue = analogRead(PHOTORESISTOR_PIN);

  Serial.println(photoValue);
  
  // Check if value is above threshold
  if (photoValue > THRESHOLD) {
    // Trigger pin 8 once when crossing above threshold
    if (!hasTriggered) {
      digitalWrite(TRIGGER_PIN, HIGH);
      Serial.println(">>> TRIGGERING: Setting TRIGGER_PIN HIGH <<<");
      delay(2000); // Keep pin high for 2 seconds
      digitalWrite(TRIGGER_PIN, LOW);
      Serial.println(">>> TRIGGERING: Setting TRIGGER_PIN LOW <<<");
      hasTriggered = true; // Prevent retriggering while above threshold
    }
    
    // Enter beeping loop until value drops below threshold
    while (analogRead(PHOTORESISTOR_PIN) > THRESHOLD) {
      // Turn buzzer on for half a second
      digitalWrite(BUZZER_PIN, HIGH);
      delay(500);
      
      // Turn buzzer off for half a second
      digitalWrite(BUZZER_PIN, LOW);
      delay(500);
    }
    // Ensure buzzer is off when exiting the loop
    digitalWrite(BUZZER_PIN, LOW);
  } else {
    // Reset trigger flag when value drops below threshold
    hasTriggered = false;
  }
  
  // Small delay to prevent excessive reading
  delay(10);
}
