// Maps the extension of the raw upload URL (stored in animated_avatar) to the
// animated route extension used in avatar URLs.
const ANIMATED_EXT = { gif: "gif", webp: "webp" };

export function animatedExtension(animatedAvatarUrl) {
  const ext = animatedAvatarUrl?.match(/\.(\w+)(?:[?#]|$)/)?.[1];
  return ANIMATED_EXT[ext] ?? null;
}
