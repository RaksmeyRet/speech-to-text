# Khemra Flutter frontend

This Flutter app uses the Django RAG API for chat search, document details, and
video answers.

## Run against the backend

Start the Django server on port `8000`, then run the app:

```powershell
flutter run
```

The API base URL can be overridden at build/run time:

```powershell
flutter run --dart-define=API_BASE_URL=http://YOUR_HOST:8000
```

The default URL is `http://10.0.2.2:8000` for the Android emulator and
`http://127.0.0.1:8000` for other targets. For a physical Android device, set
`API_BASE_URL` to the computer's LAN IP address. Local HTTP cleartext traffic is
enabled only in the Android debug manifest; use HTTPS for production.

## Frontend integration

- Khmer text and speech are translated to English before being sent as the
  question to `POST /api/rag/knowledge/search/`. The selected language is sent
  separately so the backend can return the matching-language source.
- Khmer typed questions and live microphone speech are translated to English
  before search. The current backend does not provide uploaded-audio
  transcription, so use the microphone or type the question instead of sending
  a selected audio file.
- Answers display the matched backend summaries/transcripts. Video results can
  be opened from their result cards and play from the matched timestamp.
- Selecting a result loads `GET /api/rag/knowledge/<id>/`. Video results can be
  played from the matched timestamp; PDF results open at the matched page when
  supported by the platform's PDF viewer.
