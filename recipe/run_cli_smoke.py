"""Exercise installed CLI entry points without starting Redis or a web server."""
import subprocess


def check(args, expected_status, expected_text):
    result = subprocess.run(args, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, timeout=15)
    output = result.stdout + result.stderr
    assert result.returncode == expected_status, (
        f"{args}: expected exit {expected_status}, got {result.returncode}\n{output}")
    for text in expected_text:
        assert text in output, f"{args}: missing {text!r}\n{output}"
    if expected_status == 0:
        assert "#Exception" not in output, f"{args}: help reported an exception\n{output}"
    # These messages occur after argument parsing, during normal service startup.
    assert "redis-server URI" not in output, f"{args}: unexpectedly started the controller"
    print(f"PASS: {' '.join(args)} (exit {result.returncode})")


for executable in ("Sampler", "Sink", "NullDevice"):
    check([executable, "--help"], 0, ("--help", "--severity"))

for option in ("--help", "-h"):
    check(["daq-webctl", option], 0, ("--help", "--redis-uri", "--http-uri"))

check(["daq-webctl", "--nestdaq-unknown-option"], 1,
      ("unrecognised option", "--nestdaq-unknown-option"))
check(["daq-webctl", "--threads"], 1, ("--threads", "required argument"))
print("All 7 CLI smoke checks passed.")
