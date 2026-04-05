/**
 * Setup script for the eXist-db site platform.
 *
 * Installs all packages in the correct order and runs the Jinks
 * generator for each app. Installs patched jinks-templates last
 * to prevent dependency overwrites.
 *
 * Usage:
 *   npm run setup                # full setup
 *   npm run setup -- --apps-only # just run generators
 *   npm run setup -- --profile-only # just upload profile
 */
import { execSync } from "node:child_process";
import { readFileSync, existsSync } from "node:fs";
import { resolve, dirname, basename } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const workspace = resolve(__dirname, "..");

// --- Configuration ---

const config = (() => {
  try {
    const json = JSON.parse(readFileSync(resolve(__dirname, ".existdb.json"), "utf-8"));
    const s = json.servers?.localhost;
    return {
      server: s?.server || "http://localhost:8080/exist",
      user: s?.user || "admin",
      password: s?.password || "",
    };
  } catch {
    return { server: "http://localhost:8080/exist", user: "admin", password: "" };
  }
})();

// Strip /exist from server URL for xst (it wants just host:port)
const xstServer = config.server.replace(/\/exist\/?$/, "");

const env = {
  ...process.env,
  EXISTDB_USER: config.user,
  EXISTDB_PASS: config.password,
  EXISTDB_SERVER: xstServer,
};

// XAR locations
const xars = {
  jinks: resolve(workspace, "jinks/build/jinks.xar"),
  jinks_templates: resolve(workspace, "jinks-templates/build/jinks-templates.xar"),
  markdown: resolve(workspace, "exist-markdown/target/exist-markdown-3.0.0.xar"),
  site_shell: resolve(__dirname, "dist/exist-site-shell-0.9.0-SNAPSHOT.xar"),
  dashboard: resolve(workspace, "dashboard-next/dist/dashboard-3.0.0-SNAPSHOT.xar"),
  docs: resolve(workspace, "documentation-next/dist/docs-0.1.0.xar"),
  notebook: resolve(workspace, "sandbox/dist/notebook-1.0.0-SNAPSHOT.xar"),
  blog: resolve(workspace, "wiki-next/dist/blog-0.1.0.xar"),
};

// Nav items (shared by all apps)
const navItems = [
  { abbrev: "dashboard", title: "Dashboard" },
  { abbrev: "docs", title: "Documentation" },
  { abbrev: "notebook", title: "Notebook" },
  { abbrev: "blog", title: "Blog" },
];

// Generator configs for each app
const apps = [
  {
    label: "eXist-db Site Shell",
    id: "http://exist-db.org/pkg/site-shell",
    description: "Sitewide navigation shell",
    abbrev: "exist-site-shell",
    version: "0.9.0-SNAPSHOT",
    extraDeps: [
      { package: "http://tei-publisher.com/library/jinks-templates", semver: "1" },
      { package: "http://exist-db.org/apps/markdown", semver: "3" },
    ],
  },
  {
    label: "Dashboard",
    id: "http://exist-db.org/apps/dashboard",
    description: "Administration dashboard",
    abbrev: "dashboard",
    version: "3.0.0-SNAPSHOT",
  },
  {
    label: "eXist-db Documentation",
    id: "http://exist-db.org/apps/docs",
    description: "Documentation and function reference",
    abbrev: "docs",
    version: "0.1.0",
    extraDeps: [
      { package: "http://tei-publisher.com/library/jinks-templates", semver: "1" },
      { package: "http://existsolutions.com/apps/tei-publisher-lib", semver: "4" },
    ],
  },
  {
    label: "Notebook",
    id: "http://exist-db.org/pkg/notebook",
    description: "Interactive XQuery notebook",
    abbrev: "notebook",
    version: "1.0.0-SNAPSHOT",
  },
  {
    label: "Blog",
    id: "http://exist-db.org/apps/blog",
    description: "eXist-db project blog",
    abbrev: "blog",
    version: "0.1.0",
  },
];

// --- Helpers ---

