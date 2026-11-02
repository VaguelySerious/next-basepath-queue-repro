# Next.js `basePath` + queue trigger repro

When a Next.js app with `basePath` is built on Vercel with the Next.js adapter, a route handler invoked by a queue trigger fails before any user code runs:

```
Failed to handle /docs/api/consume
Error: Cannot find module './.next/server/pages/docs/api/consume.js'
```

The message is never consumed. Fix: [nextjs/adapter-vercel#151](https://github.com/nextjs/adapter-vercel/pull/151).

## The app

- `next.config.ts`: `basePath: '/docs'`
- `vercel.json`: a `queue/v2beta` trigger on `app/api/consume/route.ts` for topic `repro-jobs`
- `POST /docs/api/send` sends a job to `repro-jobs`
- `app/api/consume/route.ts` (`handleCallback`) handles the job and writes a receipt to a second topic
- `GET /docs/api/result` reads the receipts, so you can see whether the consumer ran

There's no other dependency besides `@vercel/queue`.

## Reproduce

```sh
pnpm install
vercel deploy            # adapter on (the default for Vercel builds)
scripts/check.sh <deployment-url> [--scope <team>]
```

The build log contains `Applying modifyConfig from Vercel`. `check.sh` prints `FAIL`, and the runtime logs show the `MODULE_NOT_FOUND` above on `POST /docs/api/consume`.

## Results

Verified 2026-11-02 with Next.js 16.4.4 and Vercel CLI 65.4.0:

| Build | `scripts/check.sh` |
| --- | --- |
| Default (adapter `@vercel/next` 27.0.0) | FAIL, consume 500 `MODULE_NOT_FOUND` |
| `adapterPath` set to the published `@next-community/adapter-vercel@0.0.1-beta.35` | FAIL, same error |
| `adapterPath` set to the nextjs/adapter-vercel#151 build | PASS |
| Project env `NEXT_ENABLE_ADAPTER=0` (no adapter) | PASS |
| Without `basePath` | PASS |

## Why

Routing sets `x-matched-path` without the basePath, and the adapter's node handler resolves the page from that header. A queue trigger invokes the function directly and skips routing, so the request has no `x-matched-path`. The handler falls back to the request URL, which still starts with `/docs`. `/docs/api/consume` matches no route, so the handler requires a `server/pages/...` module that doesn't exist.

Without the adapter, Next.js removes the basePath from the URL itself, which is why `NEXT_ENABLE_ADAPTER=0` works.

## Testing an adapter build

Point Next.js at a local or preview adapter build. The adapter also needs `@vercel/build-utils`, which `@vercel/next` normally provides:

```sh
pnpm add @next-community/adapter-vercel@<version-or-tarball> @vercel/build-utils@15.1.0
```

```ts
// next.config.ts
const nextConfig: NextConfig = {
  basePath: '/docs',
  adapterPath: require.resolve('@next-community/adapter-vercel'),
};
```

## Next.js e2e test

[`nextjs-e2e/base-path-queue-trigger`](nextjs-e2e/base-path-queue-trigger) is the same app as a deploy-mode test for `vercel/next.js` (`test/e2e/app-dir/base-path-queue-trigger`). It only runs with `NEXT_TEST_MODE=deploy`, because queue triggers only exist on a deployment.
