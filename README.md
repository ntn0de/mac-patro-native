# MacPatro Native

A simple and lightweight macOS menu bar application to display the Nepali date.

## Configuration

Before building the application, you must provide a remote URL for fetching calendar data.

1.  Create a new file named `RemoteURL.swift` inside the `MacPatroNative/Sources/` directory.

2.  Add the following code to the `RemoteURL.swift` file:

    ```swift
    import Foundation

    struct RemoteURL {
        static let urlString = "https://your-remote-url.com/path-to-data/"
    }
    ```

3.  Replace `"https://your-remote-url.com/path-to-data/"` with your own URL. The server should host JSON files for each year (e.g., `2081.json`, `2082.json`).

    For example:
    ```swift
    static let urlString = "https://ntn0de.github.io/year/"
    ```

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
    mkdir -p dist/Mac\ Patro.app/Contents/MacOS
    mkdir -p dist/Mac\ Patro.app/Contents/Resources
    ```

5.  **Copy the executable:**
    ```bash
    cp .build/release/MacPatroNativeApp dist/Mac\ Patro.app/Contents/MacOS/
    ```

6.  **Copy the icon:**
    ```bash
    cp MacPatroNative/Resources/icon.icns dist/Mac\ Patro.app/Contents/Resources/
    ```

7.  **Create the `Info.plist`:**
    ```bash
    cat << EOF > dist/Mac\ Patro.app/Contents/Info.plist
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>CFBundleExecutable</key>
        <string>MacPatroNativeApp</string>
        <key>CFBundleIconFile</key>
        <string>icon.icns</string>
        <key>CFBundleIdentifier</key>
        <string>com.example.MacPatro</string>
        <key>CFBundleName</key>
        <string>Mac Patro</string>
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

## Automated Release Workflow

This repository includes a GitHub Actions workflow to automate the release process. When you push a new tag (e.g., `v1.0.1`), the workflow will build the application, package it, and create a new release on GitHub with the `.app` bundle attached.

### Setting Up the Remote URL for Releases

The automated workflow requires a secret to be set in your repository to securely access the remote URL for the calendar data.

1.  **Navigate to your repository** on GitHub.
2.  Click on the **Settings** tab.
3.  In the left sidebar, expand **Secrets and variables**, then click on **Actions**.
4.  Click **New repository secret**.
5.  For the **Name**, enter `REMOTE_URL`.
6.  For the **Secret**, paste your full data source URL (e.g., `https://your-data-source.com/year/`).
7.  Click **Add secret**.

## License

This project is intended to be open-sourced. A license will be added in the future.
