docker run --rm -v "$PWD":/src:ro swift:6.0 sh -c \
  "cp -r /src/AirCore /tmp/AirCore && cd /tmp/AirCore && rm -rf .build && swift test"