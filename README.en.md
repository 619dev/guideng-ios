# Guideng iOS

[中文](./README.md)

Guideng iOS is the iOS app wrapper for the Guideng frontend. It is built with React, Vite, and Capacitor. The app is designed for family location sharing: after signing in to a self-hosted Guideng server, it collects device location updates and sends them to the configured server.

## Features

- Wraps the existing Guideng frontend as an iOS app
- Collects device location and reports it to a Guideng server
- Uses a native background geolocation plugin for iOS background updates
- Shows devices, latest locations, and 7-day tracks
- Supports AMap display and external map links
- Supports Chinese and English UI

## Stack

- React 19
- Vite 8
- TypeScript
- Capacitor 7
- `@capacitor-community/background-geolocation`

## Requirements

- Node.js and npm
- macOS
- Xcode
- iOS device or simulator

Background location behavior should be fully verified on a real device. iOS requires user location permission, and continuous background location usually requires the user to choose “Always Allow”.

## Install

```sh
npm install
```

## Development Preview

```sh
npm run dev
```

The default Vite development port is `5173`.

## Build Frontend

```sh
npm run build
```

The built assets are emitted to `dist/`.

## Sync iOS Project

```sh
npm run cap:sync
```

This command builds the frontend first, then syncs `dist/` into the iOS project.

## Open iOS Project

```sh
npm run ios
```

This command syncs web assets and opens the Xcode project. In Xcode, configure the development team, bundle identifier, and signing certificate before running the app on a device.

## iOS Permissions

The project already configures the following keys in [Info.plist](./ios/App/App/Info.plist):

- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `UIBackgroundModes` with `location`

The app can report location only after the user grants location permission. Even with background location enabled, iOS may still manage background execution according to system policy, battery state, and user settings.

## Server Configuration

The login screen requires:

- Server URL
- Token

The app uses the server API to register the device, report location, read the device list, read tracks, and read map configuration. Data storage is controlled by the self-hosted Guideng server entered by the user.

## Scripts

```sh
npm run dev       # Start local development server
npm run build     # Build frontend
npm run preview   # Preview built assets
npm run cap:sync  # Build and sync iOS project
npm run ios       # Sync and open Xcode project
```

## Project Structure

```text
.
├── capacitor.config.ts
├── ios/
│   └── App/
├── public/
├── src/
├── index.html
├── package.json
└── README.md
```

## Privacy

After the user signs in and grants permission, Guideng collects the device location and sends device name, device ID, current location, accuracy, speed, heading, and timestamps to the self-hosted server entered by the user. Use the app only on devices you are authorized to use, and make sure every location-sharing participant is informed and has agreed.

## License

This project is licensed under the [MIT License](./LICENSE).
