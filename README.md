# PocketAI

A native SwiftUI iPhone starter app for a personal AI assistant.

## Features
- Chat interface with conversation bubbles
- Demo mode works immediately without an API key
- Optional secure backend integration (the iOS app never stores your AI provider key)
- Voice input using Apple Speech recognition
- Document text extraction for PDF and plain-text files
- Local reminder scheduling
- Settings for backend URL and demo/live mode

## Requirements
- Xcode 16 or newer
- iOS 17.0+
- macOS for building/signing the iOS app

## Open in Xcode
1. Unzip the repository.
2. Open `PocketAI.xcodeproj`.
3. Select the `PocketAI` scheme and an iPhone simulator.
4. Build and run.

The project uses a placeholder bundle identifier: `com.example.PocketAI`. Change it under **Target > Signing & Capabilities > Bundle Identifier** before publishing.

## Connect a real AI model safely
Do **not** put an OpenAI/API provider secret in the iOS app. Mobile app binaries can be inspected.

1. Deploy the included Node backend (`backend/`) to a trusted host.
2. Set the server environment variable `OPENAI_API_KEY`.
3. Set `OPENAI_MODEL` if desired (default: `gpt-4o-mini`).
4. Deploy with `npm install && npm start`.
5. In PocketAI > Settings, turn off Demo Mode and enter your backend URL, e.g. `https://your-domain.example`.
6. The app calls `POST /api/chat` on that backend.

The backend uses the OpenAI Responses API. Review provider pricing, terms, privacy requirements, and regional availability before launch.

## Backend setup
```bash
cd backend
cp .env.example .env
# Edit .env and add your API key
npm install
npm start
```

For local iPhone simulator testing, use `http://localhost:3000` only if the backend runs on the same Mac and the simulator can reach it. For a physical iPhone, use your Mac's LAN IP or deploy HTTPS. Production should use HTTPS.

## GitHub
Create a new GitHub repository, then:
```bash
git init
git add .
git commit -m "Initial PocketAI iOS app"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/PocketAI.git
git push -u origin main
```

A GitHub Actions workflow is included to build the app on macOS runners.

## Before App Store release
- Replace the placeholder bundle ID and add your Apple Developer signing team.
- Add a real privacy policy and support URL.
- Disclose AI processing and document/voice data handling.
- Add account deletion if accounts are introduced.
- Test VoiceOver, Dynamic Type, network failures, and supported devices.
- Configure App Store subscription products only after creating them in App Store Connect.
- Do not claim medical, legal, or financial expertise.

## Project layout
- `PocketAI/` — SwiftUI iOS app
- `backend/` — Node.js API proxy
- `.github/workflows/ios-build.yml` — CI build
