import os;
import json;
import backend.config as config;
import from unittest.mock { patch, MagicMock }
import from urllib.error { HTTPError, URLError }
import from contextlib { AbstractContextManager }

test "missing key is reported and never sends a request" {
    with patch.object(config.dotenv, "load_dotenv") {
        with (patch.dict(os.environ, {"OPENROUTER_API_KEY": "  "}) as AbstractContextManager) {
            with patch.object(config, "urlopen") as send {
                status = config.openrouter_status(True);
                assert status["status"] == "missing_key";
                assert status["key_configured"] == False;
                assert status["request_attempted"] == False;
                send.assert_not_called();
            }
        }
    }
}

test "configured key and model override do not imply a live request" {
    with patch.object(config.dotenv, "load_dotenv") {
        with (patch.dict(os.environ, {"OPENROUTER_API_KEY": "test-only-key", "VISION_MODEL": "test-vision"}) as AbstractContextManager) {
            with patch.object(config, "urlopen") as send {
                status = config.openrouter_status();
                assert status["status"] == "configured";
                assert status["key_configured"] == True;
                assert status["request_attempted"] == False;
                assert status["model"] == "test-vision";
                assert "test-only-key" not in json.dumps(status);
                send.assert_not_called();
            }
        }
    }
}

test "live check sends the backend bearer key and the same vision model" {
    response = MagicMock(status=200);
    response.__enter__.return_value = response;
    response.read.return_value = json.dumps({"choices": [{"message": {"content": "READY"}}]}).encode("utf-8");
    with patch.object(config.dotenv, "load_dotenv") {
        with (patch.dict(os.environ, {"OPENROUTER_API_KEY": " test-only-key ", "VISION_MODEL": "test-vision"}) as AbstractContextManager) {
            with patch.object(config, "urlopen", return_value=response) as send {
                status = config.openrouter_status(True);
                request = send.call_args[0][0];
                payload = json.loads(str(request.data.decode("utf-8")));
                assert request.get_header("Authorization") == "Bearer test-only-key";
                assert payload["model"] == "test-vision";
                assert payload["max_tokens"] == 2048;
                assert payload["reasoning"] == {"enabled": False, "exclude": True};
                assert status["status"] == "connected";
                assert status["request_attempted"] == True;
                assert status["http_status"] == 200;
                assert "content" not in status;
                assert "test-only-key" not in json.dumps(status);
            }
        }
    }
}

test "authentication and rate limit errors are distinct and sanitized" {
    with patch.object(config.dotenv, "load_dotenv") {
        with (patch.dict(os.environ, {"OPENROUTER_API_KEY": "test-only-key"}) as AbstractContextManager) {
            for (code, expected) in [(401, "unauthorized"), (403, "forbidden"), (429, "rate_limited"), (503, "provider_error")] {
                failure = HTTPError("https://openrouter.ai", code, "test-only-key", None, None);
                with patch.object(config, "urlopen", side_effect=failure) {
                    status = config.openrouter_status(True);
                    assert status["status"] == expected;
                    assert status["http_status"] == code;
                    assert status["request_attempted"] == True;
                    assert "test-only-key" not in json.dumps(status);
                }
            }
        }
    }
}

test "timeouts and network failures return actionable status" {
    with patch.object(config.dotenv, "load_dotenv") {
        with (patch.dict(os.environ, {"OPENROUTER_API_KEY": "test-only-key"}) as AbstractContextManager) {
            for (failure, expected) in [(TimeoutError(), "timeout"), (URLError(TimeoutError()), "timeout"), (URLError("test-only-key"), "network_error")] {
                with patch.object(config, "urlopen", side_effect=failure) {
                    status = config.openrouter_status(True);
                    assert status["status"] == expected;
                    assert "test-only-key" not in json.dumps(status);
                }
            }
        }
    }
}

test "invalid and reasoning-only replies are not green connection checks" {
    response = MagicMock(status=200);
    response.__enter__.return_value = response;
    with patch.object(config.dotenv, "load_dotenv") {
        with (patch.dict(os.environ, {"OPENROUTER_API_KEY": "test-only-key"}) as AbstractContextManager) {
            with patch.object(config, "urlopen", return_value=response) {
                response.read.return_value = "not JSON test-only-key".encode("utf-8");
                status = config.openrouter_status(True);
                assert status["status"] == "invalid_response";
                assert "test-only-key" not in json.dumps(status);
                response.read.return_value = json.dumps({"choices": [{"message": {"reasoning": "thinking"}}]}).encode("utf-8");
                status = config.openrouter_status(True);
                assert status["status"] == "reasoning_only";
                assert "content" not in status;
                assert config.query_openrouter(config.MODEL_VISION, "system", "user") == "";
            }
        }
    }
}

test "structured extraction requests JSON with the requested output budget" {
    response = MagicMock(status=200);
    response.__enter__.return_value = response;
    response.read.return_value = json.dumps({"choices": [{"message": {"content": "{\"concepts\": []}"}}]}).encode("utf-8");
    with patch.object(config.dotenv, "load_dotenv") {
        with (patch.dict(os.environ, {"OPENROUTER_API_KEY": "test-only-key"}) as AbstractContextManager) {
            with patch.object(config, "urlopen", return_value=response) as send {
                content = config.query_openrouter(config.MODEL_VISION, "system", "user", "", True, 4096);
                request = send.call_args[0][0];
                payload = json.loads(str(request.data.decode("utf-8")));
                assert content == "{\"concepts\": []}";
                assert payload["response_format"] == {"type": "json_object"};
                assert payload["max_tokens"] == 4096;
            }
        }
    }
}
