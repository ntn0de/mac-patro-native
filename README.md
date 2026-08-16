# MacPatro Native

A simple and lightweight macOS menu bar application to display the Nepali date.

## Installation

### Homebrew

Homebrew 6+ will not load this third-party cask until you trust it once:

```bash
brew tap ntn0de/mac-patro-native https://github.com/ntn0de/mac-patro-native
brew trust --cask ntn0de/mac-patro-native/mac-patro
```

If `Mac Patro.app` is already in Applications (a DMG, test build, or older copy), quit it and remove that copy so Homebrew can install:

```bash
rm -rf /Applications/Mac\ Patro.app
```

Then install and clear macOS quarantine:

```bash
brew install --cask mac-patro
xattr -cr /Applications/Mac\ Patro.app
```

Update later with:

```bash
brew update
brew upgrade --cask mac-patro
xattr -cr /Applications/Mac\ Patro.app
```

### Direct Download

1. Go to [GitHub Releases](https://github.com/ntn0de/mac-patro-native/releases).
2. Download the `.dmg` file from the latest release.
3. Open it and drag `Mac Patro.app` to your Applications folder.

If macOS says the app is damaged or should be moved to the Trash, see the **Troubleshooting** section below.


## Troubleshooting

### "App is damaged and can’t be opened. You should move it to the Trash."

This can happen if macOS has quarantined the app because it was downloaded from the internet and not notarized. Quit Mac Patro, then run:

```bash
xattr -cr /Applications/Mac\ Patro.app
```

If a Homebrew install failed because the app already existed, delete `/Applications/Mac Patro.app` first, install again, then run the `xattr` command.

After that, you should be able to open the app.

The same `xattr` command is also shown inside the app under **Settings → Check for Updates** and **About**.


## Building from Source

If you prefer to build the application from the source code, follow these instructions.

### Prerequisites

To build the DMG installer, you will need to install `create-dmg`. You can install it using [Homebrew](https://brew.sh/):

```bash
brew install create-dmg
```

### Configuration

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

### Build Steps

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/ntn0de/mac-patro-native.git
    cd mac-patro-native
    ```

2.  **Build the universal executable:**
    ```bash
    swift build -c release --arch arm64 --arch x86_64
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
    cp .build/apple/Products/Release/MacPatroNativeApp dist/Mac\ Patro.app/Contents/MacOS/
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
        <key>LSUIElement</key>
        <string>1</string>
    </dict>
    </plist>
    EOF
    ```
8.  **Build the DMG:**
    This step packages the `.app` bundle into a `.dmg` installer.
    ```bash
    create-dmg \
      --volname "Mac Patro Installer" \
      --window-pos 200 120 \
      --window-size 800 400 \
      --icon-size 100 \
      --icon "Mac Patro.app" 200 190 \
      --hide-extension "Mac Patro.app" \
      --app-drop-link 600 185 \
      "dist/Mac Patro v1.0.0.dmg" \
      "dist/Mac Patro.app"
    ```
    *Note: Replace `v1.0.0` with the desired version number.*

## Automated Release Workflow

Version tags trigger the release workflow. It builds the application, publishes the DMGs and GitHub release, then updates the Homebrew cask on `main`.

### Setting Up the Remote URL for Releases

The automated workflow requires a secret to be set in your repository to securely access the remote URL for the calendar data.

1.  **Navigate to your repository** on GitHub.
2.  Click on the **Settings** tab.
3.  In the left sidebar, expand **Secrets and variables**, then click on **Actions**.
4.  Click **New repository secret**.
5.  For the **Name**, enter `REMOTE_URL`.
6.  For the **Secret**, paste your full data source URL (e.g., `https://your-data-source.com/year/`).
7.  Click **Add secret**.
### How to Release

After merging the release changes into `main`, create and push an explicit semantic-version tag:

```bash
git switch main
git pull --ff-only
git tag v1.0.13
git push origin v1.0.13
```

The workflow then:

1. Builds and publishes the GitHub release and DMGs.
2. Waits for release creation to succeed.
3. Updates the cask version and SHA256.
4. Commits and pushes the cask update to `main`.


## License

This project is intended to be open-sourced. A license will be added in the future.
