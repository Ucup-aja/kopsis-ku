<?php
// Shared validation helpers — SECURITY.md §3.
function v_required($v): bool { return isset($v) && trim((string)$v) !== ''; }
function v_in($v, array $allowed): bool { return in_array($v, $allowed, true); }
function v_non_negative_num($v): bool { return is_numeric($v) && ((float)$v) >= 0; }
function v_positive_int($v): bool {
  if (!is_numeric($v)) return false;
  $i = (int)$v;
  return $i > 0 && ((float)$v) == ((float)$i);
}
function v_date_ymd(?string $v): bool {
  if ($v === null || $v === '') return true; // optional
  $d = DateTime::createFromFormat('Y-m-d', $v);
  return $d && $d->format('Y-m-d') === $v;
}
