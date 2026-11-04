// Test de charge avec seuils, pour la chaîne CI/CD (étape "Test de charge").
// Même outil que le Script-2 du sujet (loadtest), utilisé comme bibliothèque pour pouvoir
// FAIRE ÉCHOUER le pipeline si les performances se dégradent.
//
// Usage : node load-test-ci.mjs <URL>
// Variables : DURATION (s, 30), RPS (200), CONCURRENCY (50),
//             MAX_ERROR_RATE (%, 0.5), MAX_P95_MS (500)

import { loadTest } from "loadtest";

const url = process.argv[2];
if (!url) {
  console.error("Usage : node load-test-ci.mjs <URL>");
  process.exit(2);
}

const cfg = {
  duration: Number(process.env.DURATION ?? 30),
  rps: Number(process.env.RPS ?? 200),
  concurrency: Number(process.env.CONCURRENCY ?? 50),
  maxErrorRate: Number(process.env.MAX_ERROR_RATE ?? 0.5),
  maxP95: Number(process.env.MAX_P95_MS ?? 500),
};

console.log(`Test de charge : ${cfg.rps} req/s, ${cfg.concurrency} clients, ${cfg.duration} s sur ${url}`);

const result = await loadTest({
  url,
  maxSeconds: cfg.duration,
  requestsPerSecond: cfg.rps,
  concurrency: cfg.concurrency,
  agentKeepAlive: true,
  quiet: true,
});

const total = result.totalRequests;
const errors = result.totalErrors;
const errorRate = total > 0 ? (100 * errors) / total : 100;
const p95 = result.percentiles?.["95"] ?? Infinity;

const lines = [
  `| Mesure | Valeur | Seuil |`,
  `|---|---|---|`,
  `| Requêtes | ${total} | |`,
  `| Débit effectif | ${Math.round(result.effectiveRps)} req/s | |`,
  `| Erreurs | ${errors} (${errorRate.toFixed(2)} %) | ≤ ${cfg.maxErrorRate} % |`,
  `| Latence moyenne | ${result.meanLatencyMs.toFixed(1)} ms | |`,
  `| Latence p50 / p95 / p99 | ${result.percentiles["50"]} / ${p95} / ${result.percentiles["99"]} ms | p95 ≤ ${cfg.maxP95} ms |`,
];
console.log(lines.join("\n"));

// Résumé affiché dans l'onglet "Summary" de GitHub Actions
if (process.env.GITHUB_STEP_SUMMARY) {
  const { appendFileSync } = await import("node:fs");
  appendFileSync(process.env.GITHUB_STEP_SUMMARY, `### Test de charge\n\n${lines.join("\n")}\n`);
}

const failures = [];
if (errorRate > cfg.maxErrorRate) failures.push(`taux d'erreur ${errorRate.toFixed(2)} % > ${cfg.maxErrorRate} %`);
if (p95 > cfg.maxP95) failures.push(`latence p95 ${p95} ms > ${cfg.maxP95} ms`);
if (total === 0) failures.push("aucune requête aboutie");

if (failures.length) {
  console.error(`ÉCHEC du test de charge : ${failures.join(", ")}`);
  process.exit(1);
}
console.log("Test de charge réussi : seuils respectés.");
