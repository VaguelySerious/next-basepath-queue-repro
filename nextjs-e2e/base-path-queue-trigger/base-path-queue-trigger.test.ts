import { isNextDeploy, nextTestSetup } from 'e2e-utils'
import { retry } from 'next-test-utils'

// Queue triggers only exist on a deployment: the platform invokes
// app/api/consume/route.ts directly (see vercel.json), skipping routing, so
// the request carries no x-matched-path and its URL keeps the basePath.
describe('basePath queue-triggered route handler', () => {
  const { next } = nextTestSetup({
    files: __dirname,
    dependencies: { '@vercel/queue': '0.10.0' },
  })

  ;(isNextDeploy ? it : it.skip)(
    'invokes the route handler for a message sent to its topic',
    async () => {
      const sendRes = await next.fetch('/docs/api/send', { method: 'POST' })
      expect(sendRes.status).toBe(200)
      const { id } = (await sendRes.json()) as { id: string }

      const consumed: string[] = []
      await retry(
        async () => {
          const res = await next.fetch('/docs/api/result')
          const body = (await res.json()) as { consumed: string[] }
          consumed.push(...body.consumed)
          expect(consumed).toContain(id)
        },
        60_000,
        2_000
      )
    }
  )
})
