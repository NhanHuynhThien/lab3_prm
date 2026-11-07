const { contextBridge, ipcRenderer } = require("electron");
const invoke = (action, value) =>
  ipcRenderer.invoke("companion:action", action, value);
contextBridge.exposeInMainWorld("companion", {
  status: () => invoke("status"),
  connect: (value) => invoke("connect", value),
  sync: () => invoke("sync"),
  syncInterval: (milliseconds) => invoke("sync-interval", milliseconds),
  pause: () => invoke("pause"),
  resume: () => invoke("resume"),
  disconnect: () => invoke("disconnect"),
  autoStart: (value) => invoke("auto-start", value),
  onChange: (listener) => {
    const receive = (_event, value) => listener(value);
    ipcRenderer.on("companion:state", receive);
    return () => ipcRenderer.removeListener("companion:state", receive);
  },
});
