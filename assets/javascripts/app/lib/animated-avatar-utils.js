// Maps the extension of the raw upload URL (stored in animated_avatar) to the
// animated route extension used in avatar URLs.
// GIF and WebP keep their extension; APNG is stored as .png but served as .apng.
const ANIMATED_EXT = { gif: "gif", webp: "webp", png: "apng" };

export function animatedExtension(animatedAvatarUrl) {
  const ext = animatedAvatarUrl?.match(/\.(\w+)(?:[?#]|$)/)?.[1];
  return ANIMATED_EXT[ext] ?? null;
}
