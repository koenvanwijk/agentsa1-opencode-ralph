from generated.config import SignalsConfig
from generated.runtime import ActiveWorkersRuntime, RequestDurationRuntime


def test_defaults():
    config = SignalsConfig()
    assert config.request_duration.enabled is True
    assert config.active_workers.enabled is False


def test_runtime_without_folding():
    runtime = RequestDurationRuntime(SignalsConfig().request_duration)
    assert runtime.fold_key({"method": "GET", "status": "200", "zone": "west"}) == (
        ("method", "GET"),
        ("status", "200"),
        ("zone", "west"),
    )


def test_unrelated_runtime():
    runtime = ActiveWorkersRuntime(SignalsConfig().active_workers)
    assert runtime.fold_key({"pool": "main"}) == (("pool", "main"),)