function xst(...args) {
  try {
    return execSync(`xst ${args.join(" ")}`, { env, encoding: "utf-8", stdio: "pipe" });
  } catch (e) {
    return e.stdout || e.stderr || e.message;
  }
}

function installXar(path, name) {
  if (!existsSync(path)) {
    console.log(`  SKIP ${name} (${basename(path)} not found)`);
    return false;
  }
  console.log(`  Installing ${name}...`);
  const result = xst("package", "install", "-f", path);
  if (result.includes("installed") || result.includes("downgraded")) {
    console.log(`    OK`);
    return true;
  }
  // Fallback: try deploy via XQuery
  console.log(`    xst failed, trying repo:deploy...`);
  xst("execute", `repo:deploy("${name}")`);
  return true;
}

function uploadProfile() {
  console.log("  Uploading exist-site profile...");
  const profileDir = resolve(__dirname, "profile");

  xst("execute",
    'if (not(xmldb:collection-available("/db/apps/jinks/profiles/exist-site"))) then xmldb:create-collection("/db/apps/jinks/profiles", "exist-site") else ()'
  );

  xst("upload", profileDir + "/", "/db/apps/jinks/profiles/exist-site");

  // Fix: re-store .html templates as binary
  xst("execute", `
    let $source := "/db/apps/jinks/profiles/exist-site/templates"
    return
      if (xmldb:collection-available($source)) then
        for $resource in xmldb:get-child-resources($source)
        where ends-with($resource, ".html") and doc-available($source || "/" || $resource)
        let $content := serialize(doc($source || "/" || $resource))
        let $clean := if (starts-with($content, "<?xml")) then substring-after($content, "?>") else $content
        let $_ := xmldb:remove($source, $resource)
        return xmldb:store($source, $resource, $clean, "application/octet-stream")
      else ()
  `);

  console.log("    Profile uploaded");
}

function runGenerator(app) {
  console.log(`  Generating ${app.label}...`);

  const genConfig = {
    config: {
      label: app.label,
      id: app.id,
      description: app.description,
      extends: ["exist-site"],
      pkg: {
        abbrev: app.abbrev,
        version: app.version,
        ...(app.extraDeps ? { dependencies: app.extraDeps } : {}),
      },
      nav: { items: navItems },
    },
  };

  try {
    const result = execSync(
      `curl -s -u ${config.user}:${config.password} -X POST ` +
      `-H "Content-Type: application/json" ` +
      `-d '${JSON.stringify(genConfig).replace(/'/g, "\\'")}' ` +
      `"${xstServer}/exist/apps/jinks/api/generator?overwrite=all"`,
      { encoding: "utf-8", stdio: "pipe" }
    );
    const data = JSON.parse(result);
    if (data.code) {
      console.log(`    ERROR: ${data.code}`);
    } else {
      console.log(`    OK (${data.messages?.length || 0} files)`);
    }
  } catch (e) {
    console.log(`    ERROR: ${e.message}`);
  }
}

// --- Main ---

const mode = process.argv[2] || "full";

if (mode === "--profile-only") {
  uploadProfile();
  process.exit(0);
}

if (mode !== "--apps-only") {
  console.log("=== Installing packages ===\n");

  console.log("Step 1: Dependencies");
  installXar(xars.markdown, "exist-markdown");
  installXar(xars.jinks, "jinks");

  console.log("\nStep 2: Apps");
  installXar(xars.site_shell, "exist-site-shell");
  installXar(xars.dashboard, "dashboard");
  installXar(xars.docs, "docs");
  installXar(xars.notebook, "notebook");
  installXar(xars.blog, "blog");

  console.log("\nStep 3: Patched jinks-templates (MUST be last)");
  installXar(xars.jinks_templates, "jinks-templates");
}

console.log("\n=== Uploading Jinks profile ===\n");
uploadProfile();

console.log("\n=== Running Jinks generator ===\n");
for (const app of apps) {
  runGenerator(app);
}

console.log("\n=== Done ===");
console.log("If any future package install overwrites jinks-templates,");
console.log("re-run: npm run setup -- --apps-only");
