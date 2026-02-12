from __future__ import annotations

import json
from typing import AsyncIterator, Dict


def _sse(data: Dict) -> bytes:
    return f"data: {json.dumps(data, ensure_ascii=False)}\n\n".encode("utf-8")


async def stream_chat_completions(lines: AsyncIterator[str]) -> AsyncIterator[bytes]:
    for_line_id = "chatcmpl-adapter"
    async for line in lines:
        if not line.startswith("data: "):
            continue
        payload = line[6:].strip()
        if payload == "[DONE]":
            yield b"data: [DONE]\n\n"
            continue

        try:
            event = json.loads(payload)
        except json.JSONDecodeError:
            continue

        event_type = event.get("type")
        if event_type == "response.output_text.delta":
            delta = event.get("delta") or event.get("text") or ""
            chunk = {
                "id": for_line_id,
                "object": "chat.completion.chunk",
                "choices": [
                    {
                        "index": 0,
                        "delta": {"content": delta},
                        "finish_reason": None,
                    }
                ],
            }
            yield _sse(chunk)
        elif event_type == "response.completed":
            chunk = {
                "id": for_line_id,
                "object": "chat.completion.chunk",
                "choices": [
                    {
                        "index": 0,
                        "delta": {},
                        "finish_reason": "stop",
                    }
                ],
            }
            yield _sse(chunk)
            yield b"data: [DONE]\n\n"


async def stream_completions(lines: AsyncIterator[str]) -> AsyncIterator[bytes]:
    for_line_id = "cmpl-adapter"
    async for line in lines:
        if not line.startswith("data: "):
            continue
        payload = line[6:].strip()
        if payload == "[DONE]":
            yield b"data: [DONE]\n\n"
            continue

        try:
            event = json.loads(payload)
        except json.JSONDecodeError:
            continue

        event_type = event.get("type")
        if event_type == "response.output_text.delta":
            delta = event.get("delta") or event.get("text") or ""
            chunk = {
                "id": for_line_id,
                "object": "text_completion",
                "choices": [
                    {
                        "index": 0,
                        "text": delta,
                        "logprobs": None,
                        "finish_reason": None,
                    }
                ],
            }
            yield _sse(chunk)
        elif event_type == "response.completed":
            chunk = {
                "id": for_line_id,
                "object": "text_completion",
                "choices": [
                    {
                        "index": 0,
                        "text": "",
                        "logprobs": None,
                        "finish_reason": "stop",
                    }
                ],
            }
            yield _sse(chunk)
            yield b"data: [DONE]\n\n"
