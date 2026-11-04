# App Store Connect listing

Draft text for the Mac App Store listing. Character limits are Apple's.

## Basics
- **Name (max 30):** Chord for Safari
- **Subtitle (max 30):** PiP and copy-link shortcuts
- **Bundle ID:** com.raggesilver.Chord
- **Primary category:** Utilities
- **Price:** Free
- **Copyright:** 2026 Paulo Queiroz

## Promotional text (max 170)
Toggle Picture in Picture and copy the page address with one keyboard shortcut, right from Safari.

## Description
Chord adds fast keyboard shortcuts to Safari.

PICTURE IN PICTURE
Press Shift-Command-P to pop the video on the page into Picture in Picture, and press it again to bring it back. Chord picks the video that's playing, or the largest one on the page. It works on YouTube, Crunchyroll, Prime Video, HBO Max, Disney+ and Paramount+.

COPY ADDRESS
Press Shift-Command-C to copy the current tab's address. A small "Address copied" message confirms it, and you can turn that message off in the app.

YOURS TO CHANGE
Remap both shortcuts in Safari Settings > Extensions.

PRIVATE BY DESIGN
Chord never connects to the internet and collects no data.

To start: open Chord, then turn it on in Safari Settings > Extensions and allow it on the websites where you want Picture in Picture.

## Keywords (max 100, comma separated)
safari,extension,picture in picture,pip,shortcut,hotkey,copy url,copy link,video,keyboard

## Support URL / Privacy Policy URL
- Support URL: https://github.com/raggesilver/chord/issues
- Privacy Policy URL: https://github.com/raggesilver/chord/blob/main/docs/privacy-policy.md

## App Review notes
Chord is a Safari Web Extension with a small companion app.

How to test: open the app once, then enable "Chord" in Safari Settings > Extensions and set website access to Allow for All Websites. Open a video page such as YouTube, start playback, and press Shift-Command-P (Picture in Picture). Press Shift-Command-C on any page to copy its address; an "Address copied" toast appears near the bottom of the screen.

Why all-websites access: the extension must find a video element on any site the user watches video on. It reads only the presence and playback state of video elements. It collects and transmits nothing, and the app has no network entitlement.

The extension asks the companion app, through a native message, to write the address to the clipboard and to show the toast. If the system shortcut is already taken, the user can remap it in Safari Settings > Extensions.

## Screenshots (macOS, one of these sizes)
1280x800, 1440x900, 2560x1600 or 2880x1800. The submitted set (2880x1800) is in `docs/screenshots/`:
1. `01-picture-in-picture.png`: YouTube with Picture in Picture active.
2. `02-copy-address.png`: the "Address copied" toast over a page.
3. `03-light-and-dark.png`: the app window in light and dark.
4. `04-shortcuts.png`: the two shortcuts and the app window.
