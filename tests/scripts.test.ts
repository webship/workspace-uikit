import test from 'node:test';
import assert from 'node:assert';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { spawnSync } from 'child_process';

// Compiled, these tests run from dist/tests, so the package root is one folder further up.
const PKG = fs.existsSync(path.join(__dirname, '..', 'package.json')) ? path.join(__dirname, '..') : path.join(__dirname, '..', '..');
const FUNCTIONS = path.join(PKG, 'scripts', 'functions', 'fun-uikit.sh');

// The cucumber.js webship-js scaffolds, as far as the testing hook reads it.
const SCAFFOLD = `module.exports = {
  default: {
    requireModule: ['tsx/cjs'],
    require: [
      'node_modules/webship-js/tests/step-definitions/**/*.js',          // Webship-js core step definitions.
      'tests/step-definitions/**/*.js',                                  // Your custom step definitions.
    ],
    paths: ['tests/features/**/*.feature'],
    worldParameters: {
      launchUrl: process.env.LAUNCH_URL || 'http://localhost:8080',
    },
  },
};
`;

/** A project folder with the testing stack scaffolded, and the tooling folder the installer would have filled. */
function project(kind: 'demo' | 'drupal') {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'uikit-plugin-'));
  const dir = path.join(root, 'dev', 'site1');
  fs.mkdirSync(path.join(dir, '.ddev'), { recursive: true });
  fs.writeFileSync(path.join(dir, '.ddev', 'config.yaml'), `name: site1\ntype: ${kind === 'demo' ? 'php' : 'drupal11'}\ndocroot: ${kind === 'demo' ? 'site' : 'web'}\n`);
  if (kind === 'demo') {
    fs.writeFileSync(path.join(dir, '.ddev', 'config.uikit.yaml'), '# The components demo site of the UIkit step pack.\n');
    fs.mkdirSync(path.join(dir, 'site'), { recursive: true });
    fs.writeFileSync(path.join(dir, 'site', 'index.html'), '<!doctype html>\n');
  }
  fs.writeFileSync(path.join(dir, 'cucumber.js'), SCAFFOLD);
  fs.writeFileSync(path.join(dir, 'package.json'), JSON.stringify({ name: 'site1', devDependencies: { 'webship-js': '^2.0.16' } }, null, 2));
  const scripts = path.join(root, 'core', 'scripts');
  fs.mkdirSync(path.join(scripts, 'plugins', 'uikit'), { recursive: true });
  fs.copyFileSync(path.join(PKG, 'testing', 'site.feature'), path.join(scripts, 'plugins', 'uikit', 'site.feature'));
  return { root, dir, scripts };
}

/** Run bash with the plugin's functions sourced and `ddev` replaced by a recorder. */
function bash(script: string, env: Record<string, string> = {}) {
  const fake = 'ddev() { echo "ddev $*" >> "${DDEV_LOG:-/dev/null}" ; return 0 ; }';
  return spawnSync('bash', ['-c', `${fake}\nsource ${FUNCTIONS}\n${script}`], { encoding: 'utf8', env: { ...process.env, ...env } });
}

test('a static site has no accounts: the list is empty, and adding or removing them says so', () => {
  let r = bash('set_uikit_users ; echo "${#users[@]}"');
  assert.strictEqual(r.status, 0, r.stderr);
  assert.strictEqual(r.stdout.trim(), '0');
  r = bash('add_uikit_users ; cancel_uikit_users');
  assert.strictEqual(r.status, 0, r.stderr);
  assert.match(r.stdout, /no accounts, so there are none to add/);
  assert.match(r.stdout, /no accounts, so there are none to remove/);
});

