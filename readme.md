# Present Peekinator
[![Thumbnail for Present Peekinator Video. Man looking into present. An alarm is going off and he's been notified a video has been recorded](https://github.com/MatthewJones517/present_peekinator/blob/main/screenshots/Thumbnail.png?raw=true)](https://youtu.be/KBeqRLDe_jw)


## What is This?

We all know someone who peeks at their Christmas presents early. This year I decided to take matters into my own hands. I created the most over-engineered present protection system ever! [Check it out on YouTube](https://youtu.be/KBeqRLDe_jw).

When someone peeks at their present:

- An alarm sounds
- A five-second video is recorded
- That video is uploaded to Firebase Cloud Storage
- The download URL is saved in Firestore
- A push notification is sent to my phone
- The video evidence can be viewed in my Flutter app. 

The result is irrefutable proof that the present peeker deserves a spot on Santa's naughty list! 

## Project Structure

### /esp32-cam

This is the heart of the project. The [ESP32-CAM board](https://www.amazon.com/dp/B08ZS5YWCG) records the video, saves it to an SD Card, and uploads it to Firebase. The camera it comes with garbage. I reccomend upgrading to the [OV5640](https://www.amazon.com/dp/B0FVRJG44N). 

### /arduino-nano 

If you look at the [pinout](https://lastminuteengineers.com/esp32-cam-pinout-reference/) of the ESP32-CAM board, it's pretty bleak. There's precisely 1 pin that's safe to use. Everything else is in use if you fully utilize the board (WiFi, Camera, SD Card). 

I added an Arduino Nano to do the rest of the stuff I wanted to do (alarm, photo resistor). Frankly this was overkill. A simple comparator circuit would have done the trick but I didn't have the parts. I did, however, have an extra Arduino Nano. 🤷

### /firebase

All the firebase stuff is handled here. Firebase is delightful for rapid prototyping. Once the ESP32 uploads the video to cloud storage it triggers a cloud function to send the push notification and log the download URL in the database. 

### /naughty_list_notifier

This is a pretty simple Flutter app. The home screen has a list of "Peekers". Tap on one of them and you'll see the video evidence. Alternatively you can tap on the push notification and it will take you directly to the video. 

I'm disappointed this didn't get more screen time in the video, so here's some screenshots. 

![List view showing various present peekers](https://github.com/MatthewJones517/present_peekinator/blob/main/screenshots/list-view.png?raw=true)

![Video of present peeker opening the package](https://github.com/MatthewJones517/present_peekinator/blob/main/screenshots/video-view.png?raw=true)

### Thanks for Watching!

Please [like and subscribe](https://www.youtube.com/@makerinator) to my YouTube channel! You can also stay up to date by [joining the Inator Club](http://club.makerinator.com/). It's free!