cask "mac-patro" do
  version "1.1.0"
  sha256 "98cede9edc51cb20b31f24560323791726ef474914d676569e50014458038139"

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
