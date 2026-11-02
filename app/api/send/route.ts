import { send } from '@vercel/queue';
import { JOBS_TOPIC } from '@/lib/queue';

// POST /docs/api/send -> enqueues one job for the queue-triggered consumer.
export async function POST() {
  const id = crypto.randomUUID();
  await send(JOBS_TOPIC, { id });
  return Response.json({ id });
}
