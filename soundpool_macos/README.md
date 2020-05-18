# soundpool_macos

A Flutter Sound Pool for playing short media files.

## Entitlements
To load sound file from network you need to add to your `.entitlements` files lines as below
```
<key>com.apple.security.network.client</key>
<true/>
```
