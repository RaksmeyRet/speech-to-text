# Khemra Flutter frontend

This Flutter app uses the Django RAG API for chat search, document details, and
video answers.

## Run against the backend

Start the Django server on port `8000`, then run the app. The Android emulator
uses `http://10.0.2.2:8000` by default; other targets use
`http://127.0.0.1:8000`.

For a physical Android phone, connect the phone and computer to the same Wi-Fi,
start the backend so it listens on `0.0.0.0:8000`, and use the computer's
current Wi-Fi IPv4 address:

```powershell
flutter run --dart-define=API_BASE_URL=http://YOUR_COMPUTER_LAN_IP:8000
```

Find the computer's address with `ipconfig` (the IPv4 Address under the active
Wi-Fi adapter). For example:

```powershell
flutter run --dart-define=API_BASE_URL=http://172.16.10.101:8000
```

Allow port `8000` through the computer's firewall if the phone still cannot
connect. Local HTTP cleartext traffic is enabled only in the Android debug
manifest; use HTTPS for production.

## Frontend integration

- Khmer text and speech are translated to English before being sent as the
  question to `POST /api/rag/knowledge/search/ai-overview/`. Khmer questions receive Khmer
  answers and translated source cards even when the language dropdown is set to
  English; otherwise, the selected language is used.
- Khmer typed questions and live microphone speech are translated to English
  before search. The current backend does not provide uploaded-audio
  transcription, so use the microphone or type the question instead of sending
  a selected audio file.
- Answers display the matched backend summaries/transcripts. Video results can
  be opened from their result cards and play from the matched timestamp.
- Selecting a result loads `GET /api/rag/knowledge/<id>/`. Video results can be
  played from the matched timestamp; PDF results open at the matched page when
  supported by the platform's PDF viewer.
