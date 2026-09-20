cask "mac-patro" do
  version "1.1.2"
  sha256 "17867c8872223eb28bbc4ca96b0bb733293baadfd2ce696faa1ca165a05214ca"

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
