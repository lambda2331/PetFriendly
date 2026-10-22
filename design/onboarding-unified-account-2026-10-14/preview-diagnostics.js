/* Read-only browser review diagnostics; no application data or external reporting. */
addEventListener('error',e=>{document.documentElement.dataset.previewRuntimeError=e.message+' @ '+e.filename+':'+e.lineno});
addEventListener('unhandledrejection',e=>{document.documentElement.dataset.previewRuntimeError=String(e.reason?.message||e.reason)});