test('the testing hook adds the step pack and a first feature to a demo site, once', () => {
  const p = project('demo');
  const run = () => bash(`cd ${p.dir} && testing_configure_uikit ${p.dir}`, { WORKSPACE_ROOT: p.root, WORKSPACE_SCRIPTS: p.scripts, doc_name: 'dev', PROJECT_NAME: 'site1' });
  const r = run();
  assert.strictEqual(r.status, 0, r.stderr + r.stdout);
  const pkg = JSON.parse(fs.readFileSync(path.join(p.dir, 'package.json'), 'utf8'));
  assert.strictEqual(pkg.devDependencies['@webship-js/uikit-steps'], '^2.0.0');
  assert.strictEqual(pkg.devDependencies['webship-js'], '^2.0.16', 'what was there stays');
  const cucumber = fs.readFileSync(path.join(p.dir, 'cucumber.js'), 'utf8');
  const lines = cucumber.split('\n');
  const core = lines.findIndex((l) => l.includes('node_modules/webship-js/tests/step-definitions'));
  assert.strictEqual(lines[core + 1], "      'node_modules/@webship-js/uikit-steps/tests/step-definitions/*.js',", 'the pack is listed right after webship-js');
  assert.doesNotMatch(cucumber, /tags:/, 'the pack has no version lanes: the tags stay as the project set them');
  const loaded = spawnSync(process.execPath, ['-e', `const c = require(${JSON.stringify(path.join(p.dir, 'cucumber.js'))}).default; console.log(JSON.stringify([c.require.length, c.paths]))`], { encoding: 'utf8' });
  assert.strictEqual(loaded.status, 0, loaded.stderr);
  assert.deepStrictEqual(JSON.parse(loaded.stdout), [3, ['tests/features/**/*.feature']]);
  assert.ok(fs.existsSync(path.join(p.dir, 'tests', 'features', 'site.feature')));
  // Again, after a person changed the feature: nothing is doubled, nothing is reset.
  fs.writeFileSync(path.join(p.dir, 'tests', 'features', 'site.feature'), 'Feature: mine\n');
  const again = run();
  assert.strictEqual(again.status, 0);
  assert.doesNotMatch(again.stdout, /package\.json:|cucumber\.js:|tests\/features\/site\.feature:/, 'a second run adds nothing');
  assert.strictEqual(fs.readFileSync(path.join(p.dir, 'cucumber.js'), 'utf8'), cucumber);
  assert.strictEqual(fs.readFileSync(path.join(p.dir, 'tests', 'features', 'site.feature'), 'utf8'), 'Feature: mine\n');
});

test('the testing hook waits for the testing stack: without cucumber.js it says to run the setup again', () => {
  const p = project('demo');
  fs.rmSync(path.join(p.dir, 'cucumber.js'));
  const r = bash(`cd ${p.dir} && testing_configure_uikit ${p.dir}`, { WORKSPACE_ROOT: p.root, WORKSPACE_SCRIPTS: p.scripts, doc_name: 'dev', PROJECT_NAME: 'site1' });
  assert.strictEqual(r.status, 1);
  assert.match(r.stdout, /cucumber\.js is not here yet/);
});

test('the testing hook leaves any other project alone: the core\'s --add-steps gives it the pack', () => {
  const p = project('drupal');
  const r = bash(`cd ${p.dir} && testing_configure_uikit ${p.dir}`, { WORKSPACE_ROOT: p.root, WORKSPACE_SCRIPTS: p.scripts, doc_name: 'dev', PROJECT_NAME: 'site1' });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stdout, '');
  assert.strictEqual(fs.readFileSync(path.join(p.dir, 'cucumber.js'), 'utf8'), SCAFFOLD);
  assert.ok(!fs.existsSync(path.join(p.dir, 'tests')));
});

test('the build takes the demo site from the step pack, serves it as it is, and has no database', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'uikit-build-'));
  fs.mkdirSync(path.join(root, 'dev'), { recursive: true });
  const log = path.join(root, 'ddev.log');
  // The recorder also stands in for the copy of the pages (the demo site's own .ddev/ comes with them),
  // so the build finds them where they go.
  const script = [
    'trim_project_name() { :; } ; drop_database() { :; } ; ddev_up() { ddev "$@" ; } ; ddev_nodejs_version() { echo 24 ; }',
    `ddev() { echo "ddev $*" >> ${log} ; case "$*" in *"cp -a"*) mkdir -p ${root}/dev/site1/site/.ddev && touch ${root}/dev/site1/site/index.html ${root}/dev/site1/site/modal.html ${root}/dev/site1/site/.ddev/config.yaml ;; esac ; return 0 ; }`,
    'PROJECT_NAME=site1 ; INSTALL=no ; SOURCE=https://example.com/pack.git ; REF=2.0.x',
    'uikit_build',
  ].join('\n');
  const r = spawnSync('bash', ['-c', `source ${FUNCTIONS}\n${script}`], { encoding: 'utf8', env: { ...process.env, WORKSPACE_ROOT: root, doc_name: 'dev' } });
  assert.strictEqual(r.status, 0, r.stderr + r.stdout);
  const calls = fs.readFileSync(log, 'utf8');
  assert.match(calls, /ddev config --project-type=php --docroot=site --project-name=site1 --omit-containers=db --nodejs-version=24/);
  assert.match(calls, /git clone --quiet --depth 1 --branch '2\.0\.x' 'https:\/\/example\.com\/pack\.git'/);
  assert.match(calls, /cp -a \/tmp\/components-demo\/demo-site\/\. \/var\/www\/html\/site\//);
  assert.match(calls, /^ddev stop$/m, 'without --install the site is ready and stopped');
  assert.match(r.stdout, /dev site1 is ready: the components demo site\./);
  assert.match(fs.readFileSync(path.join(root, 'dev', 'site1', '.ddev', 'config.uikit.yaml'), 'utf8'), /^# source: https:\/\/example\.com\/pack\.git \(2\.0\.x\)$/m);
  assert.ok(fs.existsSync(path.join(root, 'dev', 'site1', 'site', 'index.html')), 'the pages are served from site/');
  assert.ok(!fs.existsSync(path.join(root, 'dev', 'site1', 'site', '.ddev')), 'the demo site\'s own DDEV project is not left in the docroot');
});

