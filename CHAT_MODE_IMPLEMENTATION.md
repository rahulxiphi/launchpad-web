# Hybrid Chat/Voice Mode Implementation Guide

This document explains how the bidirectional Chat and Voice mode was implemented in the Launchpad web client using the ElevenLabs Flutter SDK (`elevenlabs_agents`).

## 1. The Mediator Page (`ModeSelectionPage`)

Previously, clicking "Get Started" on the intake form immediately fetched an ElevenLabs token and launched the `VoicePage`.

To support user choice, we introduced an intermediary page:
- **File:** `lib/features/voice/mode_selection_page.dart`
- **Functionality:** This page presents two clear options: "Start voice conversation" and "Or let's chat instead".
- **Token Fetching:** The ElevenLabs session token is **only** fetched after the user makes a selection here. 
- **Navigation:** It passes the selected mode via the `initialMode` parameter (`'chat'` or `'voice'`) to the `VoicePage`.

## 2. Unifying the UI (`VoicePage`)

Instead of creating a completely separate Chat UI, we leveraged the existing `VoicePage` to ensure a consistent design and single source of truth for the conversation logic.

- **File:** `lib/features/voice/voice_page.dart`
- **State Management:** A new state variable `_isChatMode` is initialized based on the `initialMode` parameter passed from the mediator page.
- **Dynamic Bottom Bar:** The `_BottomBar` widget dynamically updates its UI based on `_isChatMode`.
  - In **Voice Mode**: Displays the microphone button to talk and a "Let's chat" text button to switch modes.
  - In **Chat Mode**: Hides the microphone and displays a text input field with a "Let's talk" button to switch back.

## 3. How the Switching Works

The core of the bidirectional switching is handled by manipulating the user's microphone state via the ElevenLabs `ConversationClient` (`client.setMicMuted()`), rather than dropping and restarting the connection.

When the user taps the toggle button (e.g. "Let's chat" or "Let's talk"):
1. The `onToggleMode` callback is triggered.
2. The local `_isChatMode` boolean is inverted, causing the UI to rebuild and swap the input methods.
3. We immediately call `_client.setMicMuted(newMode)` on the active ElevenLabs session.

### The "Hybrid" Approach
Currently, the application uses a **Hybrid Mode**. 
Because the `elevenlabs_agents` Flutter SDK (version 0.4.0) lacks a public method to dynamically update configuration overrides (like `text_only: true`) mid-session, we rely entirely on muting the user's microphone.

- **What happens:** When the user switches to Chat Mode, their microphone is muted, allowing them to type silently. However, the agent's Text-to-Speech (TTS) is **not** disabled. The agent will read its text responses out loud.
- **Why this path:** The alternative required disconnecting the LiveKit session entirely and regenerating a new backend token every time the user toggled the mode, introducing a 3-5 second loading screen on every switch and losing immediate conversation context.

## 4. ElevenLabs Dashboard Settings

**Important:** Do **NOT** enable the "Enable chat mode" toggle in the ElevenLabs agent's Advanced Settings dashboard. 
Enabling that toggle will permanently convert the agent into a text-only bot on the backend, completely breaking the Voice Mode functionality for all users. The switching is handled purely via the frontend microphone muting logic.

## 5. Official Feature Request for ElevenLabs
If you need to escalate this via your main account, here are the exact messages you can send to ElevenLabs support to provide full context and make the feature request.

**Message 1: Providing Context**
> *"Hi team, we are building a multimodal conversational AI platform using your Flutter `elevenlabs_agents` SDK. Our core requirement is a seamless 'hybrid' interface where users can instantly toggle between a Voice Mode (talking) and a Chat Mode (typing) mid-session. Currently, we achieve this by toggling `client.setMicMuted()`. However, while this mutes the user, the agent continues to speak out loud via TTS when in Chat Mode. We want a truly silent Chat Mode without dropping the active LiveKit connection."*

**Message 2: The Exact Feature Request**
> *"Because the SDK abstracts the underlying LiveKit implementation, we cannot access the `Room` object to mute the remote audio track. Furthermore, the `_sendOverrides` method in `ConversationClient` locks after the first call, so we cannot update the `text_only` configuration override mid-session.*
> 
> *Feature Request: Please expose a public method in the Flutter SDK to either (A) dynamically mute the agent's incoming audio playback mid-session (e.g., `client.setSpeakerMuted(true)`) or (B) allow dynamic updates to `ConversationOverrides` so we can toggle `text_only: true` on the fly. This is essential for providing accessible, seamless hybrid Chat/Voice applications."*

