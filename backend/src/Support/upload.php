<?php
// Secure upload helper — SECURITY.md §4, ARCHITECTURE.md §9.
// - whitelist extension + real MIME via finfo
// - size limit 5MB
// - server-generated random filename, mkdir 0755
function save_upload(array $file, string $dir, string $prefix, array $allowedExt = ['jpg','jpeg','png','webp']): array {
  if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
    return [null, 'Upload gagal (kode ' . ($file['error'] ?? '?') . ').'];
  }
  if (!is_uploaded_file($file['tmp_name'] ?? '')) return [null, 'File tidak valid.'];
  if (($file['size'] ?? 0) > 5 * 1024 * 1024) return [null, 'Ukuran foto maksimal 5MB.'];

  $ext = strtolower(pathinfo($file['name'] ?? '', PATHINFO_EXTENSION));
  if (!in_array($ext, $allowedExt, true)) {
    return [null, 'Format foto harus jpg, png, atau webp.'];
  }
  // Verify actual MIME — don't trust client extension.
  $finfo = new finfo(FILEINFO_MIME_TYPE);
  $mime = $finfo->file($file['tmp_name']);
  $allowedMime = ['image/jpeg' => ['jpg','jpeg'], 'image/png' => ['png'], 'image/webp' => ['webp']];
  if (!isset($allowedMime[$mime]) || !in_array($ext === 'jpeg' ? 'jpeg' : $ext, array_merge(...array_values($allowedMime)), true)) {
    // Strict: mime must be an image type we allow.
    if (!in_array($mime, array_keys($allowedMime), true)) {
      return [null, 'File bukan gambar yang valid.'];
    }
  }
  if ($ext === 'jpeg') $ext = 'jpg';

  if (!is_dir($dir)) mkdir($dir, 0755, true);
  $name = $prefix . '_' . time() . '_' . bin2hex(random_bytes(6)) . '.' . $ext;
  $dest = rtrim($dir, '/') . '/' . $name;
  if (!move_uploaded_file($file['tmp_name'], $dest)) return [null, 'Gagal menyimpan foto.'];
  return [$name, null];
}
