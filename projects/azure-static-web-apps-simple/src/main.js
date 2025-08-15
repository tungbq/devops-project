document.getElementById("ping").addEventListener("click", () => {
    const out = document.getElementById("out");
    out.textContent = `SWA is up! ${new Date().toLocaleString()}`;
  });