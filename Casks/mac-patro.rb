cask "mac-patro" do
  version "1.0.12"
  sha256 "f9c509459c499141412d6e458d95251e9573e2c89ca0315525739f172b8cbea5"

  url "https://github.com/ntn0de/mac-patro-native/releases/download/v#{version}/Mac-Patro-latest.dmg"
  name "Mac Patro"
  desc "Nepali calendar and date converter for the macOS menu bar"
  homepage "https://github.com/ntn0de/mac-patro-native"

  app "Mac Patro.app"

  caveats <<~EOS
    If macOS blocks the app after installation, run:
      xattr -cr /Applications/Mac\ Patro.app
  EOS
end