/** A build of site1 in a fresh workspace folder, with `ddev` and the core's helpers recorded; `layer` stands for the
 * core's runtime layer (fun-runtime.sh), as far as the builder asks it. */
function build(opts: { layer?: string; env?: Record<string, string> } = {}) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'uikit-build-'));
  fs.mkdirSync(path.join(root, 'dev'), { recursive: true });
  const log = path.join(root, 'ddev.log');
  const script = [
    'trim_project_name() { :; } ; drop_database() { :; } ; ddev_up() { ddev "$@" ; } ; ddev_nodejs_version() { echo 24 ; }',
    `ddev() { echo "ddev $*" >> ${log} ; case "$*" in *"cp -a"*) mkdir -p ${root}/dev/site1/site && touch ${root}/dev/site1/site/index.html ;; esac ; return 0 ; }`,
    opts.layer || '',
    'PROJECT_NAME=site1 ; SOURCE=https://example.com/pack.git ; REF=2.0.x',
    'uikit_build',
  ].join('\n');
  const r = spawnSync('bash', ['-c', `source ${FUNCTIONS}\n${script}`], { encoding: 'utf8', env: { ...process.env, WORKSPACE_ROOT: root, doc_name: 'dev', INSTALL: 'yes', ...(opts.env || {}) } });
  const calls = fs.existsSync(log) ? fs.readFileSync(log, 'utf8') : '';
  return { r, calls, root, log };
}

/** The core's runtime layer, as far as the builder asks it: the runtime of a new build, the address, the claim. */
const layer = (rt: string, url: string) => [
  `runtime_of() { echo ${rt} ; }`,
  `rt_url() { echo ${url} ; }`,
  'rt_claim() { echo "rt_claim $*" >> "$WORKSPACE_ROOT/ddev.log" ; }',
].join(' ; ');

test('on DDEV the build runs the same commands with the runtime layer as without it', () => {
  const without = build();
  const withLayer = build({ layer: layer('ddev', 'https://site1.ddev.site') });
  for (const b of [without, withLayer]) {
    assert.strictEqual(b.r.status, 0, b.r.stderr + b.r.stdout);
    assert.ok(fs.existsSync(path.join(b.root, 'dev', 'site1', '.ddev', 'config.uikit.yaml')), 'DDEV\'s own file marks the project');
    assert.doesNotMatch(b.calls, /rt_claim/, 'nothing is claimed on DDEV');
    assert.match(b.r.stdout, /Go to https:\/\/site1\.ddev\.site$/m);
  }
  assert.strictEqual(withLayer.calls, without.calls, 'the same ddev commands, to the letter');
});

for (const [rt, url] of [['docker', 'http://127.0.0.1:43210'], ['podman', 'http://127.0.0.1:43211'], ['kubernetes', 'http://172.18.0.2:30080']]) {
  test(`on ${rt} the project is claimed and the site answers at the runtime's address, never a ddev.site`, () => {
    const b = build({ layer: layer(rt, url), env: { RUNTIME: rt } });
    assert.strictEqual(b.r.status, 0, b.r.stderr + b.r.stdout);
    assert.match(b.calls, /^rt_claim uikit$/m, 'the x-webship block says the project is a demo site of this builder');
    assert.ok(!fs.existsSync(path.join(b.root, 'dev', 'site1', '.ddev')), 'no .ddev folder: it would make the project a DDEV one');
    assert.match(b.calls, /ddev config --project-type=php --docroot=site --project-name=site1 --omit-containers=db --nodejs-version=24/, 'the php stack without a database');
    assert.ok(b.calls.indexOf('ddev config') < b.calls.indexOf('rt_claim uikit'), 'the claim comes after the runtime\'s files are written');
    assert.match(b.r.stdout, new RegExp(`^Go to ${url.replace(/[.:/]/g, '\\$&')}$`, 'm'));
    assert.doesNotMatch(b.r.stdout, /ddev\.site/, 'no message names a DDEV address');
  });
}

