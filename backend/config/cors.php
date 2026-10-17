<?php
require_once __DIR__ . '/env.php';
function cors($methods=["GET","POST","PUT","DELETE","OPTIONS"]){
  header("Content-Type: application/json");
  // SECURITY.md §5: restrict origins in production via ALLOWED_ORIGIN env.
  $origin = env_str('ALLOWED_ORIGIN', '*');
  header("Access-Control-Allow-Origin: $origin");
  header("Access-Control-Allow-Methods: ".implode(", ",$methods));
  header("Access-Control-Allow-Headers: Content-Type, Authorization");
  if(($_SERVER['REQUEST_METHOD']??'')==='OPTIONS'){ http_response_code(200); exit; }
}
