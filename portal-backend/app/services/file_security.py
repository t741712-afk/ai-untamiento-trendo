import os
import json
import amaas.grpc

FILE_SECURITY_REGION  = os.getenv("FILE_SECURITY_REGION", "eu-central-1")
FILE_SECURITY_API_KEY = os.getenv("FILE_SECURITY_API_KEY")

def scan_file(file_path: str) -> dict:
    print(f"[FILE_SECURITY] scan_file() llamado con: {file_path}")
    print(f"[FILE_SECURITY] Región: {FILE_SECURITY_REGION}")

    try:
        channel = amaas.grpc.init_by_region(
            region=FILE_SECURITY_REGION,
            api_key=FILE_SECURITY_API_KEY,
        )

        result = amaas.grpc.scan_file(
            channel,
            file_path,
            verbose=True
        )

        amaas.grpc.quit(channel)

        print(f"[FILE_SECURITY] Resultado raw SDK: {result}")

        try:
            parsed = json.loads(result)
            print(f"[FILE_SECURITY] Resultado parseado JSON: {parsed}")
            return parsed
        except Exception:
            return {
                "status": "raw_result",
                "details": result
            }

    except Exception as e:
        print(f"[FILE_SECURITY] ERROR SDK: {str(e)}")
        return {
            "status": "error",
            "details": str(e)
        }
