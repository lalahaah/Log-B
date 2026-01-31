import type { NextConfig } from "next";
const withPWA = require('next-pwa')({
  dest: 'public',
  disable: process.env.NODE_ENV === 'development',
  register: true,
  skipWaiting: true,
});

const nextConfig: NextConfig = {
  /* config options here */
  // Turbopack과 Webpack 플러그인(next-pwa) 간의 충돌을 방지하기 위해 빈 설정을 추가합니다.
  experimental: {
    turbopack: {},
  } as any,
};

export default withPWA(nextConfig);
