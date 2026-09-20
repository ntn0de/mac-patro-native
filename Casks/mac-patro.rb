cask "mac-patro" do
  version "1.1.1"
  sha256 "6fe21b2f518a41d6462c09ef0bef9488532bb4b26cba6e8f9d6bc8cc94f7fb0b"

  url "https://github.com/ntn0de/mac-patro-native/releases/download/v#{version}/Mac-Patro-latest.dmg"
  name "Mac Patro"
  desc "Nepali calendar and date converter for the macOS menu bar"
  homepage "https://github.com/ntn0de/mac-patro-native"

  app "Mac Patro.app"

  caveats <<~EOS
    If an existing Mac Patro.app is already in /Applications, quit it and
    delete that copy before installing with Homebrew.

    After installation, if macOS blocks the app, run:
      xattr -cr /Applications/Mac\ Patro.app
  EOS
end
