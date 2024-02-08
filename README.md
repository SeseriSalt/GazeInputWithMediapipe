# Eye Glance Input Interface

## Sample

![Sample](https://github.com/SeseriSalt/GazeInputWithMediapipe/assets/103529116/161a3427-6455-4876-a152-a72a6d5d8147)


## Operation

### basic operation

- Move the blue cursor on the tip of your nose.
- After moving the cursor, look at wink or the four corners of the screen for a moment.

### calibration, Setting

- Automatic calibration
  - Press the "Calibration" button.
  - Press the button again, gaze at a point for 5 seconds, and press the button again.
  - Press the button again and input Eye Glance in the direction of the arrow displayed on the screen.
  - The data obtained from the automatic calibration is reflected in the manual settings "Eye Glance Waveform Threshould" and "Eye Glance Integral Value Maginification".
- Manual Setting
  - The thresholds that affect the input can be set manually.

## Usage

### Install Bazel

Install bazel to create a framework.

```
export BAZEL_VERSION=5.2.0
curl -fLO "https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-darwin-x86_64.sh"
```

### Download Files

https://github.com/SeseriSalt/mediapipe/blob/simple_iris_framework/mediapipe/develop/iris/SYIris.h

https://github.com/SeseriSalt/mediapipe/blob/simple_iris_framework/mediapipe/develop/iris/SYIris.mm

https://github.com/SeseriSalt/mediapipe/blob/simple_iris_framework/mediapipe/develop/iris/info.plist

### Build the framework

```
$ bazel build --config=ios_fat --define 3D=true mediapipe/develop:HandTracker
```

If the build is successful, a zip file will be generated in `bazel-bin/mediapipe/develop/`, unzip it and you will find a .framework file.

If you replace the newly created framework with the currently configured one, the app should build successfully.

We are currently looking into making the framework available for implementation in Carthago. If you want to build it easily, please wait for a while.



reference：https://qiita.com/noppefoxwolf/items/99cb1da63c093f668d71
