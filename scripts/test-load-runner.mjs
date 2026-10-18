#!/usr/bin/env node

/**
 * test-load-runner.mjs
 * Motor nativo de carga concurrente y análisis estadístico determinista (Node.js v24)
 * Para pruebas de rendimiento, resiliencia y telemetría de caché en Lab 03.
 */

import { performance } from 'node:perf_hooks';

function parseArgs() {
  const args = process.argv.slice(2);
  const options = {
    url: '',
    method: 'GET',
    headers: {},
    body: null,
    requests: 100,
    concurrency: 10,
    output: 'table'
  };

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    if (arg.startsWith('--url=')) {
      options.url = arg.substring(6);
    } else if (arg === '--url' && i + 1 < args.length) {
      options.url = args[++i];
    } else if (arg.startsWith('--method=')) {
      options.method = arg.substring(9).toUpperCase();
    } else if (arg === '--method' && i + 1 < args.length) {
      options.method = args[++i].toUpperCase();
    } else if (arg.startsWith('--headers=')) {
      options.headers = parseJsonSafe(arg.substring(10));
    } else if (arg === '--headers' && i + 1 < args.length) {
      options.headers = parseJsonSafe(args[++i]);
    } else if (arg.startsWith('--token=')) {
      options.headers['Authorization'] = `Bearer ${arg.substring(8)}`;
    } else if (arg === '--token' && i + 1 < args.length) {
      options.headers['Authorization'] = `Bearer ${args[++i]}`;
    } else if (arg.startsWith('--header=')) {
      const parts = arg.substring(9).split(':');
      if (parts.length >= 2) {
        options.headers[parts[0].trim()] = parts.slice(1).join(':').trim();
      }
    } else if (arg === '--header' && i + 1 < args.length) {
      const parts = args[++i].split(':');
      if (parts.length >= 2) {
        options.headers[parts[0].trim()] = parts.slice(1).join(':').trim();
      }
    } else if (arg.startsWith('--body=')) {
      options.body = arg.substring(7);
    } else if (arg === '--body' && i + 1 < args.length) {
      options.body = args[++i];
    } else if (arg.startsWith('--body-base64=')) {
      options.body = Buffer.from(arg.substring(14), 'base64').toString('utf8');
    } else if (arg === '--body-base64' && i + 1 < args.length) {
      options.body = Buffer.from(args[++i], 'base64').toString('utf8');
    } else if (arg.startsWith('--requests=')) {
      options.requests = parseInt(arg.substring(11), 10);
    } else if (arg === '--requests' && i + 1 < args.length) {
      options.requests = parseInt(args[++i], 10);
    } else if (arg.startsWith('--concurrency=')) {
      options.concurrency = parseInt(arg.substring(14), 10);
    } else if (arg === '--concurrency' && i + 1 < args.length) {
      options.concurrency = parseInt(args[++i], 10);
    } else if (arg.startsWith('--output=')) {
      options.output = arg.substring(9).toLowerCase();
    } else if (arg === '--output' && i + 1 < args.length) {
      options.output = args[++i].toLowerCase();
    }
  }

  if (!options.url) {
    console.error('Error: El parámetro --url es obligatorio.');
    process.exit(1);
  }

  if (isNaN(options.requests) || options.requests <= 0) {
    options.requests = 100;
  }
  if (isNaN(options.concurrency) || options.concurrency <= 0) {
    options.concurrency = 10;
  }
  if (options.concurrency > options.requests) {
    options.concurrency = options.requests;
  }

  return options;
}

