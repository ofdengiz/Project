import argparse
import base64
import json
import sys


def main() -> int:
    parser = argparse.ArgumentParser(description="Execute SSH commands with password auth.")
    parser.add_argument("--host", required=True)
    parser.add_argument("--user", required=True)
    parser.add_argument("--password", required=True)
    parser.add_argument("--command-b64", required=True)
    parser.add_argument("--timeout", type=int, default=10)
    args = parser.parse_args()

    try:
        import paramiko
    except Exception as exc:  # pragma: no cover - environment check
        print(json.dumps({"ok": False, "error": f"paramiko import failed: {exc}"}))
        return 2

    command = base64.b64decode(args.command_b64).decode("utf-8")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        client.connect(
            hostname=args.host,
            username=args.user,
            password=args.password,
            timeout=args.timeout,
            look_for_keys=False,
            allow_agent=False,
        )
        stdin, stdout, stderr = client.exec_command(command, timeout=args.timeout)
        exit_code = stdout.channel.recv_exit_status()
        payload = {
            "ok": True,
            "exit_code": exit_code,
            "stdout": stdout.read().decode("utf-8", errors="replace"),
            "stderr": stderr.read().decode("utf-8", errors="replace"),
        }
        print(json.dumps(payload))
        return 0
    except Exception as exc:
        print(json.dumps({"ok": False, "error": str(exc)}))
        return 1
    finally:
        client.close()


if __name__ == "__main__":
    raise SystemExit(main())
