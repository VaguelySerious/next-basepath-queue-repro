import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // The bug only reproduces with a basePath. Remove this line and the
  // consumer below receives the message on every build mode.
  basePath: '/docs',
};

export default nextConfig;
