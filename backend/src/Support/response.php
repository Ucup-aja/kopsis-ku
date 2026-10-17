<?php
// Uniform JSON envelope — ARCHITECTURE.md §6, API_CONTRACT.md §1.
// Success: {success:true, message, data}
// Error:   {success:false, message, error:{code, fields}, data:null}
// Production must not leak SQL/stack traces (SECURITY.md §8).
function respond(bool $ok, string $message, $data = null, int $code = 200, array $error = []): void {
  http_response_code($code);
  $out = ["success" => $ok, "message" => $message, "data" => $data];
  if (!$ok) {
    $out["error"] = [
      "code" => $error["code"] ?? ($code === 422 ? "VALIDATION_ERROR" : ($code === 401 ? "UNAUTHORIZED" : ($code === 403 ? "FORBIDDEN" : ($code === 404 ? "NOT_FOUND" : ($code === 409 ? "CONFLICT" : "REQUEST_FAILED"))))),
      "fields" => $error["fields"] ?? new stdClass(),
    ];
  }
  echo json_encode($out, JSON_UNESCAPED_UNICODE);
  exit;
}

function fail_safe(string $userMessage, int $code = 500, string $logDetail = ""): void {
  if ($logDetail !== "") error_log("[koperasi_siswa] $logDetail");
  $isProd = (getenv('APP_ENV') ?: '') === 'prod';
  respond(false, $userMessage, null, $code);
}
