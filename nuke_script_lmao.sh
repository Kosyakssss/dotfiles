APP="SomeApp"
BUNDLE="com.vendor.someapp"

rm -rf "$HOME/Library/Application Support/$APP"
rm -rf "$HOME/Library/Caches/$BUNDLE"
rm -rf "$HOME/Library/Preferences/$BUNDLE.plist"
rm -rf "$HOME/Library/Logs/$APP"
rm -rf "$HOME/Library/Containers/$BUNDLE" \
       "$HOME/Library/Group Containers/"*"$BUNDLE"*
