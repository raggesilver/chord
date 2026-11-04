// Content script (all frames). Finds the best video and toggles Picture in Picture.
(() => {
  const api = typeof browser !== "undefined" ? browser : chrome;

  function area(v) {
    const r = v.getBoundingClientRect();
    const w = Math.max(0, Math.min(r.right, innerWidth) - Math.max(r.left, 0));
    const h = Math.max(0, Math.min(r.bottom, innerHeight) - Math.max(r.top, 0));
    return w * h;
  }
  function isPlaying(v) {
    return !v.paused && !v.ended && v.readyState > 2;
  }
  function pipSupported(v) {
    // Don't trust disablePictureInPicture: Safari's own menu can still PiP those via the WebKit API.
    return typeof v.webkitSetPresentationMode === "function" ||
      (!v.disablePictureInPicture && document.pictureInPictureEnabled !== false && "requestPictureInPicture" in v);
  }
  function inPiP(v) {
    if (v.webkitPresentationMode === "picture-in-picture" || document.pictureInPictureElement === v) return true;
    // For a video inside a shadow root, the standard API reports the shadow host.
    const root = v.getRootNode && v.getRootNode();
    return !!(root && root.host && document.pictureInPictureElement === root.host);
  }

  // Collect <video> elements, including those inside open shadow roots (e.g. Disney+).
  function allVideos(root = document, out = []) {
    root.querySelectorAll("video").forEach(v => out.push(v));
    for (const el of root.querySelectorAll("*")) {
      if (el.shadowRoot) allVideos(el.shadowRoot, out);
    }
    return out;
  }

  function findVideo() {
    const videos = allVideos().filter(v => v.readyState > 0 || v.currentSrc || v.src);
    const active = videos.find(inPiP);
    if (active) return active; // always prefer exiting the one already in PiP
    const ok = videos.filter(pipSupported);
    const visible = ok.filter(v => area(v) > 0);
    const playing = visible.filter(isPlaying).sort((a, b) => area(b) - area(a));
    if (playing[0]) return playing[0];
    if (visible.length) return visible.sort((a, b) => area(b) - area(a))[0];
    // Fall back to playing-but-offscreen video, then anything.
    return ok.find(isPlaying) || ok[0] || null;
  }

  async function toggle(v) {
    if (inPiP(v)) {
      if (document.pictureInPictureElement && document.exitPictureInPicture) await document.exitPictureInPicture();
      else v.webkitSetPresentationMode("inline");
      return;
    }
    const preferWebkit = v.disablePictureInPicture || typeof v.requestPictureInPicture !== "function";
    if (preferWebkit && typeof v.webkitSetPresentationMode === "function") v.webkitSetPresentationMode("picture-in-picture");
    else await v.requestPictureInPicture();
  }

  // Attempt PiP; if the browser refuses for lack of a user gesture, arm a one-shot retry.
  let armed = false;
  async function attempt(fromGesture) {
    const v = findVideo();
    if (!v) return { status: "no-video" };
    try {
      await toggle(v);
      armed = false;
      return { status: "ok" };
    } catch (e) {
      if (e && e.name === "NotAllowedError" && !fromGesture) {
        armed = true; // next real keypress/click will retry inside a genuine gesture
        return { status: "armed" };
      }
      console.warn("[pip-ext] PiP failed:", e);
      return { status: "error", error: String(e) };
    }
  }

  // Fallback path: a trusted keydown/click is a real user gesture.
  addEventListener("keydown", (e) => {
    if (!e.isTrusted) return;
    const isShortcut = e.metaKey && e.shiftKey && !e.altKey && !e.ctrlKey && e.code === "KeyP";
    if (isShortcut || armed) {
      if (isShortcut) e.preventDefault();
      attempt(true);
    }
  }, true);
  addEventListener("pointerup", (e) => { if (armed && e.isTrusted) attempt(true); }, true);

  api.runtime.onMessage.addListener((msg) => {
    if (msg.type === "get-url") {
      return window === top ? Promise.resolve({ url: location.href }) : undefined;
    }
    if (msg.type === "toggle-pip") {
      // Only answer if this frame has a candidate; otherwise let other frames answer.
      if (!findVideo()) return undefined;
      return attempt(false);
    }
  });
})();
