# MacPatro Native

A simple and lightweight macOS menu bar application to display the Nepali date.

## Building the Application

To build the application from source, follow these steps:

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd mac-patro-native
    ```

2.  **Build the executable:**
    ```bash
    swift build -c release
    ```

3.  **Create the application icon:**
    This step converts the PNG icon into the required `.icns` format.
    ```bash
    # Create a temporary directory for the icon set
    mkdir -p icon.iconset

    # Generate the different icon sizes
    sips -z 16 16 MacPatroNative/Resources/icon.png --out icon.iconset/icon_16x16.png
    sips -z 32 32 MacPatroNative/Resources/icon.png --out icon.iconset/icon_16x16@2x.png
    sips -z 32 32 MacPatroNative/Resources/icon.png --out icon.iconset/icon_32x32.png
    sips -z 64 64 MacPatroNative/Resources/icon.png --out icon.iconset/icon_32x32@2x.png
    sips -z 128 128 MacPatroNative/Resources/icon.png --out icon.iconset/icon_128x128.png
    sips -z 256 256 MacPatroNative/Resources/icon.png --out icon.iconset/icon_128x128@2x.png
    sips -z 256 256 MacPatroNative/Resources/icon.png --out icon.iconset/icon_256x256.png
    sips -z 512 512 MacPatroNative/Resources/icon.png --out icon.iconset/icon_256x256@2x.png
    sips -z 512 512 MacPatroNative/Resources/icon.png --out icon.iconset/icon_512x512.png
    sips -z 1024 1024 MacPatroNative/Resources/icon.png --out icon.iconset/icon_512x512@2x.png

    # Create the .icns file
    iconutil -c icns icon.iconset -o MacPatroNative/Resources/icon.icns

    # Clean up the temporary directory
    rm -rf icon.iconset
    ```

4.  **Create the `.app` bundle structure:**
    ```bash
    mkdir -p dist/MacPatroNative.app/Contents/MacOS
    mkdir -p dist/MacPatroNative.app/Contents/Resources
    ```

5.  **Copy the executable:**
    ```bash
    cp .build/release/MacPatroNativeApp dist/MacPatroNative.app/Contents/MacOS/
    ```

6.  **Copy the icon:**
    ```bash
    cp MacPatroNative/Resources/icon.icns dist/MacPatroNative.app/Contents/Resources/
    ```

7.  **Create the `Info.plist`:**
    ```bash
    cat << EOF > dist/MacPatroNative.app/Contents/Info.plist
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>CFBundleExecutable</key>
        <string>MacPatroNativeApp</string>
        <key>CFBundleIconFile</key>
        <string>icon.icns</string>
        <key>CFBundleIdentifier</key>
        <string>com.example.MacPatroNative</string>
        <key>CFBundleName</key>
        <string>MacPatroNative</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>CFBundleShortVersionString</key>
        <string>1.0</string>
        <key>CFBundleVersion</key>
        <string>1</string>
        <key>LSMinimumSystemVersion</key>
        <string>13.0</string>
    </dict>
    </plist>
    EOF
    ```

## License

This project is intended to be open-sourced. A license will be added in the future.