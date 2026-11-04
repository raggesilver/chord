// Background (non-persistent) script: receives keyboard commands and dispatches them.
const api = typeof browser !== "undefined" ? browser : chrome;

async function activeTab() {
  const [tab] = await api.tabs.query({ active: true, currentWindow: true });
  return tab;
}

async function flashBadge(tabId, text, color) {
  try {
    await api.action.setBadgeBackgroundColor({ color });
    await api.action.setBadgeText({ text });
    setTimeout(() => api.action.setBadgeText({ text: "" }), 1500);
  } catch (_) {}
}

async function togglePiP(tab) {
  // Broadcast to every frame; each content script decides if it has a candidate video.
  // The frame with the best candidate answers { handled: true }.
  let result = null;
  try {
    result = await api.tabs.sendMessage(tab.id, { type: "toggle-pip" });
  } catch (e) {
    flashBadge(tab.id, "\u00d7", "#888"); // no content script (e.g. restricted page / access not granted)
    return;
  }
  if (!result || result.status === "no-video") flashBadge(tab.id, "\u2013", "#888");
  else if (result.status === "armed") flashBadge(tab.id, "\u21b5", "#e6a700"); // needs a click/key (see content.js)
  else if (result.status === "error") flashBadge(tab.id, "!", "#c00");
}

async function copyUrl(tab) {
  let url = tab.url;
  if (!url) {
    // tab.url can be hidden without activeTab/tabs; ask the content script instead.
    try { url = (await api.tabs.sendMessage(tab.id, { type: "get-url" })).url; } catch (_) {}
  }
  if (!url) return flashBadge(tab.id, "!", "#c00");
  try {
    // For sendNativeMessage Safari routes to the containing app's extension handler;
    // the application id argument is ignored.
    const res = await api.runtime.sendNativeMessage("application.id", { action: "copy", url });
    // res.toast === true means the app showed its own toast, so skip the badge.
    if (res && res.ok) { if (!res.toast) flashBadge(tab.id, "\u2713", "#2a9d3f"); }
    else flashBadge(tab.id, "!", "#c00");
  } catch (e) {
    console.error("native message failed", e);
    flashBadge(tab.id, "!", "#c00");
  }
}

api.commands.onCommand.addListener(async (command, tabFromEvent) => {
  const tab = tabFromEvent || (await activeTab());
  if (!tab) return;
  if (command === "toggle-pip") togglePiP(tab);
  else if (command === "copy-url") copyUrl(tab);
});

// Clicking the toolbar button opens the container app's window (settings).
api.action.onClicked.addListener(() => {
  api.runtime.sendNativeMessage("application.id", { action: "open-app" }).catch(() => {});
});
