import { handleCallback } from '@vercel/queue';
import { RECEIPTS_TOPIC, receipts } from '@/lib/queue';

// Invoked by the queue trigger in vercel.json, not by routing. With a
// basePath and the Vercel adapter, this handler never runs: the function
// fails with MODULE_NOT_FOUND for .next/server/pages/docs/api/consume.js.
export const POST = handleCallback<{ id: string }>(async (message) => {
  console.log('consumed', message.id);
  await receipts.send(RECEIPTS_TOPIC, { id: message.id });
});