function parseJsonSafe(str) {
  try {
    return JSON.parse(str);
  } catch {
    // Si viene con comillas escapadas desde PowerShell
    try {
      const sanitized = str.replace(/^['"]|['"]$/g, '').replace(/""/g, '"');
      return JSON.parse(sanitized);
    } catch {
      return {};
    }
  }
}

function getPercentile(sortedArr, p) {
  if (sortedArr.length === 0) return 0;
  const idx = Math.ceil((p / 100) * sortedArr.length) - 1;
  const safeIdx = Math.max(0, Math.min(idx, sortedArr.length - 1));
  return sortedArr[safeIdx];
}

async function runLoadTest(options) {
  const { url, method, headers, body, requests, concurrency } = options;

  let requestIndex = 0;
  const results = [];

  const fetchOptions = {
    method,
    headers: {
      ...headers
    }
  };

  if (body && (method === 'POST' || method === 'PUT' || method === 'PATCH')) {
    fetchOptions.body = typeof body === 'string' ? body : JSON.stringify(body);
    if (!fetchOptions.headers['Content-Type'] && !fetchOptions.headers['content-type']) {
      fetchOptions.headers['Content-Type'] = 'application/json';
    }
  }

  const testStartTime = performance.now();

  async function worker() {
    while (true) {
      let currentIdx;
      // Adquisición secuencial atómica por índice
      if (requestIndex >= requests) {
        break;
      }
      currentIdx = requestIndex++;

      const reqStart = performance.now();
      try {
        const response = await fetch(url, fetchOptions);
        const reqDuration = performance.now() - reqStart;

        // Consumir el body para liberar conexiones
        await response.arrayBuffer();

        const xCache = (response.headers.get('x-cache') || '').toUpperCase();
        const correlationId = response.headers.get('x-correlation-id') || '';

        results.push({
          index: currentIdx,
          status: response.status,
          duration: reqDuration,
          cache: xCache,
          correlationId,
          error: null
        });
      } catch (err) {
        const reqDuration = performance.now() - reqStart;
        results.push({
          index: currentIdx,
          status: 0,
          duration: reqDuration,
          cache: '',
          correlationId: '',
          error: err.message
        });
      }
    }
  }

  // Desplegar workers concurrentes
  const workers = Array.from({ length: concurrency }, () => worker());
  await Promise.all(workers);

  const testEndTime = performance.now();
  const totalDurationSec = (testEndTime - testStartTime) / 1000;

  // Cálculos estadísticos
  const durations = results.map(r => r.duration).sort((a, b) => a - b);
  const total = results.length;
  const statusCodes = {};
  let successCount = 0;
  let cacheHits = 0;
  let cacheMisses = 0;

  for (const r of results) {
    statusCodes[r.status] = (statusCodes[r.status] || 0) + 1;
    if (r.status >= 200 && r.status < 300) {
      successCount++;
    }
    if (r.cache === 'HIT') {
      cacheHits++;
    } else if (r.cache === 'MISS') {
      cacheMisses++;
    }
  }

  const failedCount = total - successCount;
  const rps = totalDurationSec > 0 ? total / totalDurationSec : 0;
  const sumDuration = durations.reduce((acc, d) => acc + d, 0);
  const mean = total > 0 ? sumDuration / total : 0;

  const min = durations[0] || 0;
  const max = durations[durations.length - 1] || 0;
  const p50 = getPercentile(durations, 50);
  const p90 = getPercentile(durations, 90);
  const p95 = getPercentile(durations, 95);
  const p99 = getPercentile(durations, 99);

  const cacheTracked = cacheHits + cacheMisses;
  const cacheHitRatio = cacheTracked > 0 ? (cacheHits / cacheTracked) * 100 : (cacheHits / total) * 100;

  return {
    targetUrl: url,
    method,
    concurrency,
    totalRequests: total,
    successfulRequests: successCount,
    failedRequests: failedCount,
    durationSeconds: parseFloat(totalDurationSec.toFixed(3)),
    throughputRps: parseFloat(rps.toFixed(2)),
    statusCodes,
    latenciesMs: {
      min: parseFloat(min.toFixed(2)),
      mean: parseFloat(mean.toFixed(2)),
      p50: parseFloat(p50.toFixed(2)),
      p90: parseFloat(p90.toFixed(2)),
      p95: parseFloat(p95.toFixed(2)),
      p99: parseFloat(p99.toFixed(2)),
      max: parseFloat(max.toFixed(2))
    },
    cache: {
      hits: cacheHits,
      misses: cacheMisses,
      hitRatioPercent: parseFloat(cacheHitRatio.toFixed(2))
    }
  };
}

async function main() {
  const options = parseArgs();
  const metrics = await runLoadTest(options);

  if (options.output === 'json') {
    console.log(JSON.stringify(metrics, null, 2));
    return;
  }

  // Salida en tabla estilizada para consola
  console.log('='.repeat(70));
  console.log(` BENCHMARK REPORT: ${metrics.method} ${metrics.targetUrl}`);
  console.log('='.repeat(70));
  console.log(` Concurrencia       : ${metrics.concurrency} workers concurrentes`);
  console.log(` Total Peticiones   : ${metrics.totalRequests}`);
  console.log(` Exitosas (2xx)     : ${metrics.successfulRequests} (${((metrics.successfulRequests / metrics.totalRequests) * 100).toFixed(1)}%)`);
  console.log(` Fallidas           : ${metrics.failedRequests}`);
  console.log(` Duración Total     : ${metrics.durationSeconds} s`);
  console.log(` Throughput         : ${metrics.throughputRps} req/s`);
  console.log('-'.repeat(70));
  console.log(' DISTRIBUCIÓN DE LATENCIAS (ms):');
  console.log(`   Mínima           : ${metrics.latenciesMs.min} ms`);
  console.log(`   Media            : ${metrics.latenciesMs.mean} ms`);
  console.log(`   Mediana (p50)    : ${metrics.latenciesMs.p50} ms`);
  console.log(`   Percentil 90     : ${metrics.latenciesMs.p90} ms`);
  console.log(`   Percentil 95     : ${metrics.latenciesMs.p95} ms`);
  console.log(`   Percentil 99     : ${metrics.latenciesMs.p99} ms`);
  console.log(`   Máxima           : ${metrics.latenciesMs.max} ms`);
  console.log('-'.repeat(70));
  console.log(' DESGLOSE CÓDIGOS HTTP:');
  for (const [code, count] of Object.entries(metrics.statusCodes)) {
    console.log(`   HTTP ${code.padEnd(6)}: ${count} reqs`);
  }
  if (metrics.cache.hits > 0 || metrics.cache.misses > 0) {
    console.log('-'.repeat(70));
    console.log(' TELEMETRÍA DE CACHÉ (X-Cache):');
    console.log(`   Cache HITs       : ${metrics.cache.hits}`);
    console.log(`   Cache MISSes     : ${metrics.cache.misses}`);
    console.log(`   Hit Ratio        : ${metrics.cache.hitRatioPercent}%`);
  }
  console.log('='.repeat(70));
}

main().catch(err => {
  console.error('Fallo no controlado en test-load-runner:', err);
  process.exit(1);
});