test('--runtime on a core without the runtime layer is refused, and nothing is started', () => {
  const b = build({ env: { RUNTIME: 'docker' } });
  assert.strictEqual(b.r.status, 1);
  assert.match(b.r.stdout, /--runtime docker needs a Webship Workspace with the container runtimes \(webship\/workspace#694\)/);
  assert.strictEqual(b.calls, '', 'no ddev command ran');
  assert.ok(!fs.existsSync(path.join(b.root, 'dev', 'site1')), 'no project folder was made');
});

test('a runtime this builder is not proven on (the workspace\'s setting) stops the build before anything is made', () => {
  const b = build({ layer: layer('lando', 'http://127.0.0.1:43212') });
  assert.strictEqual(b.r.status, 1);
  assert.match(b.r.stdout, /builds on ddev, docker, podman or kubernetes, not on lando yet/);
  assert.strictEqual(b.calls, '', 'no ddev command ran');
  assert.ok(!fs.existsSync(path.join(b.root, 'dev', 'site1')), 'no project folder was made');
});

test('a project of the builder is known by the core\'s rt_is_platform where the core has it, else by DDEV\'s file', () => {
  let r = bash('rt_is_platform() { echo "asked $*" ; return 0 ; } ; uikit_is_project /x/site1');
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stdout.trim(), 'asked /x/site1 uikit');
  r = bash('rt_is_platform() { return 1 ; } ; uikit_is_project /x/site1');
  assert.strictEqual(r.status, 1);
  const p = project('demo');
  r = bash(`uikit_is_project ${p.dir}`);
  assert.strictEqual(r.status, 0, 'without the layer, .ddev/config.uikit.yaml says so');
  fs.rmSync(path.join(p.dir, '.ddev', 'config.uikit.yaml'));
  assert.strictEqual(bash(`uikit_is_project ${p.dir}`).status, 1);
});

test('the builder takes the runtimes it is proven on, and says what each one gives', () => {
  const args = fs.readFileSync(path.join(PKG, 'scripts', 'args', 'arg-uikit.sh'), 'utf8');
  assert.match(args, /choices=\['ddev', 'docker', 'podman', 'kubernetes'\]/);
  assert.match(args, /dest='RUNTIME',\n\s+default="_none_"/);
  assert.match(fs.readFileSync(path.join(PKG, 'scripts', 'functions', 'fun-uikit.sh'), 'utf8'), /^readonly UIKIT_RUNTIMES='ddev docker podman kubernetes';$/m);
});

test('a source without a demo site stops the build with a message', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'uikit-build-'));
  fs.mkdirSync(path.join(root, 'dev'), { recursive: true });
  const script = [
    'trim_project_name() { :; } ; drop_database() { :; } ; ddev_up() { ddev "$@" ; } ; ddev_nodejs_version() { echo 24 ; }',
    'ddev() { case "$*" in *"cp -a"*) return 1 ;; esac ; return 0 ; }',
    'PROJECT_NAME=site1 ; INSTALL=no ; SOURCE=https://example.com/other.git ; REF=main',
    'uikit_build',
  ].join('\n');
  const r = spawnSync('bash', ['-c', `source ${FUNCTIONS}\n${script}`], { encoding: 'utf8', env: { ...process.env, WORKSPACE_ROOT: root, doc_name: 'dev' } });
  assert.strictEqual(r.status, 1);
  assert.match(r.stdout, /https:\/\/example\.com\/other\.git has no demo-site\/ folder with an index\.html\./);
});

test('the first feature names no library or platform in a step', () => {
  const feature = fs.readFileSync(path.join(PKG, 'testing', 'site.feature'), 'utf8');
  const steps = feature.split('\n').filter((l) => /^\s*(Given|When|Then|And|But) /.test(l));
  assert.ok(steps.length >= 15);
  for (const s of steps) assert.doesNotMatch(s, /uikit|drupal|wordpress|joomla/i, s);
});
