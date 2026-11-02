import { RECEIPTS_TOPIC, receipts } from '../../../lib/queue';

export const dynamic = 'force-dynamic';

// GET /docs/api/result -> lists the job ids the consumer has processed
// since the last call.
export async function GET() {
  const consumed: string[] = [];
  const result = await receipts.receive<{ id: string }>(
    RECEIPTS_TOPIC,
    'reader',
    async (message) => {
      consumed.push(message.id);
    },
    { limit: 10 }
  );
  return Response.json({ consumed, ok: result.ok });
}
