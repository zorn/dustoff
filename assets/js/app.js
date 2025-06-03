// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

/**
 * @function renderLocalDatetimes
 * @description
 *   Finds all <time> elements with the attribute 'data-local-datetime' and
 *   replaces their text content with a formatted date string in the user's
 *   local time zone.
 *
 *   The function expects each <time> element to have a 'datetime' attribute
 *   containing an ISO8601 UTC datetime string. The displayed format will be:
 *   'Month D, YYYY h:mm AM/PM TZ', e.g., 'May 5, 2025 4:00 PM EDT'. If
 *   JavaScript is disabled, no substitution will be made. You should default
 *   with a UTC fallback string value
 *
 * @example
 *   // In your HTML/HEEx:
 *   // <time data-local-datetime datetime="2025-05-27T08:00:00.000000Z">
 *   //     2025-05-27T08:00:00.000000Z
 *   // </time>
 *
 *   // In your JS:
 *   // renderLocalDatetimes();
 *
 *   // The updated DOM will be:
 *   // <time data-local-datetime datetime="2025-05-27T08:00:00.000000Z">
 *   //     May 27, 2025 4:00 PM EDT
 *   // </time>
 *
 * @returns {void}
 */
function renderLocalDatetimes() {
  // If this `app.js` file starts to get large, we should move this to a separate
  // file. This is currently not tested as we do not have JavaScript test
  // infrastructure. Be careful when adding new functionality.
  document.querySelectorAll("[data-local-datetime]").forEach((el) => {
    // Get the ISO8601 UTC datetime string from the datetime attribute
    const iso = el.getAttribute("datetime");
    if (!iso) return;
    // Parse the string into a JavaScript Date object
    const dt = new Date(iso);
    if (isNaN(dt)) return;
    // Format: May 5, 2025 4:00 PM EDT
    const opts = {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "numeric",
      minute: "2-digit",
      hour12: true,
      timeZoneName: "short",
    };
    let str = dt.toLocaleString(undefined, opts);
    el.textContent = str;
  });
}

// Render local datetimes when the page loads and when the page is updated.
document.addEventListener("DOMContentLoaded", renderLocalDatetimes);
document.addEventListener("phx:update", renderLocalDatetimes);
