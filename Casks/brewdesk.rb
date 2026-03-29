cask "brewdesk" do
  version :latest
  sha256 :no_check

  url "https://github.com/aljaff94/BrewDesk/releases/latest/download/BrewDesk.zip"
  name "BrewDesk"
  desc "Native macOS GUI for Homebrew package manager"
  homepage "https://github.com/aljaff94/BrewDesk"

  app "BrewDesk.app"

  zap trash: [
    "~/Library/Preferences/com.brewdesk.BrewDesk.plist",
    "~/Library/Caches/com.brewdesk.BrewDesk",
  ]
end
