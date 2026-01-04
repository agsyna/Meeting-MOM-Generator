# Meeting MOM Generator

The **Meeting MOM Generator** is an AI-powered tool that automatically records, transcribes, and summarizes meetings.  
It identifies speakers, extracts key decisions and generates structured **Minutes of Meeting (MOM)** to simplify post-meeting documentation.

---

## Overview

Manual note-taking often results in missed information or inconsistent summaries.  
The Meeting MOM Generator automates this process using **speech recognition** and **speaker diarization** to produce accurate transcripts and concise summaries in real time.  

It ensures that all discussions, decisions and action items are accurately captured and easily accessible.

---

## Features

- Real-time audio recording within the app  
- Automatic speech-to-text transcription  
- Speaker diarization (distinguishes between multiple speakers)  
- Timestamped transcripts for precise reference  
- Automated MOM generation summarizing key points and decisions  
- Export options for PDF or text formats  

---

## Tech Stack

| Layer | Technology |
|-------|-------------|
| Frontend | Flutter (Dart) |
| Backend | Flask |
| Speech Processing | Python (SpeechRecognition, Whisper, Pyannote-audio) |

---

## How It Works

1. **Record Meeting**  
   The user records audio directly within the Flutter application.

2. **Process Audio**  
   The recorded audio is sent to the backend for processing.  
   Python-based models perform transcription and speaker diarization.

3. **Generate MOM**  
   The processed transcript is analyzed to extract key points, decisions, and action items.

4. **Display and Export**  
   The final transcript and MOM are displayed in the app and can be downloaded or shared.

---
