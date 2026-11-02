import { PollingQueueClient } from '@vercel/queue';

// Receipts are written and read with a fixed region, as polling receive
// requires (see the @vercel/queue README, "Region considerations").
export const receipts = new PollingQueueClient({ region: 'iad1' });
export const JOBS_TOPIC = 'repro-jobs';
export const RECEIPTS_TOPIC = 'repro-receipts';
