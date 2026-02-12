from __future__ import annotations

import time
from typing import Any, Dict, Iterable, Optional


def map_model(model: Optional[str], model_map: Dict[str, str]) -> Optional[str]:
    if not model:
        return None
    return model_map.get(model, model)


def build_responses_request(payload: Dict[str, Any], model_map: Dict[str, str]) -> Dict[str, Any]:
    model = map_model(payload.get("model"), model_map)
    stream = bool(payload.get("stream"))

    if "messages" in payload:
        input_items = []
        for message in payload.get("messages", []):
            role = message.get("role", "user")
            content = message.get("content", "")
            input_items.append({"role": role, "content": content})
        input_value: Any = input_items
    else:
        input_value = payload.get("prompt", "")

    max_tokens = payload.get("max_completion_tokens", payload.get("max_tokens"))

    responses_request: Dict[str, Any] = {
        "model": model,
        "input": input_value,
        "stream": stream,
    }

    if max_tokens is not None:
        responses_request["max_output_tokens"] = max_tokens
    if "temperature" in payload:
        responses_request["temperature"] = payload["temperature"]
    if "top_p" in payload:
        responses_request["top_p"] = payload["top_p"]

    return responses_request


def extract_text_from_response(output: Iterable[Dict[str, Any]]) -> str:
    parts = []
    for item in output:
        for content in item.get("content", []):
            if content.get("type") == "output_text":
                parts.append(content.get("text", ""))
    return "".join(parts)


def to_chat_completions(response: Dict[str, Any]) -> Dict[str, Any]:
    text = extract_text_from_response(response.get("output", []))
    created = response.get("created", int(time.time()))

    usage = response.get("usage", {})
    prompt_tokens = usage.get("input_tokens")
    completion_tokens = usage.get("output_tokens")
    total_tokens = usage.get("total_tokens")
    if total_tokens is None and prompt_tokens is not None and completion_tokens is not None:
        total_tokens = prompt_tokens + completion_tokens

    return {
        "id": response.get("id", "chatcmpl-adapter"),
        "object": "chat.completion",
        "created": created,
        "choices": [
            {
                "index": 0,
                "message": {"role": "assistant", "content": text},
                "finish_reason": response.get("finish_reason", "stop"),
            }
        ],
        "usage": {
            "prompt_tokens": prompt_tokens,
            "completion_tokens": completion_tokens,
            "total_tokens": total_tokens,
        },
    }


def to_completions(response: Dict[str, Any]) -> Dict[str, Any]:
    text = extract_text_from_response(response.get("output", []))
    created = response.get("created", int(time.time()))

    usage = response.get("usage", {})
    prompt_tokens = usage.get("input_tokens")
    completion_tokens = usage.get("output_tokens")
    total_tokens = usage.get("total_tokens")
    if total_tokens is None and prompt_tokens is not None and completion_tokens is not None:
        total_tokens = prompt_tokens + completion_tokens

    return {
        "id": response.get("id", "cmpl-adapter"),
        "object": "text_completion",
        "created": created,
        "choices": [
            {
                "text": text,
                "index": 0,
                "logprobs": None,
                "finish_reason": response.get("finish_reason", "stop"),
            }
        ],
        "usage": {
            "prompt_tokens": prompt_tokens,
            "completion_tokens": completion_tokens,
            "total_tokens": total_tokens,
        },
    }
