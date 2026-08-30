const express = require("express");

const app = express();
const port = process.env.PORT || 3000;

// Build metadata baked in at image build time (see Dockerfile ARG/ENV) so a
// smoke test can confirm it actually hit the NEW revision after a deploy,
// not a stale cached one — this is what deploy.yml's smoke-test step checks.
const buildInfo = {
  version: process.env.BUILD_VERSION || "dev",
  commitSha: process.env.BUILD_COMMIT_SHA || "unknown",
};

app.get("/", (req, res) => {
  res.json({ message: "cicd-best-practices-container-apps", ...buildInfo });
});

app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok" });
});

if (require.main === module) {
  app.listen(port, () => {
    console.log(`listening on port ${port}`);
  });
}

module.exports = app;
